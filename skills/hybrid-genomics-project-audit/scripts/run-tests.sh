#!/usr/bin/env bash
# run_tests.sh
#
# Test harness for the hybrid-genomics-project-audit skill (STEP 3).
#
#   Tier 1 — pure-Python unit tests on the pipeline core. ALWAYS runnable
#            (no vcftools). Drives test_tier1_core.py via pytest.
#   Tier 2 — end-to-end pipeline smoke test through hybrid_index_sliding_window.sh.
#            Requires vcftools (+ bgzip/tabix/awk). If absent, the stage is recorded
#            as LOGIC_TRACED_ONLY and does NOT fail the run.
#
# Emits:
#   <OUTDIR>/test_report.json   machine-readable summary (consumed by STEP 4 synthesis)
#   <OUTDIR>/test_log.txt       full stdout/stderr
#   <OUTDIR>/e2e_log.txt        Tier-2 pipeline stdout/stderr (if run)
#
# Usage:
#   run_tests.sh [--code-dir DIR] [--tests-dir DIR] [--outdir DIR] [--real-vcf FILE]
#                [--input LIST --parent1 LIST --parent2 LIST]
#
# Determinism: all stochastic steps use --seed 1. Tier-2 uses --n-reps 1.
#
# Exit status: nonzero ONLY if a runnable test FAILED. Skipped/traced stages do not
# cause a nonzero exit (missing tools are a degraded-capability note, not a failure).

set -uo pipefail   # NOTE: not -e; we manage failures explicitly to keep reporting intact

# --------------------------------------------------------------------------- #
# Defaults / arg parsing
# --------------------------------------------------------------------------- #
CODE_DIR="codebase/scripts/hybrid_index"
TESTS_DIR="tests"
OUTDIR="audit_tmp"
REAL_VCF=""
INPUT_LIST=""
PARENT1_LIST=""
PARENT2_LIST=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --code-dir)  CODE_DIR="$2"; shift 2 ;;
    --tests-dir) TESTS_DIR="$2"; shift 2 ;;
    --outdir)    OUTDIR="$2"; shift 2 ;;
    --real-vcf)  REAL_VCF="$2"; shift 2 ;;
    --input)     INPUT_LIST="$2"; shift 2 ;;
    --parent1)   PARENT1_LIST="$2"; shift 2 ;;
    --parent2)   PARENT2_LIST="$2"; shift 2 ;;
    -h|--help)
      grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "ERROR: unknown arg: $1" >&2; exit 2 ;;
  esac
done

mkdir -p "$OUTDIR"
LOG="$OUTDIR/test_log.txt"
E2E_LOG="$OUTDIR/e2e_log.txt"
REPORT="$OUTDIR/test_report.json"
GEN="$TESTS_DIR/make_synthetic_vcf.py"
TIER1="$TESTS_DIR/test_tier1_core.py"

: > "$LOG"

log() { echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG"; }

# --------------------------------------------------------------------------- #
# Environment probe
# --------------------------------------------------------------------------- #
have() { command -v "$1" >/dev/null 2>&1; }

PYTHON="python3"; have python3 || PYTHON="python"
have "$PYTHON" || { echo "ERROR: no python found" >&2; exit 2; }

tool_ver() { command -v "$1" >/dev/null 2>&1 && { "$1" --version 2>&1 | head -1; } || echo "ABSENT"; }

PYTEST_OK=0
if "$PYTHON" -c "import pytest" 2>/dev/null; then PYTEST_OK=1; fi

VCFTOOLS_OK=0; have vcftools && VCFTOOLS_OK=1
BGZIP_OK=0;    have bgzip && BGZIP_OK=1
AWK_OK=0;      have awk && AWK_OK=1

log "Environment:"
log "  python:   $($PYTHON --version 2>&1)"
log "  pytest:   $([[ $PYTEST_OK -eq 1 ]] && echo present || echo ABSENT)"
log "  vcftools: $(tool_ver vcftools)"
log "  bgzip:    $(tool_ver bgzip)"
log "  awk:      $(tool_ver awk)"

# Sanity: required files
MISSING=()
[[ -f "$GEN" ]]   || MISSING+=("$GEN")
[[ -f "$TIER1" ]] || MISSING+=("$TIER1")
[[ -f "$CODE_DIR/calculate_hybrid_index_ml.py" ]] || MISSING+=("$CODE_DIR/calculate_hybrid_index_ml.py")
[[ -f "$CODE_DIR/find_introgression_deserts.py" ]] || MISSING+=("$CODE_DIR/find_introgression_deserts.py")
if [[ ${#MISSING[@]} -gt 0 ]]; then
  log "ERROR: missing required files: ${MISSING[*]}"
  cat > "$REPORT" <<JSON
{
  "status": "error",
  "error": "missing required files",
  "missing": [$(printf '"%s",' "${MISSING[@]}" | sed 's/,$//')]
}
JSON
  exit 2
fi

# --------------------------------------------------------------------------- #
# TIER 1 — pytest on the pure-Python core
# --------------------------------------------------------------------------- #
TIER1_STATUS="not_run"
TIER1_PASSED=0
TIER1_FAILED=0
TIER1_SKIPPED=0

run_tier1() {
  log "=== TIER 1: unit tests (core, no vcftools) ==="
  export HYBRID_CODE_DIR="$CODE_DIR"
  export GEN="$GEN"

  if [[ $PYTEST_OK -eq 1 ]]; then
    # Machine-readable junit + human tee
    local junit="$OUTDIR/tier1_junit.xml"
    "$PYTHON" -m pytest "$TIER1" -q \
        --junitxml="$junit" 2>&1 | tee -a "$LOG"
    local rc=${PIPESTATUS[0]}
    if [[ -f "$junit" ]]; then
      # Parse counts from junit XML (no external deps)
      read -r TIER1_PASSED TIER1_FAILED TIER1_SKIPPED < <(
        "$PYTHON" - "$junit" <<'PY'
import sys, xml.etree.ElementTree as ET
t = ET.parse(sys.argv[1]).getroot()
# junit root may be <testsuites> or <testsuite>
suites = t.findall("testsuite") or [t]
tests=fail=err=skip=0
for s in suites:
    tests += int(s.get("tests", 0))
    fail  += int(s.get("failures", 0))
    err   += int(s.get("errors", 0))
    skip  += int(s.get("skipped", 0))
passed = tests - fail - err - skip
print(passed, fail + err, skip)
PY
      )
    fi
    TIER1_STATUS=$([[ $rc -eq 0 ]] && echo "passed" || echo "failed")
  else
    log "pytest absent -> running test_tier1_core.py directly (fallback)."
    HYBRID_CODE_DIR="$CODE_DIR" GEN="$GEN" "$PYTHON" "$TIER1" 2>&1 | tee -a "$LOG"
    local rc=${PIPESTATUS[0]}
    TIER1_STATUS=$([[ $rc -eq 0 ]] && echo "passed" || echo "failed")
    # counts unavailable without pytest
    TIER1_PASSED=$([[ $rc -eq 0 ]] && echo -1 || echo 0)
  fi
  log "TIER 1 status: $TIER1_STATUS (pass=$TIER1_PASSED fail=$TIER1_FAILED skip=$TIER1_SKIPPED)"
}

# --------------------------------------------------------------------------- #
# TIER 2 — end-to-end pipeline smoke test (needs vcftools)
# --------------------------------------------------------------------------- #
TIER2_STATUS="not_run"
TIER2_NOTE=""

emit_tier2_traced() {
  TIER2_STATUS="logic_traced_only"
  TIER2_NOTE="$1"
  log "TIER 2: LOGIC_TRACED_ONLY -- $1"
}

run_tier2() {
  log "=== TIER 2: end-to-end pipeline smoke test ==="

  if [[ $VCFTOOLS_OK -ne 1 || $AWK_OK -ne 1 ]]; then
    emit_tier2_traced "vcftools/awk absent; FST->AIM->subset stages cannot execute"
    return 0
  fi
  local pipeline="$CODE_DIR/hybrid_index_sliding_window.sh"
  if [[ ! -f "$pipeline" ]]; then
    emit_tier2_traced "hybrid_index_sliding_window.sh not found"
    return 0
  fi

  local work; work="$(mktemp -d)"
  local vcf in_list p1_list p2_list

  if [[ -n "$REAL_VCF" && -f "$REAL_VCF" && -n "$INPUT_LIST" && -n "$PARENT1_LIST" && -n "$PARENT2_LIST" ]]; then
    log "TIER 2: using real VCF: $REAL_VCF"
    vcf="$REAL_VCF"; in_list="$INPUT_LIST"; p1_list="$PARENT1_LIST"; p2_list="$PARENT2_LIST"
  else
    log "TIER 2: no real VCF supplied -> synthesizing a small multi-sample VCF"
    # pure_p2 has 2 input + 4 parent1 + 4 parent2 with 20 diagnostic loci.
    "$PYTHON" "$GEN" pure_p2 \
        --out "$work/e2e.vcf" \
        --sample-list-prefix "$work/samples" \
        --expect-out "$work/expect.json" 2>>"$LOG" || {
          emit_tier2_traced "synthetic VCF generation failed"; return 0; }
    vcf="$work/e2e.vcf"
    in_list="$work/samples.input.txt"
    p1_list="$work/samples.parent1.txt"
    p2_list="$work/samples.parent2.txt"
  fi

  # Run the pipeline with a low min-aims so the tiny test VCF yields a window,
  # FST threshold 0 so all diagnostic SNPs survive the AIM step, n-reps 1 for determinism.
  log "TIER 2: invoking pipeline (min-aims=5, fst-threshold=0.0, n-reps=1, seed=1)"
  bash "$pipeline" \
      --vcf "$vcf" \
      --input "$in_list" \
      --parent1 "$p1_list" \
      --parent2 "$p2_list" \
      --window 50000 --step 10000 \
      --min-aims 5 --fst-threshold 0.0 \
      --n-reps 1 --seed 1 \
      --outdir "$work/out" >"$E2E_LOG" 2>&1
  local rc=$?

  if [[ $rc -ne 0 ]]; then
    log "TIER 2: pipeline exited nonzero ($rc); see $E2E_LOG"
    TIER2_STATUS="failed"
    TIER2_NOTE="pipeline returned $rc"
    rm -rf "$work"; return 1
  fi

  # Validate outputs: 10-column header + ancestry_summary consistency.
  local win="$work/out/hybrid_index_windows.tsv"
  local checks_ok=1
  if [[ ! -f "$win" ]]; then
    log "TIER 2: expected $win not produced"; checks_ok=0
  else
    local ncol; ncol=$(head -1 "$win" | awk -F'\t' '{print NF}')
    if [[ "$ncol" -ne 10 ]]; then
      log "TIER 2: windows header has $ncol cols, expected 10"; checks_ok=0
    fi
    local nrows; nrows=$(($(wc -l < "$win") - 1))
    if [[ "$nrows" -lt 1 ]]; then
      log "TIER 2: no data rows in windows output (FST/AIM stage may have dropped all loci)"
      checks_ok=0
    else
      log "TIER 2: windows output OK ($nrows data rows, 10 cols)"
    fi
  fi
  [[ -f "$work/out/ancestry_summary.tsv" ]] && \
    log "TIER 2: ancestry_summary.tsv present" || \
    log "TIER 2: ancestry_summary.tsv MISSING (non-fatal)"

  if [[ $checks_ok -eq 1 ]]; then
    TIER2_STATUS="passed"
  else
    TIER2_STATUS="failed"
    TIER2_NOTE="output validation failed; see $E2E_LOG"
  fi

  rm -rf "$work"
  [[ "$TIER2_STATUS" == "passed" ]]
}

# --------------------------------------------------------------------------- #
# Execute
# --------------------------------------------------------------------------- #
run_tier1; TIER1_RC=$?
run_tier2; TIER2_RC=$?

# --------------------------------------------------------------------------- #
# Report
# --------------------------------------------------------------------------- #
# Overall failure = any RUNNABLE tier that actually ran and failed.
OVERALL="passed"
[[ "$TIER1_STATUS" == "failed" ]] && OVERALL="failed"
[[ "$TIER2_STATUS" == "failed" ]] && OVERALL="failed"

cat > "$REPORT" <<JSON
{
  "status": "$OVERALL",
  "generated": "$(date -u '+%Y-%m-%dT%H:%M:%SZ')",
  "environment": {
    "python": "$($PYTHON --version 2>&1)",
    "pytest": $([[ $PYTEST_OK -eq 1 ]] && echo true || echo false),
    "vcftools": $([[ $VCFTOOLS_OK -eq 1 ]] && echo true || echo false),
    "bgzip": $([[ $BGZIP_OK -eq 1 ]] && echo true || echo false),
    "awk": $([[ $AWK_OK -eq 1 ]] && echo true || echo false)
  },
  "tier1": {
    "status": "$TIER1_STATUS",
    "passed": $TIER1_PASSED,
    "failed": $TIER1_FAILED,
    "skipped": $TIER1_SKIPPED,
    "junit": "$OUTDIR/tier1_junit.xml"
  },
  "tier2": {
    "status": "$TIER2_STATUS",
    "note": "$TIER2_NOTE",
    "e2e_log": "$E2E_LOG"
  },
  "logs": { "test_log": "$LOG" }
}
JSON

log "=== SUMMARY ==="
log "Tier 1: $TIER1_STATUS | Tier 2: $TIER2_STATUS | Overall: $OVERALL"
log "Report: $REPORT"

# Nonzero exit only if a runnable tier failed.
[[ "$OVERALL" == "passed" ]] && exit 0 || exit 1
