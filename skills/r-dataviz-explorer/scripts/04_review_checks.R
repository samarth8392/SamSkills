#!/usr/bin/env Rscript
# Usage: Rscript 04_review_checks.R <input.csv|.xlsx> <output_dir> [missingness_threshold_pct]
# Mechanical complement to workflow step 4 (REASSESS): the things a human/agent
# should catch by reading exploration_log.txt and opening the PNGs, checked in
# code instead of by eye. Does not replace that read — a near-zero-variance
# flag or a missing log entry still needs a judgment call — but it catches the
# two failure modes this skill has actually hit (a column silently dropped
# from the log, a column plotted with the wrong role) mechanically every time.
required_pkgs <- c("readr", "readxl", "dplyr")
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  stop("Missing required package(s): ", paste(missing_pkgs, collapse = ", "),
       ". Install with: install.packages(c(", paste(sprintf('"%s"', missing_pkgs), collapse = ", "), "))")
}
suppressPackageStartupMessages({
  library(readr)
  library(readxl)
  library(dplyr)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: Rscript 04_review_checks.R <input.csv|.xlsx> <output_dir> [missingness_threshold_pct]")
input_path <- args[1]
output_dir <- args[2]
missingness_threshold <- if (length(args) >= 3) as.numeric(args[3]) else 20

read_any <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") read_csv(path, show_col_types = FALSE) else read_excel(path)
}

results <- character(0)
add_result <- function(status, msg) {
  results <<- c(results, paste0("[", status, "] ", msg))
}

# Word-boundary match for a column name inside a log line, using \\Q...\\E
# (literal quoting) so a column name containing regex metacharacters (e.g.
# "score.1") is matched as a literal string, not interpreted as a pattern.
col_mentioned <- function(col, lines) {
  pattern <- paste0("(^|[^A-Za-z0-9._])", "\\Q", col, "\\E", "([^A-Za-z0-9._]|$)")
  any(grepl(pattern, lines, perl = TRUE))
}

profile_path <- file.path(output_dir, "column_profile.csv")
log_path <- file.path(output_dir, "exploration_log.txt")
final_dir <- file.path(output_dir, "final")

if (!file.exists(profile_path)) stop("column_profile.csv not found in ", output_dir, " — run 01_profile_data.R first")
profile <- read_csv(profile_path, show_col_types = FALSE)
df <- read_any(input_path)

# --- Check 1: every profiled column is accounted for in the log as [plot] or [skip] ---
if (!file.exists(log_path)) {
  add_result("FAIL", "exploration_log.txt not found — run 02_explore_columns.R before reviewing")
} else {
  log_lines <- readLines(log_path)
  plot_lines <- grep("^\\[plot\\]", log_lines, value = TRUE)
  skip_lines <- grep("^\\[skip\\]", log_lines, value = TRUE)
  for (col in profile$column) {
    # word-boundary match so e.g. "wt" doesn't false-match inside "gearwt"
    mentioned <- col_mentioned(col, plot_lines) || col_mentioned(col, skip_lines)
    if (!mentioned) {
      add_result("FAIL", paste0(col, " appears in column_profile.csv but not in exploration_log.txt as [plot] or [skip] — was it silently dropped?"))
    }
  }
  n_missing_from_log <- sum(!vapply(profile$column, function(col) {
    col_mentioned(col, plot_lines) || col_mentioned(col, skip_lines)
  }, logical(1)))
  if (n_missing_from_log == 0) add_result("PASS", "every column in column_profile.csv is accounted for in exploration_log.txt")
}

# --- Check 2: missingness threshold ---
high_missing <- profile[profile$pct_missing > missingness_threshold, ]
if (nrow(high_missing) == 0) {
  add_result("PASS", paste0("no column exceeds ", missingness_threshold, "% missingness"))
} else {
  for (i in seq_len(nrow(high_missing))) {
    add_result("WARN", paste0(high_missing$column[i], " is ", high_missing$pct_missing[i],
                               "% missing — check whether it should be excluded or imputed before it's used in a plot/test"))
  }
}

# --- Check 3: near-zero variance among continuous/discrete_numeric columns ---
# `constant` role (sd == 0) is already skipped upstream; this catches the
# almost-constant case that still passes the n_unique check but produces an
# uninformative flat histogram/boxplot.
num_roles <- profile[profile$role %in% c("continuous", "discrete_numeric"), ]
for (i in seq_len(nrow(num_roles))) {
  col <- num_roles$column[i]
  x <- df[[col]]
  x <- x[!is.na(x)]
  if (length(x) >= 2) {
    m <- mean(x)
    s <- sd(x)
    cv <- if (abs(m) > 1e-8) s / abs(m) else NA
    if (!is.na(cv) && cv < 0.01) {
      add_result("WARN", paste0(col, " has coefficient of variation ", signif(cv, 3),
                                 " — near-constant; its plot may look uninformatively flat"))
    }
  }
}

# --- Check 4: role vs. logged content sanity check ---
if (file.exists(log_path)) {
  all_log_lines <- readLines(log_path)
  for (i in seq_len(nrow(profile))) {
    col <- profile$column[i]
    role <- profile$role[i]
    pattern <- paste0("(^|[^A-Za-z0-9._])", "\\Q", col, "\\E", "([^A-Za-z0-9._]|$)")
    col_lines <- grep(pattern, all_log_lines, value = TRUE, perl = TRUE)
    plot_line <- grep("^\\[plot\\]", col_lines, value = TRUE)
    if (length(plot_line) == 0) next  # already flagged by Check 1, or a [skip]/[note]-only column
    if (role == "continuous" && !any(grepl("Shapiro-Wilk|-> eda_", plot_line))) {
      add_result("WARN", paste0(col, " is role 'continuous' but its log line doesn't look like a histogram/density entry — check it wasn't mis-routed"))
    }
    if (role %in% c("categorical_low", "categorical_high", "discrete_numeric") && !any(grepl("unique values", plot_line))) {
      add_result("WARN", paste0(col, " is role '", role, "' but its log line doesn't mention unique values — check it wasn't mis-routed to a histogram"))
    }
    if (role == "datetime" && !any(grepl("datetime", plot_line))) {
      add_result("WARN", paste0(col, " is role 'datetime' but its log line doesn't confirm datetime handling — check it wasn't silently skipped"))
    }
  }
}

# --- Check 5: final panel files exist and aren't suspiciously small (blank-PNG proxy) ---
if (!dir.exists(final_dir)) {
  add_result("WARN", "final/ directory not found — run 03_final_plots.R before this check, or ignore if not finalizing yet")
} else {
  pngs <- list.files(final_dir, pattern = "\\.png$", full.names = TRUE)
  if (length(pngs) == 0) {
    add_result("WARN", "final/ directory exists but contains no PNGs")
  } else {
    for (f in pngs) {
      sz <- file.info(f)$size
      if (is.na(sz) || sz < 3000) {
        add_result("WARN", paste0(basename(f), " is only ", sz, " bytes — open it, this is the size of a blank/near-empty PNG, not a rendered figure"))
      } else {
        add_result("PASS", paste0(basename(f), " (", sz, " bytes) exists and is not suspiciously small — still open it, file size is only a proxy"))
      }
    }
  }
}

cat("\n=== Review checklist:", basename(input_path), "===\n\n")
cat(paste(results, collapse = "\n"), "\n")

n_fail <- sum(grepl("^\\[FAIL\\]", results))
n_warn <- sum(grepl("^\\[WARN\\]", results))
cat("\n", n_fail, "FAIL,", n_warn, "WARN,", sum(grepl("^\\[PASS\\]", results)), "PASS\n")

writeLines(c(paste("Review checklist:", basename(input_path)), "", results,
             "", paste(n_fail, "FAIL,", n_warn, "WARN,", sum(grepl("^\\[PASS\\]", results)), "PASS")),
           file.path(output_dir, "review_checklist.txt"))
cat("\nChecklist written ->", file.path(output_dir, "review_checklist.txt"), "\n")
