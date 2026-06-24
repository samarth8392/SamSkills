#!/usr/bin/env python3
"""
test_tier1_core.py

Tier-1 unit tests for the hybrid-genomics pipeline. No vcftools required: these import
the Python core directly and run synthetic VCFs / windows TSVs with KNOWN ground truth.

What each test proves:
  - h orientation: pure-parent1 => 0.0, pure-parent2 => 1.0, het => 0.5
  - polarity: swapping which parent is ALT-fixed does NOT flip h (diag_ref branch)
  - support_interval_binomial: analytic edge cases k=0, k=n; brackets k/n; monotone
  - partial/haploid/missing genotypes are excluded
  - min-aims gating drops under-supported windows
  - multiallelic / non-SNP records are skipped
  - desert merge boundary: gap == merge_distance merges; gap == merge_distance+1 splits
  - re-derivation hook: region count / total bp from find_introgression_deserts.py

Layout assumption (override with env vars):
  HYBRID_CODE_DIR  -> dir containing calculate_hybrid_index_ml.py, find_introgression_deserts.py
  GEN              -> path to make_synthetic_vcf.py
Run:  pytest -q test_tier1_core.py
"""

from __future__ import annotations

import importlib.util
import json
import math
import os
import subprocess
import sys
import tempfile
from pathlib import Path

import pytest

# --------------------------------------------------------------------------- #
# Locate and import the pipeline modules dynamically (paths are project-specific)
# --------------------------------------------------------------------------- #

CODE_DIR = Path(os.environ.get("HYBRID_CODE_DIR", "codebase/scripts/hybrid_index"))
GEN_PATH = Path(os.environ.get("GEN", "tests/make_synthetic_vcf.py"))


def _load(modname: str, path: Path):
    spec = importlib.util.spec_from_file_location(modname, str(path))
    if spec is None or spec.loader is None:
        pytest.skip(f"cannot load {path}")
    mod = importlib.util.module_from_spec(spec)
    sys.modules[modname] = mod
    spec.loader.exec_module(mod)
    return mod


@pytest.fixture(scope="session")
def calc():
    p = CODE_DIR / "calculate_hybrid_index_ml.py"
    if not p.exists():
        pytest.skip(f"missing {p}")
    return _load("calc_hi", p)


@pytest.fixture(scope="session")
def gen():
    if not GEN_PATH.exists():
        pytest.skip(f"missing generator {GEN_PATH}")
    return _load("gen_vcf", GEN_PATH)


# --------------------------------------------------------------------------- #
# Helper: run the hybrid-index core on an in-memory scenario, return rows
# --------------------------------------------------------------------------- #

def _run_hi_on_scenario(calc, sc, window=50000, step=10000, min_aims=10,
                        diagnostic_threshold=0.05, n_reps=1, seed=1):
    """
    Drive calculate_hybrid_index_ml end-to-end on a Scenario object by writing its VCF
    and sample lists to a tempdir and invoking the module's main() via argv. Returns the
    parsed output rows (list of dicts).
    """
    with tempfile.TemporaryDirectory() as d:
        d = Path(d)
        vcf = d / "in.vcf"
        vcf.write_text(sc.vcf_text)
        for grp in ("input", "parent1", "parent2"):
            (d / f"{grp}.txt").write_text("\n".join(sc.sample_lists[grp]) + "\n")
        out = d / "windows.tsv"

        argv = [
            "calculate_hybrid_index_ml.py",
            "--vcf", str(vcf),
            "--input-samples", str(d / "input.txt"),
            "--parent1-samples", str(d / "parent1.txt"),
            "--parent2-samples", str(d / "parent2.txt"),
            "--window", str(window), "--step", str(step),
            "--min-aims", str(min_aims),
            "--diagnostic-threshold", str(diagnostic_threshold),
            "--n-reps", str(n_reps), "--seed", str(seed),
            "--output", str(out),
        ]
        old = sys.argv
        sys.argv = argv
        try:
            rc = calc.main()
        finally:
            sys.argv = old
        assert rc == 0, "calculate_hybrid_index_ml.main() returned nonzero"

        rows = []
        if out.exists():
            lines = out.read_text().strip().splitlines()
            if len(lines) > 1:
                header = lines[0].split("\t")
                for ln in lines[1:]:
                    rows.append(dict(zip(header, ln.split("\t"))))
        return rows


# --------------------------------------------------------------------------- #
# h-orientation tests
# --------------------------------------------------------------------------- #

def test_pure_parent1_gives_h0(calc, gen):
    sc = gen.scen_pure_p1()
    rows = _run_hi_on_scenario(calc, sc)
    assert rows, "expected at least one window for pure_p1"
    for r in rows:
        assert math.isclose(float(r["mean_hybrid_index"]), 0.0, abs_tol=1e-9), r
        assert r["ancestry"] == "parent1", r


def test_pure_parent2_gives_h1(calc, gen):
    sc = gen.scen_pure_p2()
    rows = _run_hi_on_scenario(calc, sc)
    assert rows, "expected at least one window for pure_p2"
    for r in rows:
        assert math.isclose(float(r["mean_hybrid_index"]), 1.0, abs_tol=1e-9), r
        assert r["ancestry"] == "parent2", r


def test_het_block_gives_h_half(calc, gen):
    sc = gen.scen_het50()
    rows = _run_hi_on_scenario(calc, sc)
    assert rows
    for r in rows:
        assert math.isclose(float(r["mean_hybrid_index"]), 0.5, abs_tol=1e-9), r
        assert r["ancestry"] == "admixed", r


def test_polarity_swap_does_not_flip_h(calc, gen):
    """diag_ref branch: ALT fixed in parent1, input == parent2 => h must be 1.0."""
    sc = gen.scen_polarity_swapped()
    rows = _run_hi_on_scenario(calc, sc)
    assert rows, "polarity-swapped scenario produced no windows"
    for r in rows:
        assert math.isclose(float(r["mean_hybrid_index"]), 1.0, abs_tol=1e-9), (
            "h flipped under polarity swap -- p2_is_alt/diag_ref handling is wrong", r)


# --------------------------------------------------------------------------- #
# Genotype-parsing / filtering tests
# --------------------------------------------------------------------------- #

@pytest.mark.parametrize("gt", ["0/.", "./1", "1", ".", "./.", ".|.", "0/2", "2/2"])
def test_invalid_genotypes_return_none(calc, gt):
    assert calc.parse_gt_to_n_alt(gt) is None, f"{gt} should parse to None"


@pytest.mark.parametrize("gt,expected", [("0/0", 0), ("0/1", 1), ("1/0", 1),
                                         ("1/1", 2), ("0|1", 1), ("1|1", 2)])
def test_valid_genotypes_parse(calc, gt, expected):
    assert calc.parse_gt_to_n_alt(gt) == expected


def test_partial_genotypes_yield_no_windows(calc, gen):
    sc = gen.scen_partial_gts()
    rows = _run_hi_on_scenario(calc, sc)
    assert rows == [], "windows emitted despite all input GTs being invalid"


def test_below_min_aims_drops_window(calc, gen):
    sc = gen.scen_below_min_aims()       # 5 diagnostic loci
    rows = _run_hi_on_scenario(calc, sc, min_aims=10)
    assert rows == [], "window with <min_aims diagnostic loci was not dropped"


def test_multiallelic_records_skipped(calc, gen):
    """Odd loci are multiallelic; only the clean half should count toward the window."""
    sc = gen.scen_multiallelic_skip()
    rows = _run_hi_on_scenario(calc, sc, min_aims=1)
    assert rows, "expected a window from the clean SNPs"
    n_clean = sc.expectation["n_clean_diagnostic"]
    # mean_n_loci is reported per window; should equal the clean count, not n_loci.
    for r in rows:
        assert abs(float(r["mean_n_loci"]) - n_clean) < 1e-6, (
            "multiallelic/non-SNP records leaked into the diagnostic set", r)


# --------------------------------------------------------------------------- #
# support_interval_binomial: analytic edge cases
# --------------------------------------------------------------------------- #

def test_support_interval_k0(calc):
    n = 40
    lo, hi = calc.support_interval_binomial(0, n, delta_ll=2.0)
    assert lo == 0.0
    assert math.isclose(hi, 1.0 - math.exp(-2.0 / n), rel_tol=1e-9), (lo, hi)


def test_support_interval_kn(calc):
    n = 40
    lo, hi = calc.support_interval_binomial(n, n, delta_ll=2.0)
    assert hi == 1.0
    assert math.isclose(lo, math.exp(-2.0 / n), rel_tol=1e-9), (lo, hi)


def test_support_interval_brackets_mle(calc):
    n, k = 50, 20
    lo, hi = calc.support_interval_binomial(k, n)
    assert 0.0 <= lo <= k / n <= hi <= 1.0, (lo, k / n, hi)


def test_support_interval_narrows_with_n(calc):
    """More data => tighter interval at the same MLE (k/n held at 0.5)."""
    lo_small, hi_small = calc.support_interval_binomial(10, 20)
    lo_big, hi_big = calc.support_interval_binomial(100, 200)
    assert (hi_big - lo_big) < (hi_small - lo_small)


# --------------------------------------------------------------------------- #
# Desert merge-boundary + re-derivation (subprocess; pure-python script)
# --------------------------------------------------------------------------- #

def _run_deserts(tsv_path: Path, out_path: Path, *, target, merge_distance,
                 min_samples, min_support, min_length, min_windows=1):
    script = CODE_DIR / "find_introgression_deserts.py"
    if not script.exists():
        pytest.skip(f"missing {script}")
    cmd = [
        sys.executable, str(script),
        "--input", str(tsv_path), "--output", str(out_path),
        "--target", target, "--merge-distance", str(merge_distance),
        "--min-samples", str(min_samples), "--min-support", str(min_support),
        "--min-length", str(min_length), "--min-windows", str(min_windows),
    ]
    res = subprocess.run(cmd, capture_output=True, text=True)
    assert res.returncode == 0, res.stderr
    return out_path


def _read_regions(path: Path):
    lines = path.read_text().strip().splitlines()
    if len(lines) <= 1:
        return []
    header = lines[0].split("\t")
    return [dict(zip(header, ln.split("\t"))) for ln in lines[1:]]


def test_desert_merge_boundary(gen):
    """gap == merge_distance merges (A+B); gap == merge_distance+1 splits (C)."""
    tsv, expect = gen.build_windows_tsv(merge_distance=5000)
    with tempfile.TemporaryDirectory() as d:
        d = Path(d)
        tsv_p = d / "windows.tsv"
        tsv_p.write_text(tsv)
        out = _run_deserts(
            tsv_p, d / "deserts.tsv",
            target=expect["target"], merge_distance=expect["merge_distance"],
            min_samples=expect["min_samples"], min_support=expect["min_support"],
            min_length=1, min_windows=1,
        )
        regions = _read_regions(out)
        assert len(regions) == expect["expected_regions"], (
            f"expected {expect['expected_regions']} regions, got {len(regions)}: {regions}")
        lengths = sorted(int(r["length"]) for r in regions)
        exp_lengths = sorted([expect["expected_region1_length"],
                              expect["expected_region2_length"]])
        assert lengths == exp_lengths, (lengths, exp_lengths)


def test_desert_min_length_filter(gen):
    """A min_length larger than both regions should yield zero regions."""
    tsv, expect = gen.build_windows_tsv(merge_distance=5000)
    with tempfile.TemporaryDirectory() as d:
        d = Path(d)
        tsv_p = d / "windows.tsv"
        tsv_p.write_text(tsv)
        out = _run_deserts(
            tsv_p, d / "deserts.tsv",
            target=expect["target"], merge_distance=expect["merge_distance"],
            min_samples=expect["min_samples"], min_support=expect["min_support"],
            min_length=10_000_000, min_windows=1,
        )
        assert _read_regions(out) == []


def test_desert_min_support_filter(gen):
    """min_support above the per-window support fraction yields zero regions."""
    tsv, expect = gen.build_windows_tsv(merge_distance=5000)
    with tempfile.TemporaryDirectory() as d:
        d = Path(d)
        tsv_p = d / "windows.tsv"
        tsv_p.write_text(tsv)
        out = _run_deserts(
            tsv_p, d / "deserts.tsv",
            target="parent1", merge_distance=5000,
            min_samples=expect["min_samples"], min_support=1.0001,  # impossible
            min_length=1, min_windows=1,
        )
        assert _read_regions(out) == []


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
