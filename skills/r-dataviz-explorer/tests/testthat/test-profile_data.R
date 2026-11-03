library(testthat)

source("/Users/mathurs2/Documents/2026/genAI_btep_talk/skill_creation/r-dataviz-explorer/scripts/profile_data.R")

test_that("infer_column_type detects numeric_continuous", {
  set.seed(1)
  x <- rnorm(200, mean = 10, sd = 2)
  expect_equal(infer_column_type(x, "value"), "numeric_continuous")
})

test_that("infer_column_type detects numeric_discrete", {
  set.seed(1)
  x <- sample(1:20, 200, replace = TRUE)
  expect_equal(infer_column_type(x, "count"), "numeric_discrete")
})

test_that("infer_column_type detects categorical from low-cardinality numeric", {
  x <- rep(c(1, 2, 3), 100)
  expect_equal(infer_column_type(x, "group_code"), "categorical")
})

test_that("infer_column_type detects categorical from character column", {
  x <- rep(c("setosa", "versicolor", "virginica"), 50)
  expect_equal(infer_column_type(x, "species"), "categorical")
})

test_that("infer_column_type detects binary", {
  x <- rep(c("yes", "no"), 50)
  expect_equal(infer_column_type(x, "flag"), "binary")
})

test_that("infer_column_type detects identifier_text", {
  x <- paste0("id-", seq_len(100))
  expect_equal(infer_column_type(x, "record_id"), "identifier_text")
})

test_that("infer_column_type detects datetime from Date class", {
  x <- as.Date("2020-01-01") + 0:99
  expect_equal(infer_column_type(x, "some_column"), "datetime")
})

test_that("infer_column_type detects datetime from parseable character column named with date/time", {
  x <- c("2020-01-01", "2020-02-15", "2020-03-20", "2020-04-10")
  expect_equal(infer_column_type(x, "event_date"), "datetime")
})

test_that("infer_column_type detects ordinal from ordered factor", {
  x <- factor(rep(c("low", "medium", "high"), 20),
              levels = c("low", "medium", "high"), ordered = TRUE)
  expect_equal(infer_column_type(x, "severity"), "ordinal")
})

test_that("profile_column computes numeric stats correctly", {
  x <- c(1, 2, 3, 4, 5, 100)  # 100 is an outlier
  stats <- profile_column(x, "numeric_continuous")
  expect_equal(stats$n, 6)
  expect_equal(stats$missing, 0)
  expect_equal(stats$min, 1)
  expect_equal(stats$max, 100)
  expect_equal(stats$median, 3.5)
  expect_equal(stats$n_outliers, 1)
})

test_that("profile_column handles missing values in numeric columns", {
  x <- c(1, 2, NA, 4, 5)
  stats <- profile_column(x, "numeric_continuous")
  expect_equal(stats$n, 5)
  expect_equal(stats$missing, 1)
  expect_equal(stats$mean, 3)
})

test_that("profile_column computes categorical stats correctly", {
  x <- c("a", "a", "a", "b", "b", "c")
  stats <- profile_column(x, "categorical")
  expect_equal(stats$n, 6)
  expect_equal(stats$missing, 0)
  expect_equal(stats$n_levels, 3)
  expect_equal(stats$mode, "a")
  expect_equal(unname(stats$level_counts[["a"]]), 3)
})

test_that("profile_column computes datetime stats correctly", {
  x <- as.Date("2020-01-01") + c(0, 5, 10)
  stats <- profile_column(x, "datetime")
  expect_equal(stats$n, 3)
  expect_equal(stats$range_days, 10)
})

test_that("profile_column computes identifier_text stats correctly", {
  x <- paste0("id-", 1:10)
  stats <- profile_column(x, "identifier_text")
  expect_equal(stats$n, 10)
  expect_equal(stats$n_unique, 10)
})

test_that("select_plots returns expected plot ids per type", {
  expect_setequal(select_plots("numeric_continuous"), c("histogram", "boxplot"))
  expect_setequal(select_plots("categorical"), c("bar"))
  expect_setequal(select_plots("identifier_text"), character(0))
})

test_that("load_dataset reads a csv file", {
  tmp <- tempfile(fileext = ".csv")
  write.csv(data.frame(a = 1:3, b = c("x", "y", "z")), tmp, row.names = FALSE)
  df <- load_dataset(tmp)
  expect_equal(nrow(df), 3)
  expect_equal(ncol(df), 2)
  unlink(tmp)
})

test_that("load_dataset errors on missing file", {
  expect_error(load_dataset("/no/such/file.csv"), "not found")
})

test_that("profile_dataset profiles every column of a small data frame", {
  df <- data.frame(
    id = paste0("id-", 1:20),
    value = rnorm(20),
    group = rep(c("a", "b", "c"), length.out = 20),
    stringsAsFactors = FALSE
  )
  result <- profile_dataset(df)
  expect_equal(nrow(result), 3)
  expect_setequal(result$column, c("id", "value", "group"))
  id_row <- result[result$column == "id", ]
  expect_equal(id_row$type, "identifier_text")
  value_row <- result[result$column == "value", ]
  expect_equal(value_row$type, "numeric_continuous")
  group_row <- result[result$column == "group", ]
  expect_equal(group_row$type, "categorical")
})
