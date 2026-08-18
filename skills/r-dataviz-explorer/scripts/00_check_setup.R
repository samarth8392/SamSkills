#!/usr/bin/env Rscript
# Usage: Rscript 00_check_setup.R
# Run this FIRST, before 01-04, especially if it's unknown whether R and its
# packages are already set up in this environment. Checks every package the
# four workflow scripts need, combined, in one shot — each of 01-04 also
# checks its own subset before doing any work, but discovering a missing
# package three scripts into the workflow (after already profiling and
# exploring the data) is a worse experience than finding out up front.
#
# This script cannot install R itself — if you're reading this, R already
# ran it. If `Rscript` isn't found at all, R isn't installed; see SKILL.md's
# Step 0 for what to do about that (it's a language runtime, not a package,
# so it isn't handled here).

required_pkgs <- c(
  "readr", "readxl", "dplyr", "purrr", "tibble",  # 01
  "ggplot2", "forcats", "car", "rstatix",          # 02 (+ ggplot2/forcats shared with 03)
  "patchwork"                                       # 03
)
required_pkgs <- unique(required_pkgs)

cat("R version:", R.version.string, "\n\n")

status <- vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)
versions <- vapply(required_pkgs, function(p) {
  if (requireNamespace(p, quietly = TRUE)) as.character(utils::packageVersion(p)) else NA_character_
}, character(1))

report <- data.frame(package = required_pkgs, installed = status, version = versions)
print(report, row.names = FALSE)

missing <- required_pkgs[!status]
cat("\n")
if (length(missing) == 0) {
  cat("All", length(required_pkgs), "required packages are installed. Ready to run 01_profile_data.R.\n")
  quit(status = 0)
} else {
  cat(length(missing), "package(s) missing:", paste(missing, collapse = ", "), "\n")
  cat("Install with:\n\n")
  cat("  install.packages(c(", paste(sprintf('"%s"', missing), collapse = ", "), "))\n\n", sep = "")
  cat("or from the shell:\n\n")
  cat("  Rscript -e 'install.packages(c(", paste(sprintf('"%s"', missing), collapse = ", "), "))'\n\n", sep = "")
  quit(status = 1)
}
