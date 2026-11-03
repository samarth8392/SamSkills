#!/usr/bin/env bash
# run_report.sh — render the r-dataviz-explorer HTML report for a dataset.
#
# Usage: ./run_report.sh <path/to/data.csv|xlsx> [output_dir]
#
# Copies report_template.qmd (and its helper scripts) into output_dir so
# repeated/concurrent runs on different datasets don't clobber each other's
# Quarto intermediate files, then renders it with the data_path parameter.

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <path/to/data.csv|xlsx> [output_dir]" >&2
  exit 1
fi

if [[ ! -f "$1" ]]; then
  echo "Error: input file not found: $1" >&2
  exit 1
fi
DATA_PATH="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DATA_BASENAME="$(basename "$DATA_PATH")"
DATA_STEM="${DATA_BASENAME%.*}"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

if [[ $# -ge 2 ]]; then
  OUTPUT_DIR="$2"
else
  OUTPUT_DIR="$(dirname "$DATA_PATH")/${DATA_STEM}_report_${TIMESTAMP}"
fi

mkdir -p "$OUTPUT_DIR"
# Resolve to an absolute path so LOG_FILE/OUTPUT_HTML stay correct once we
# `cd` into it below (a relative OUTPUT_DIR would otherwise be re-applied
# relative to the new cwd, e.g. "output/render.log" -> "output/output/render.log").
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"
cp "$SCRIPT_DIR/report_template.qmd" "$OUTPUT_DIR/report_template.qmd"
cp "$SCRIPT_DIR/profile_data.R" "$OUTPUT_DIR/profile_data.R"
cp "$SCRIPT_DIR/plot_theme.R" "$OUTPUT_DIR/plot_theme.R"

LOG_FILE="$OUTPUT_DIR/render.log"
OUTPUT_HTML="${DATA_STEM}_report.html"

echo "Rendering report for $DATA_PATH ..."
if (cd "$OUTPUT_DIR" && quarto render report_template.qmd \
      -P "data_path:$DATA_PATH" \
      --output "$OUTPUT_HTML" > "$LOG_FILE" 2>&1); then
  echo "Report rendered: $OUTPUT_DIR/$OUTPUT_HTML"
  echo "Render log: $LOG_FILE"
  exit 0
else
  echo "Render FAILED. See log: $LOG_FILE" >&2
  tail -n 40 "$LOG_FILE" >&2
  exit 1
fi
