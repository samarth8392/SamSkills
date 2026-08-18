#!/usr/bin/env Rscript
# Usage: Rscript 01_profile_data.R <input.csv|.xlsx> [output_dir]
required_pkgs <- c("readr", "readxl", "dplyr", "purrr", "tibble")
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  stop("Missing required package(s): ", paste(missing_pkgs, collapse = ", "),
       ". Install with: install.packages(c(", paste(sprintf('"%s"', missing_pkgs), collapse = ", "), "))")
}
suppressPackageStartupMessages({
  library(readr)
  library(readxl)
  library(dplyr)
  library(purrr)
  library(tibble)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 1) stop("Usage: Rscript 01_profile_data.R <input.csv|.xlsx> [output_dir]")
input_path <- args[1]
output_dir <- if (length(args) >= 2) args[2] else "eda_output"
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# Captured once, at the first step of the pipeline, since a patchwork/ggplot2
# guide-collection mismatch (see SKILL.md "Common Mistakes") is exactly the
# kind of failure that's only diagnosable from package versions after the fact.
writeLines(capture.output(sessionInfo()), file.path(output_dir, "session_info.txt"))

read_any <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") {
    read_csv(path, show_col_types = FALSE)
  } else if (ext %in% c("xlsx", "xls")) {
    read_excel(path)
  } else {
    stop("Unsupported file type: ", ext, " (expected .csv, .xlsx, or .xls)")
  }
}

classify_column <- function(x, n) {
  n_missing <- sum(is.na(x))
  n_unique <- dplyr::n_distinct(x, na.rm = TRUE)

  if (n_unique <= 1) {
    role <- "constant"
  } else if (n_unique == n) {
    role <- "identifier"
  } else if (inherits(x, "Date") || inherits(x, "POSIXct")) {
    role <- "datetime"
  } else if (is.numeric(x)) {
    role <- if (n_unique <= 10 && all(x == floor(x), na.rm = TRUE)) "discrete_numeric" else "continuous"
  } else if (is.character(x) || is.factor(x) || is.logical(x)) {
    role <- if (n_unique <= 8) "categorical_low" else "categorical_high"
  } else {
    role <- "other"
  }
  list(n_missing = n_missing, n_unique = n_unique, role = role)
}

suggest_plots <- function(role) {
  switch(role,
    continuous        = "histogram + density; boxplot/violin if a categorical grouping column exists",
    discrete_numeric   = "bar chart of value counts; boxplot if a categorical grouping column exists",
    categorical_low    = "bar chart of counts (ordered by frequency)",
    categorical_high   = "bar chart of top-N categories (+ 'other' bucket)",
    datetime           = "line/count-over-time plot",
    identifier          = "skip (unique per row, not informative to plot)",
    constant            = "skip (zero variance)",
    "no suggestion"
  )
}

suggest_test <- function(role) {
  switch(role,
    continuous        = "Shapiro-Wilk normality check; if grouped by a categorical_low column: Kruskal-Wallis or ANOVA (Welch) after checking normality/variance homogeneity",
    discrete_numeric   = "Kruskal-Wallis if grouped by a categorical_low column",
    categorical_low    = "Chi-square goodness-of-fit vs. uniform; Chi-square test of independence if compared against another categorical column",
    categorical_high   = "Chi-square test of independence (on top-N categories) if compared against another categorical column",
    datetime           = "trend test (e.g. Mann-Kendall) if evenly spaced",
    "none"
  )
}

df <- read_any(input_path)
n <- nrow(df)

profile <- map_dfr(names(df), function(col) {
  x <- df[[col]]
  cls <- classify_column(x, n)
  tibble(
    column = col,
    r_type = class(x)[1],
    role = cls$role,
    n_missing = cls$n_missing,
    pct_missing = round(100 * cls$n_missing / n, 1),
    n_unique = cls$n_unique,
    suggested_plot = suggest_plots(cls$role),
    suggested_test = suggest_test(cls$role)
  )
})

write_csv(profile, file.path(output_dir, "column_profile.csv"))

cat("\n=== Column Profile:", basename(input_path), "===\n")
cat("Rows:", n, " Columns:", ncol(df), "\n\n")
print(as.data.frame(profile), row.names = FALSE)
cat("\nSaved profile ->", file.path(output_dir, "column_profile.csv"), "\n")

n_continuous <- sum(profile$role %in% c("continuous", "discrete_numeric"))
groupers <- profile$column[profile$role == "categorical_low" |
  (profile$role == "discrete_numeric" & profile$n_unique <= 6)]
cat("\nContinuous/discrete-numeric columns:", n_continuous, "\n")
cat("Candidate grouping columns (categorical_low):", if (length(groupers)) paste(groupers, collapse = ", ") else "none", "\n")
if (n_continuous >= 2) cat("-> correlation matrix + pairwise scatter of the most correlated pair is worthwhile\n")
