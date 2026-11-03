# profile_data.R
# Pure helper functions for column-type inference, per-column statistics,
# and plot-type selection. No plotting or rendering side effects.

suppressPackageStartupMessages({
  library(lubridate)
  library(tools)
  library(readr)
  library(readxl)
})

# --- Tunable thresholds ----------------------------------------------------
CATEGORICAL_CARDINALITY_RATIO <- 0.05
CATEGORICAL_MAX_UNIQUE <- 15
IDENTIFIER_UNIQUE_RATIO <- 0.9
NUMERIC_DISCRETE_MAX_UNIQUE <- 30

#' Infer the semantic type of a single column.
#'
#' @param column A vector (the column's values).
#' @param column_name Name of the column (used only for the datetime
#'   name heuristic).
#' @return One of "datetime", "binary", "categorical", "ordinal",
#'   "numeric_continuous", "numeric_discrete", "identifier_text".
infer_column_type <- function(column, column_name = "") {
  non_na <- column[!is.na(column)]
  n_non_na <- length(non_na)
  if (n_non_na == 0) {
    return("identifier_text")
  }
  n_unique <- length(unique(non_na))

  if (is.ordered(column)) {
    return("ordinal")
  }

  if (inherits(column, "Date") || inherits(column, "POSIXct") || inherits(column, "POSIXt")) {
    return("datetime")
  }

  if (is.character(column) && grepl("date|time", column_name, ignore.case = TRUE)) {
    sample_vals <- utils::head(non_na, 20)
    parsed <- suppressWarnings(lubridate::parse_date_time(
      sample_vals, orders = c("ymd", "mdy", "dmy", "ymd HMS", "mdy HMS")
    ))
    if (all(!is.na(parsed))) {
      return("datetime")
    }
  }

  if (n_unique == 2) {
    return("binary")
  }

  if (is.numeric(column)) {
    cardinality_ratio <- n_unique / n_non_na
    is_low_cardinality <- cardinality_ratio < CATEGORICAL_CARDINALITY_RATIO &&
      n_unique <= CATEGORICAL_MAX_UNIQUE
    if (is_low_cardinality) {
      return("categorical")
    }
    all_whole_numbers <- all(non_na == floor(non_na))
    if (all_whole_numbers && n_unique <= NUMERIC_DISCRETE_MAX_UNIQUE) {
      return("numeric_discrete")
    }
    return("numeric_continuous")
  }

  # character or unordered factor
  if (n_unique / n_non_na > IDENTIFIER_UNIQUE_RATIO) {
    return("identifier_text")
  }
  return("categorical")
}

#' Compute descriptive statistics for a single column given its inferred type.
#'
#' @param column A vector (the column's values).
#' @param type A type string as returned by `infer_column_type()`.
#' @return A named list of statistics appropriate to `type`.
profile_column <- function(column, type) {
  n <- length(column)
  missing <- sum(is.na(column))
  non_na <- column[!is.na(column)]

  if (type %in% c("numeric_continuous", "numeric_discrete")) {
    q <- stats::quantile(non_na, probs = c(0.25, 0.5, 0.75), names = FALSE)
    iqr <- q[3] - q[1]
    lower_fence <- q[1] - 1.5 * iqr
    upper_fence <- q[3] + 1.5 * iqr
    n_outliers <- sum(non_na < lower_fence | non_na > upper_fence)
    sd_val <- stats::sd(non_na)
    skewness <- if (is.na(sd_val) || sd_val == 0) {
      0
    } else {
      mean((non_na - mean(non_na))^3) / (sd_val^3)
    }
    return(list(
      n = n, missing = missing,
      mean = mean(non_na), median = q[2], sd = sd_val,
      min = min(non_na), max = max(non_na),
      q1 = q[1], q3 = q[3],
      skewness = skewness,
      n_outliers = n_outliers
    ))
  }

  if (type %in% c("categorical", "binary", "ordinal")) {
    counts <- sort(table(non_na), decreasing = TRUE)
    return(list(
      n = n, missing = missing,
      n_levels = length(counts),
      level_counts = as.list(counts),
      level_proportions = as.list(round(counts / sum(counts), 4)),
      mode = names(counts)[1]
    ))
  }

  if (type == "datetime") {
    return(list(
      n = n, missing = missing,
      min = min(non_na), max = max(non_na),
      range_days = as.numeric(difftime(max(non_na), min(non_na), units = "days"))
    ))
  }

  # identifier_text
  list(n = n, missing = missing, n_unique = length(unique(non_na)))
}

#' Load a CSV/TSV/Excel file into a data frame.
#'
#' @param path Path to a .csv, .tsv, .xlsx, or .xls file.
#' @return A data.frame (tibble for csv/tsv, data.frame for Excel).
load_dataset <- function(path) {
  if (!file.exists(path)) {
    stop(sprintf("File not found: %s", path))
  }
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") {
    as.data.frame(readr::read_csv(path, show_col_types = FALSE))
  } else if (ext == "tsv") {
    as.data.frame(readr::read_tsv(path, show_col_types = FALSE))
  } else if (ext %in% c("xlsx", "xls")) {
    as.data.frame(readxl::read_excel(path))
  } else {
    stop(sprintf("Unsupported file extension: .%s", ext))
  }
}

#' Select which plot types apply to a column of the given inferred type.
#'
#' @param type A type string as returned by `infer_column_type()`.
#' @return A character vector of plot identifiers (possibly empty).
select_plots <- function(type) {
  switch(type,
    numeric_continuous = c("histogram", "boxplot"),
    numeric_discrete = c("histogram", "boxplot"),
    categorical = c("bar"),
    binary = c("bar"),
    ordinal = c("bar_ordered"),
    datetime = c("timeline"),
    identifier_text = character(0),
    character(0)
  )
}

#' Profile every column of a data frame: infer type, compute stats, select plots.
#'
#' @param df A data.frame.
#' @return A data.frame with one row per column: `column` (chr), `type` (chr),
#'   `stats` (list-column of named lists from `profile_column()`), `plots`
#'   (list-column of character vectors from `select_plots()`). For a
#'   zero-column input, returns a schema-correct empty data.frame with the
#'   same four columns (rather than a bare list).
profile_dataset <- function(df) {
  col_names <- names(df)
  if (length(col_names) == 0) {
    empty <- data.frame(column = character(0), type = character(0), stringsAsFactors = FALSE)
    empty$stats <- list()
    empty$plots <- list()
    return(empty)
  }

  types <- character(length(col_names))
  stats_list <- vector("list", length(col_names))
  for (i in seq_along(col_names)) {
    column <- df[[col_names[i]]]
    types[i] <- infer_column_type(column, col_names[i])
    stats_list[[i]] <- profile_column(column, types[i])
  }

  result <- data.frame(column = col_names, type = types, stringsAsFactors = FALSE)
  result$stats <- stats_list
  result$plots <- lapply(types, select_plots)
  result
}
