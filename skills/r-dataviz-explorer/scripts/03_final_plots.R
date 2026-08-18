#!/usr/bin/env Rscript
# Usage: Rscript 03_final_plots.R <input.csv|.xlsx> <output_dir> [group_col] [theme_path]
# Produces a small set of polished, colorblind-safe ggplot2 figures for the
# variables/relationships identified as most informative during exploration
# (see exploration_log.txt and column_profile.csv from steps 01-02).
required_pkgs <- c("readr", "readxl", "dplyr", "forcats", "ggplot2", "patchwork")
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  stop("Missing required package(s): ", paste(missing_pkgs, collapse = ", "),
       ". Install with: install.packages(c(", paste(sprintf('"%s"', missing_pkgs), collapse = ", "), "))")
}
suppressPackageStartupMessages({
  library(readr)
  library(readxl)
  library(dplyr)
  library(forcats)
  library(ggplot2)
  library(patchwork)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: Rscript 03_final_plots.R <input.csv|.xlsx> <output_dir> [group_col] [theme_path]")
input_path <- args[1]
output_dir <- args[2]
group_col <- if (length(args) >= 3 && nzchar(args[3])) args[3] else NA
theme_path <- if (length(args) >= 4) args[4] else "cb_theme.R"
source(theme_path)

final_dir <- file.path(output_dir, "final")
dir.create(final_dir, showWarnings = FALSE, recursive = TRUE)

read_any <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") read_csv(path, show_col_types = FALSE) else read_excel(path)
}
df <- read_any(input_path)

profile_path <- file.path(output_dir, "column_profile.csv")
profile <- if (file.exists(profile_path)) read_csv(profile_path, show_col_types = FALSE) else NULL

stats_path <- file.path(output_dir, "column_stats.csv")
col_stats <- if (file.exists(stats_path)) read_csv(stats_path, show_col_types = FALSE) else NULL

# Mirrors 02_explore_columns.R's own Pearson-vs-Spearman decision exactly
# (fresh Shapiro-Wilk per column, not a column_stats.csv lookup): column_stats
# only carries a shapiro_pooled row for role=="continuous" columns, so a
# lookup-based version would silently default every discrete_numeric column
# to "assumed normal" and could disagree with 02's own printed decision for
# the identical column set.
decide_cor_method <- function(cols) {
  normal_flags <- vapply(cols, function(cn) {
    xv <- df[[cn]]
    xv <- xv[!is.na(xv)]
    if (length(xv) >= 3 && length(xv) <= 5000 && dplyr::n_distinct(xv) > 1) {
      sw <- tryCatch(shapiro.test(xv), error = function(e) NULL)
      !is.null(sw) && sw$p.value > 0.05
    } else TRUE
  }, logical(1))
  if (mean(normal_flags) < 0.5) "spearman" else "pearson"
}

# Use the ROLES from column_profile.csv, not raw is.numeric(). A numeric row-ID
# is is.numeric() but must never reach a boxplot, scatter or correlation matrix;
# a 0/1 flag is numeric but is not a continuous axis. Steps 01/02 already made
# this call correctly -- re-deriving it here silently discards it.
if (!is.null(profile)) {
  analysis_cols <- profile$column[profile$role %in% c("continuous", "discrete_numeric")]
  plot_cols     <- profile$column[profile$role == "continuous"]   # valid continuous axes
} else {
  analysis_cols <- names(df)[sapply(df, is.numeric)]
  plot_cols     <- analysis_cols
}
numeric_cols <- intersect(analysis_cols, names(df))
if (is.na(group_col) && !is.null(profile)) {
  groupers <- profile$column[profile$role == "categorical_low" |
    (profile$role == "discrete_numeric" & profile$n_unique <= 6)]
  if (length(groupers) >= 1) group_col <- groupers[1]
}
# drop the grouping column from candidate plot axes (never plot a var against itself)
plot_cols <- setdiff(intersect(plot_cols, names(df)), if (is.na(group_col)) character(0) else group_col)

# --- Panel A: distribution of the most interesting continuous variable, by group ---
# "Most interesting" = the variable whose grouped comparison test (whichever
# 02_explore_columns.R routed it to: Kruskal-Wallis, ANOVA, Welch's t, or
# Mann-Whitney) found the strongest separation, i.e. lowest p-value. Test
# statistics aren't comparable across test types, but p-values are. Falls
# back to plot_cols[1] when column_stats.csv wasn't produced (e.g. 03 run
# without 02, or no grouping column).
group_test_names <- c("kruskal", "anova", "welch_t", "mann_whitney")
panelA <- NULL
if (length(plot_cols) >= 1) {
  var1 <- plot_cols[1]
  if (!is.null(col_stats)) {
    ranked <- col_stats %>%
      filter(test %in% group_test_names, column %in% plot_cols) %>%
      arrange(p_value)
    if (nrow(ranked) >= 1) var1 <- ranked$column[1]
  }
  if (!is.na(group_col)) {
    panelA <- ggplot(df, aes(x = fct_reorder(factor(.data[[group_col]]), .data[[var1]], .fun = median),
                              y = .data[[var1]], fill = factor(.data[[group_col]]))) +
      geom_boxplot(alpha = 0.85, outlier.shape = NA, width = 0.6) +
      geom_jitter(width = 0.12, alpha = 0.35, size = 1.2, color = "black") +
      scale_fill_cb_d() +
      labs(title = paste(var1, "by", group_col), x = group_col, y = var1, fill = group_col) +
      theme_cb()
  } else {
    panelA <- ggplot(df, aes(x = .data[[var1]])) +
      geom_histogram(bins = 30, fill = "#0072B2", color = "white", alpha = 0.85) +
      labs(title = paste("Distribution of", var1), x = var1, y = "Count") +
      theme_cb()
  }
}

# --- Panel B: relationship between the two most correlated numeric variables ---
# Pearson assumes normality; default to Spearman when most plot_cols failed
# Shapiro-Wilk (mirrors 02_explore_columns.R's correlation-matrix decision).
# geom_smooth follows suit: "lm" implies linearity (consistent with Pearson),
# "loess" only implies monotonic/smooth (consistent with Spearman).
panelB <- NULL
if (length(plot_cols) >= 2) {
  cor_method <- decide_cor_method(plot_cols)
  corr_mat <- cor(df[plot_cols], method = cor_method, use = "pairwise.complete.obs")
  diag(corr_mat) <- 0
  best <- which(abs(corr_mat) == max(abs(corr_mat)), arr.ind = TRUE)[1, ]
  vx <- rownames(corr_mat)[best[1]]; vy <- colnames(corr_mat)[best[2]]
  overall_r <- cor(df[[vx]], df[[vy]], method = cor_method, use = "complete.obs")
  r_label <- if (cor_method == "pearson") "Pearson r" else "Spearman rho"

  within_note <- ""
  if (!is.na(group_col)) {
    wg <- df[!is.na(df[[vx]]) & !is.na(df[[vy]]) & !is.na(df[[group_col]]), ]
    by_group_r <- tapply(seq_len(nrow(wg)), wg[[group_col]], function(idx) {
      sub <- wg[idx, ]
      if (nrow(sub) >= 3 && sd(sub[[vx]]) > 0 && sd(sub[[vy]]) > 0) {
        round(cor(sub[[vx]], sub[[vy]], method = cor_method), 2)
      } else NA
    })
    vals <- by_group_r[!is.na(by_group_r)]
    if (length(vals) >= 2) within_note <- paste0(" (within-group: ", paste(sprintf("%.2f", vals), collapse = " / "), ")")
  }

  smooth_method <- if (cor_method == "pearson") "lm" else "loess"
  aes_map <- if (!is.na(group_col)) aes(x = .data[[vx]], y = .data[[vy]], color = factor(.data[[group_col]])) else aes(x = .data[[vx]], y = .data[[vy]])
  panelB <- ggplot(df, aes_map) +
    geom_point(alpha = 0.75, size = 2) +
    geom_smooth(method = smooth_method, se = TRUE, color = "grey30", linewidth = 0.7, formula = y ~ x) +
    { if (!is.na(group_col)) scale_color_cb_d() } +
    labs(title = paste(vy, "vs.", vx), x = vx, y = vy,
         subtitle = sprintf("%s = %.2f%s", r_label, overall_r, within_note),
         color = group_col) +
    theme_cb()
}

# --- Panel C: correlation heatmap ---
panelC <- NULL
if (length(numeric_cols) >= 3) {
  cor_method_c <- decide_cor_method(numeric_cols)
  corr_mat <- cor(df[numeric_cols], method = cor_method_c, use = "pairwise.complete.obs")
  corr_df <- as.data.frame(as.table(corr_mat))
  names(corr_df) <- c("var1", "var2", "correlation")
  idx1 <- match(corr_df$var1, colnames(corr_mat))
  idx2 <- match(corr_df$var2, colnames(corr_mat))
  corr_df <- corr_df[idx1 > idx2, ]  # one triangle only, diagonal dropped
  panelC <- ggplot(corr_df, aes(var1, var2, fill = correlation)) +
    geom_tile(color = "white") +
    geom_text(aes(label = sprintf("%.2f", correlation)), size = 2.6) +
    scale_fill_gradient2(low = "#0072B2", mid = "white", high = "#D55E00", midpoint = 0, limits = c(-1, 1)) +
    labs(title = paste0("Correlation matrix (", cor_method_c, ")"), x = NULL, y = NULL) +
    theme_cb() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1), legend.position = "right")
}

# --- Panel D: category counts for the grouping variable ---
panelD <- NULL
if (!is.na(group_col)) {
  panelD <- df %>%
    count(.data[[group_col]]) %>%
    ggplot(aes(x = fct_reorder(factor(.data[[group_col]]), n), y = n, fill = factor(.data[[group_col]]))) +
    geom_col(alpha = 0.9) +
    coord_flip() +
    scale_fill_cb_d() +
    labs(title = paste("Counts by", group_col), x = NULL, y = "Count") +
    theme_cb() +
    theme(legend.position = "none")
}

panels <- Filter(Negate(is.null), list(panelA, panelB, panelC, panelD))
for (i in seq_along(panels)) {
  fname <- file.path(final_dir, sprintf("final_panel_%d.png", i))
  save_cb_plot(panels[[i]], fname, width = 7, height = 5)
}

if (length(panels) >= 2) {
  # patchwork <1.2.0 combined with ggplot2 >=3.5's rewritten guide system can
  # throw "'==' only defined for equally-sized data frames" inside guide
  # collection when panels use different legend.position values. Combining
  # is a nice-to-have on top of the (already-saved) individual panels, so
  # failure here should not take down the whole script.
  combined <- tryCatch(
    wrap_plots(panels, ncol = 2) + plot_annotation(tag_levels = "A"),
    error = function(e) NULL
  )
  if (!is.null(combined)) {
    summary_path <- file.path(final_dir, "final_summary.png")
    ok <- tryCatch({
      save_cb_plot(combined, summary_path, width = 12, height = 9)
      TRUE
    }, error = function(e) {
      # ggsave() opens the PNG device before the guide-collection error fires,
      # so on.exit(dev.off()) still leaves a blank white file at summary_path.
      # Remove it — a missing file is a clearer signal than a blank "result".
      if (file.exists(summary_path)) unlink(summary_path)
      message("[warn] Could not render combined final_summary.png (", conditionMessage(e), ").")
      message("[warn] This is a known patchwork/ggplot2 guide-collection version mismatch — ",
              "individual panels above are unaffected. Try upgrading patchwork (>=1.2.0) to fix.")
      FALSE
    })
  }
}

message("\n", length(panels), " final panel(s) written to ", final_dir)