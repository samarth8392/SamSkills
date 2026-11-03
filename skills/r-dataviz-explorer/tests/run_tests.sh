#!/usr/bin/env bash
# run_tests.sh — regression tests for r-dataviz-explorer.
# Runs the testthat unit tests, then renders both fixture datasets
# end-to-end and asserts the HTML output exists and is non-trivial in size.

set -uo pipefail

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$TESTS_DIR")"
SCRIPTS_DIR="$SKILL_DIR/scripts"
FIXTURES_DIR="$TESTS_DIR/fixtures"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

PASS=0
FAIL=0

echo "=== Unit tests (testthat) ==="
Rscript -e "testthat::test_file('$TESTS_DIR/testthat/test-profile_data.R')" 2>&1 | tee "$WORK_DIR/unit_tests.log"
# testthat prints a running "[ FAIL n | WARN n | SKIP n | PASS n ]" summary
# after every assertion, so grep -q "FAIL 0" would match an early passing
# line even if a later assertion fails and bumps the count. Only the final
# summary line reflects the true totals.
last_summary="$(grep -E '\[ FAIL [0-9]+ \| WARN [0-9]+ \| SKIP [0-9]+ \| PASS [0-9]+ \]' "$WORK_DIR/unit_tests.log" | tail -n 1)"
if [[ -n "$last_summary" && "$last_summary" == *"FAIL 0"* ]]; then
  echo "PASS: unit tests ($last_summary)"
  PASS=$((PASS + 1))
else
  echo "FAIL: unit tests reported failures ($last_summary)"
  FAIL=$((FAIL + 1))
fi

MIN_HTML_BYTES=10000

check_report() {
  local name="$1"
  local fixture="$2"
  echo ""
  echo "=== Render smoke test: $name ==="
  local out_dir="$WORK_DIR/$name"
  if "$SCRIPTS_DIR/run_report.sh" "$fixture" "$out_dir"; then
    local log_file="$out_dir/render.log"
    if [[ -f "$log_file" ]] && grep -qE 'Error|Execution halted' "$log_file"; then
      echo "FAIL: $name render.log contains an Error/Execution halted despite exit 0"
      FAIL=$((FAIL + 1))
      return
    fi
    local html_file
    html_file=$(find "$out_dir" -maxdepth 1 -name "*_report.html" | head -n 1)
    if [[ -n "$html_file" ]]; then
      local size
      size=$(stat -f%z "$html_file" 2>/dev/null || stat -c%s "$html_file")
      if [[ "$size" -ge "$MIN_HTML_BYTES" ]]; then
        echo "PASS: $name report rendered ($size bytes)"
        PASS=$((PASS + 1))
        return
      fi
    fi
  fi
  echo "FAIL: $name report did not render correctly"
  FAIL=$((FAIL + 1))
}

check_report "iris" "$FIXTURES_DIR/iris.csv"
check_report "mtcars" "$FIXTURES_DIR/mtcars.csv"
# wide_categorical.csv has a 12-level categorical column (in-spec: below
# CATEGORICAL_MAX_UNIQUE=15) — regression guard for the Okabe-Ito 8-color
# manual-scale overflow bug found in final review (fixed in plot_theme.R).
check_report "wide_categorical" "$FIXTURES_DIR/wide_categorical.csv"

echo ""
echo "=== Summary ==="
echo "PASS: $PASS  FAIL: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then
  exit 1
fi
exit 0
