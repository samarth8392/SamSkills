#!/usr/bin/env python3
"""
make_synthetic_vcf.py

Emit small VCFs with KNOWN ground-truth ancestry so the hybrid-index pipeline can be
tested against closed-form expectations. Used by the hybrid-genomics-project-audit skill
(Tier-1 unit tests).

Design contract (must match calculate_hybrid_index_ml.py):
  - h = 0  => pure parent1 (S. catenatus) ancestry in the input sample
  - h = 1  => pure parent2 (S. tergeminus) ancestry
  - Diagnostic loci: one allele ~fixed in parent1, the other ~fixed in parent2.
  - parse_gt_to_n_alt skips '.', './.', partial ('0/.'), haploid ('1'), non-0/1 alleles.

Each builder returns (vcf_text, expectation_dict) where expectation_dict carries the
ground-truth values the test will assert against (expected h per input sample, n
diagnostic loci, etc.). The generator NEVER computes h via the pipeline — it only lays
down genotypes whose correct h is known by construction, so a passing test proves the
pipeline, not the generator.

CLI:
  python make_synthetic_vcf.py <scenario> --out file.vcf [--seed 1]
scenarios: pure_p1 | pure_p2 | het50 | polarity_swapped | partial_gts |
           below_min_aims | multiallelic_skip | desert_windows

For desert testing we also emit a windows TSV directly (build_windows_tsv), bypassing
the VCF, because find_introgression_deserts.py consumes a windows TSV, not a VCF.
"""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Tuple


# ----------------------------------------------------------------------------- #
# VCF assembly helpers
# ----------------------------------------------------------------------------- #

VCF_HEADER_LINES = [
    "##fileformat=VCFv4.2",
    '##FILTER=<ID=PASS,Description="All filters passed">',
    '##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">',
    '##contig=<ID=chrTEST>',
]


def _col_header(samples: List[str]) -> str:
    fixed = ["#CHROM", "POS", "ID", "REF", "ALT", "QUAL", "FILTER", "INFO", "FORMAT"]
    return "\t".join(fixed + samples)


def _record(chrom: str, pos: int, ref: str, alt: str, gts: List[str]) -> str:
    fixed = [chrom, str(pos), ".", ref, alt, ".", "PASS", ".", "GT"]
    return "\t".join(fixed + gts)


def _assemble(samples: List[str], records: List[str]) -> str:
    return "\n".join(VCF_HEADER_LINES + [_col_header(samples)] + records) + "\n"


@dataclass
class Scenario:
    name: str
    vcf_text: str
    sample_lists: Dict[str, List[str]]          # 'input','parent1','parent2' -> sample IDs
    expectation: Dict                            # ground-truth for assertions


# ----------------------------------------------------------------------------- #
# Genotype string builders for diagnostic loci
# ----------------------------------------------------------------------------- #
# A diagnostic locus has REF ~fixed in one parent, ALT ~fixed in the other.
# "p2_is_alt" means ALT allele marks parent2. We control polarity per scenario.

GT_HOM_REF = "0/0"   # 0 ALT copies
GT_HET = "0/1"       # 1 ALT copy
GT_HOM_ALT = "1/1"   # 2 ALT copies


def _diagnostic_block(
    n_loci: int,
    p1_gt: str,
    p2_gt: str,
    input_gt: str,
    n_input: int,
    n_p1: int,
    n_p2: int,
    start_pos: int = 1000,
    pos_step: int = 100,
    alt_is_p2: bool = True,
) -> Tuple[List[str], List[str]]:
    """
    Build n_loci diagnostic records. Column order: input samples, then parent1, then
    parent2 (the sample-list files define group membership; VCF column order is just
    the union). Returns (records, all_sample_ids).

    alt_is_p2=True  -> ALT allele fixed in parent2 (p2 hom-alt, p1 hom-ref) [diag_alt]
    alt_is_p2=False -> ALT allele fixed in parent1 (p1 hom-alt, p2 hom-ref) [diag_ref]
    Caller supplies p1_gt/p2_gt/input_gt consistent with the polarity they want.
    """
    in_ids = [f"IN{i}" for i in range(n_input)]
    p1_ids = [f"P1_{i}" for i in range(n_p1)]
    p2_ids = [f"P2_{i}" for i in range(n_p2)]
    all_ids = in_ids + p1_ids + p2_ids

    records = []
    for j in range(n_loci):
        pos = start_pos + j * pos_step
        gts = (
            [input_gt] * n_input
            + [p1_gt] * n_p1
            + [p2_gt] * n_p2
        )
        records.append(_record("chrTEST", pos, "A", "G", gts))
    return records, all_ids


def _sample_lists(all_ids: List[str], n_input: int, n_p1: int) -> Dict[str, List[str]]:
    return {
        "input": all_ids[:n_input],
        "parent1": all_ids[n_input:n_input + n_p1],
        "parent2": all_ids[n_input + n_p1:],
    }


# ----------------------------------------------------------------------------- #
# Scenarios
# ----------------------------------------------------------------------------- #

def scen_pure_p1(n_loci: int = 20) -> Scenario:
    """Input identical to parent1. Expected h = 0.0, ancestry=parent1."""
    # ALT fixed in parent2 (diag_alt). parent1 hom-ref, parent2 hom-alt.
    # input == parent1 => 0 ALT => 0 parent2 alleles => h=0.
    recs, ids = _diagnostic_block(
        n_loci, p1_gt=GT_HOM_REF, p2_gt=GT_HOM_ALT, input_gt=GT_HOM_REF,
        n_input=2, n_p1=4, n_p2=4, alt_is_p2=True,
    )
    return Scenario(
        "pure_p1", _assemble(ids, recs), _sample_lists(ids, 2, 4),
        {"expected_h": {s: 0.0 for s in ids[:2]},
         "expected_ancestry": "parent1", "n_diagnostic": n_loci},
    )


def scen_pure_p2(n_loci: int = 20) -> Scenario:
    """Input identical to parent2. Expected h = 1.0, ancestry=parent2."""
    recs, ids = _diagnostic_block(
        n_loci, p1_gt=GT_HOM_REF, p2_gt=GT_HOM_ALT, input_gt=GT_HOM_ALT,
        n_input=2, n_p1=4, n_p2=4, alt_is_p2=True,
    )
    return Scenario(
        "pure_p2", _assemble(ids, recs), _sample_lists(ids, 2, 4),
        {"expected_h": {s: 1.0 for s in ids[:2]},
         "expected_ancestry": "parent2", "n_diagnostic": n_loci},
    )


def scen_het50(n_loci: int = 20) -> Scenario:
    """Input fully heterozygous at diagnostic loci. Expected h = 0.5, admixed."""
    recs, ids = _diagnostic_block(
        n_loci, p1_gt=GT_HOM_REF, p2_gt=GT_HOM_ALT, input_gt=GT_HET,
        n_input=2, n_p1=4, n_p2=4, alt_is_p2=True,
    )
    return Scenario(
        "het50", _assemble(ids, recs), _sample_lists(ids, 2, 4),
        {"expected_h": {s: 0.5 for s in ids[:2]},
         "expected_ancestry": "admixed", "n_diagnostic": n_loci},
    )


def scen_polarity_swapped(n_loci: int = 20) -> Scenario:
    """
    ALT fixed in parent1 (diag_ref branch). Input == parent2 (hom-ref here).
    h must STILL be 1.0 because n_p2 = 2 - n_alt when p2_is_alt is False.
    This is the polarity regression test.
    """
    # parent1 hom-alt, parent2 hom-ref; input == parent2 == hom-ref.
    recs, ids = _diagnostic_block(
        n_loci, p1_gt=GT_HOM_ALT, p2_gt=GT_HOM_REF, input_gt=GT_HOM_REF,
        n_input=2, n_p1=4, n_p2=4, alt_is_p2=False,
    )
    return Scenario(
        "polarity_swapped", _assemble(ids, recs), _sample_lists(ids, 2, 4),
        {"expected_h": {s: 1.0 for s in ids[:2]},
         "expected_ancestry": "parent2", "n_diagnostic": n_loci},
    )


def scen_partial_gts(n_loci: int = 20) -> Scenario:
    """
    Input genotypes are all partial/haploid/missing => every diagnostic locus is
    skipped for the input sample => no window emitted (reps_used==0). Parents are clean.
    """
    in_ids = ["IN0"]
    p1_ids = [f"P1_{i}" for i in range(4)]
    p2_ids = [f"P2_{i}" for i in range(4)]
    ids = in_ids + p1_ids + p2_ids
    bad_input = ["0/.", "./1", "1", ".", "./."]  # cycle through invalid forms
    recs = []
    for j in range(n_loci):
        pos = 1000 + j * 100
        gt_in = bad_input[j % len(bad_input)]
        gts = [gt_in] + [GT_HOM_REF] * 4 + [GT_HOM_ALT] * 4
        recs.append(_record("chrTEST", pos, "A", "G", gts))
    return Scenario(
        "partial_gts", _assemble(ids, recs), _sample_lists(ids, 1, 4),
        {"expected_windows": 0, "reason": "all input GTs invalid -> skipped"},
    )


def scen_below_min_aims(n_loci: int = 5) -> Scenario:
    """
    Only 5 diagnostic loci in the window. With --min-aims 10 the window must be
    dropped (sum_c < min_aims). Expected: no window passes.
    """
    recs, ids = _diagnostic_block(
        n_loci, p1_gt=GT_HOM_REF, p2_gt=GT_HOM_ALT, input_gt=GT_HOM_ALT,
        n_input=1, n_p1=4, n_p2=4, alt_is_p2=True,
    )
    return Scenario(
        "below_min_aims", _assemble(ids, recs), _sample_lists(ids, 1, 4),
        {"min_aims": 10, "n_diagnostic": n_loci, "expected_windows": 0},
    )


def scen_multiallelic_skip(n_loci: int = 10) -> Scenario:
    """
    Half the records are multiallelic (ALT='G,T') or non-SNP (REF='AT'); these MUST be
    skipped by the VCF iterator, leaving only the clean half as diagnostic loci.
    """
    in_ids = ["IN0"]
    p1_ids = [f"P1_{i}" for i in range(4)]
    p2_ids = [f"P2_{i}" for i in range(4)]
    ids = in_ids + p1_ids + p2_ids
    recs = []
    clean = 0
    for j in range(n_loci):
        pos = 1000 + j * 100
        gts = [GT_HOM_ALT] + [GT_HOM_REF] * 4 + [GT_HOM_ALT] * 4
        if j % 2 == 0:
            recs.append(_record("chrTEST", pos, "A", "G", gts))   # clean SNP
            clean += 1
        else:
            # multiallelic on odd loci; pipeline must skip
            recs.append(_record("chrTEST", pos, "A", "G,T", gts))
    return Scenario(
        "multiallelic_skip", _assemble(ids, recs), _sample_lists(ids, 1, 4),
        {"n_clean_diagnostic": clean, "note": "odd loci multiallelic -> skipped"},
    )


SCENARIOS = {
    "pure_p1": scen_pure_p1,
    "pure_p2": scen_pure_p2,
    "het50": scen_het50,
    "polarity_swapped": scen_polarity_swapped,
    "partial_gts": scen_partial_gts,
    "below_min_aims": scen_below_min_aims,
    "multiallelic_skip": scen_multiallelic_skip,
}


# ----------------------------------------------------------------------------- #
# Windows TSV builder (for find_introgression_deserts.py, not VCF-based)
# ----------------------------------------------------------------------------- #

WINDOWS_HEADER = [
    "sample", "chrom", "window_start", "window_end",
    "mean_n_loci", "mean_hybrid_index", "ci_low", "ci_high",
    "ancestry", "n_reps_used",
]


def build_windows_tsv(
    n_samples: int = 8,
    window: int = 50000,
    step: int = 10000,
    merge_distance: int = 5000,
) -> Tuple[str, Dict]:
    """
    Build a deterministic windows TSV that exercises the desert merge boundary.

    Layout (all samples parent1-like, ci_high <= 0.1 so they classify parent1):
      Block A: windows at starts 0,10k,20k,30k,40k  (contiguous, step=10k)
      Gap exactly == merge_distance boundary between block A end and block B start
      Block B: a second run of windows
    With window=50000, step=10000, consecutive window_starts differ by 10k but the
    windows OVERLAP (end = start+50k), so gaps are negative -> always merge within a
    block. We then place block B so the gap between A's last end and B's first start
    is exactly merge_distance (should MERGE: s <= cur_end + merge_distance) and a
    block C where the gap is merge_distance+1 (should SPLIT).

    Returns (tsv_text, expectation) where expectation gives expected region count and
    total length for target=parent1, min_samples<=n_samples, min_support=1.0.
    """
    rows: List[str] = []
    samples = [f"S{i}" for i in range(n_samples)]

    def emit(start: int, end: int):
        for s in samples:
            rows.append("\t".join([
                s, "chrTEST", str(start), str(end),
                "25", "0.02", "0.0", "0.05",   # ci_high=0.05 <= 0.1 => parent1
                "parent1", "100",
            ]))

    # Block A: starts 0..40k step 10k, each window 50k wide
    a_starts = [0, 10000, 20000, 30000, 40000]
    for st in a_starts:
        emit(st, st + window)
    a_last_end = a_starts[-1] + window  # 90000

    # Block B: gap from a_last_end exactly == merge_distance -> should merge with A
    b_start = a_last_end + merge_distance          # 95000, gap == merge_distance
    b_starts = [b_start, b_start + 10000]
    for st in b_starts:
        emit(st, st + window)
    b_last_end = b_starts[-1] + window

    # Block C: gap from b_last_end == merge_distance + 1 -> should SPLIT into new region
    c_start = b_last_end + merge_distance + 1
    c_starts = [c_start, c_start + 10000, c_start + 20000]
    for st in c_starts:
        emit(st, st + window)
    c_last_end = c_starts[-1] + window

    tsv = "\t".join(WINDOWS_HEADER) + "\n" + "\n".join(rows) + "\n"

    # Expected: A and B merge into ONE region; C is a SECOND region. => 2 regions.
    region1_len = b_last_end - 0
    region2_len = c_last_end - c_start
    expectation = {
        "merge_distance": merge_distance,
        "target": "parent1",
        "min_support": 1.0,
        "min_samples": n_samples,
        "expected_regions": 2,
        "expected_region1_length": region1_len,
        "expected_region2_length": region2_len,
        "note": "A+B merge (gap==merge_distance); C splits (gap==merge_distance+1)",
    }
    return tsv, expectation


# ----------------------------------------------------------------------------- #
# CLI
# ----------------------------------------------------------------------------- #

def main() -> int:
    p = argparse.ArgumentParser(description="Generate synthetic VCFs / windows TSV with known ground truth.")
    p.add_argument("scenario", choices=list(SCENARIOS.keys()) + ["desert_windows"])
    p.add_argument("--out", required=True, help="Output VCF (or TSV for desert_windows).")
    p.add_argument("--sample-list-prefix", default=None,
                   help="If set, also write <prefix>.input.txt/.parent1.txt/.parent2.txt")
    p.add_argument("--expect-out", default=None, help="Write expectation JSON here.")
    p.add_argument("--merge-distance", type=int, default=5000, help="(desert_windows only)")
    p.add_argument("--seed", type=int, default=1)  # accepted for interface symmetry
    args = p.parse_args()

    if args.scenario == "desert_windows":
        tsv, expect = build_windows_tsv(merge_distance=args.merge_distance)
        with open(args.out, "w") as f:
            f.write(tsv)
        if args.expect_out:
            with open(args.expect_out, "w") as f:
                json.dump(expect, f, indent=2)
        print(f"[OK] wrote windows TSV: {args.out}", file=sys.stderr)
        return 0

    sc = SCENARIOS[args.scenario]()
    with open(args.out, "w") as f:
        f.write(sc.vcf_text)

    if args.sample_list_prefix:
        for grp in ("input", "parent1", "parent2"):
            with open(f"{args.sample_list_prefix}.{grp}.txt", "w") as f:
                f.write("\n".join(sc.sample_lists[grp]) + "\n")

    if args.expect_out:
        with open(args.expect_out, "w") as f:
            json.dump({"scenario": sc.name, **sc.expectation}, f, indent=2)

    print(f"[OK] wrote scenario '{sc.name}' VCF: {args.out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
