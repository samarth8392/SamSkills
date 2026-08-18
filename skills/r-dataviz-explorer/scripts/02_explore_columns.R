#!/usr/bin/env Rscript
# Usage: Rscript 02_explore_columns.R <input.csv|.xlsx> <output_dir> [theme_path]
# Reads column_profile.csv written by 01_profile_data.R, makes one diagnostic
# plot (+ appropriate stat test) per non-skippable column, and writes
# exploration_log.txt and column_stats.csv for self-review and for
# 03_final_plots.R to rank "most interesting" variables by.
required_pkgs <- c("readr", "readxl", "dplyr", "ggplot2", "forcats", "car", "rstatix")
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  stop("Missing required package(s): ", paste(missing_pkgs, collapse = ", "),
       ". Install with: install.packages(c(", paste(sprintf('"%s"', missing_pkgs), collapse = ", "), "))")
}
suppressPackageStartupMessages({
  library(readr)
  library(readxl)
  library(dplyr)
  library(ggplot2)
  library(forcats)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: Rscript 02_explore_columns.R <input.csv|.xlsx> <output_dir> [theme_path]")
input_path <- args[1]
output_dir <- args[2]
theme_path <- if (length(args) >= 3) args[3] else "cb_theme.R"

plot_dir <- file.path(output_dir, "exploration")
dir.create(plot_dir, showWarnings = FALSE, recursive = TRUE)
log_path <- file.path(output_dir, "exploration_log.txt")
log_lines <- character(0)
log_msg <- function(...) {
  msg <- paste0(...)
  log_lines <<- c(log_lines, msg)
  message(msg)
}

# Every ggsave()/plotting call in this script should route through here so a
# dropped point, a coerced type, or an NA-heavy column shows up in the log
# instead of only ever reaching the console (and getting lost, since Rscript's
# stderr isn't captured anywhere agents are told to read).
with_warning_log <- function(expr, context) {
  withCallingHandlers(
    expr,
    warning = function(w) {
      log_msg("[warn] ", context, ": ", conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )
}

stats_rows <- list()
add_stat <- function(column, test, statistic, p_value, note = "") {
  stats_rows[[length(stats_rows) + 1]] <<- data.frame(
    column = column, test = test,
    statistic = as.numeric(statistic), p_value = as.numeric(p_value),
    note = note, stringsAsFactors = FALSE
  )
}

source(theme_path)

read_any <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") read_csv(path, show_col_types = FALSE) else read_excel(path)
}

profile_path <- file.path(output_dir, "column_profile.csv")
if (!file.exists(profile_path)) stop("column_profile.csv not found in ", output_dir, " — run 01_profile_data.R first")
profile <- read_csv(profile_path, show_col_types = FALSE)
df <- read_any(input_path)

groupers <- profile$column[profile$role == "categorical_low" |
  (profile$role == "discrete_numeric" & profile$n_unique <= 6)]
group_col <- if (length(groupers) >= 1) groupers[1] else NA

log_msg("Exploration of ", basename(input_path), " (", nrow(df), " rows, ", ncol(df), " cols)")
log_msg("Grouping column used for split plots: ", if (is.na(group_col)) "none found" else group_col)
log_msg("")

for (i in seq_len(nrow(profile))) {
  col <- profile$column[i]
  role <- profile$role[i]
  x <- df[[col]]
  n_missing <- sum(is.na(x))
  missing_note <- if (n_missing > 0) paste0(" | ", n_missing, " missing (", profile$pct_missing[i], "%)") else ""

  if (role %in% c("identifier", "constant")) {
    log_msg("[skip] ", col, " (", role, ")")
    next
  }

  fname <- file.path(plot_dir, paste0("eda_", make.names(col), ".png"))

  if (role == "continuous") {
    p <- ggplot(df, aes(x = .data[[col]])) +
      geom_histogram(aes(y = after_stat(density)), bins = 30, fill = "#0072B2", alpha = 0.7, color = "white") +
      geom_density(color = "#D55E00", linewidth = 0.9) +
      labs(title = paste("Distribution of", col), x = col, y = "Density") +
      theme_cb()
    with_warning_log(ggsave(fname, p, width = 6, height = 4, dpi = 150, bg = "white"), paste("histogram of", col))

    n_valid <- sum(!is.na(x))
    if (n_valid >= 3 && n_valid <= 5000 && dplyr::n_distinct(x, na.rm = TRUE) > 1) {
      sw <- tryCatch(shapiro.test(x), error = function(e) NULL)
      if (!is.null(sw)) {
        add_stat(col, "shapiro_pooled", sw$statistic, sw$p.value)
        log_msg("[plot] ", col, " -> ", basename(fname), " | Shapiro-Wilk W=", round(sw$statistic, 3),
                " p=", signif(sw$p.value, 3), if (sw$p.value < 0.05) " (non-normal)" else " (approx. normal)",
                missing_note)
      }
    } else {
      log_msg("[plot] ", col, " -> ", basename(fname), missing_note)
    }

    if (!is.na(group_col) && group_col != col) {
      gfname <- file.path(plot_dir, paste0("eda_", make.names(col), "_by_", make.names(group_col), ".png"))
      pg <- ggplot(df, aes(x = factor(.data[[group_col]]), y = .data[[col]], fill = factor(.data[[group_col]]))) +
        geom_boxplot(alpha = 0.8, outlier.shape = NA) +
        geom_jitter(width = 0.15, alpha = 0.4, size = 1) +
        scale_fill_cb_d() +
        labs(title = paste(col, "by", group_col), x = group_col, y = col, fill = group_col) +
        theme_cb()
      with_warning_log(ggsave(gfname, pg, width = 6, height = 4.5, dpi = 150, bg = "white"),
                        paste(col, "by", group_col))

      groups <- split(x, df[[group_col]])
      groups <- groups[lengths(groups) >= 2]
      k <- length(groups)
      if (k >= 2) {
        tmp <- data.frame(value = x, group = factor(df[[group_col]]))
        tmp <- tmp[!is.na(tmp$value) & tmp$group %in% names(groups), , drop = FALSE]
        tmp$group <- droplevels(tmp$group)

        # Route parametric vs. non-parametric per column_to_plot_guide.md
        # Step 3: check normality *within each group* and equal variance
        # (Levene's), not just on the pooled column above — a column can be
        # non-normal pooled but normal within each group, or vice versa.
        group_normal <- vapply(split(tmp$value, tmp$group), function(g) {
          if (length(g) >= 3 && dplyr::n_distinct(g) > 1) {
            sw <- tryCatch(shapiro.test(g), error = function(e) NULL)
            !is.null(sw) && sw$p.value > 0.05
          } else FALSE
        }, logical(1))
        all_normal <- length(group_normal) == k && all(group_normal)

        lv <- tryCatch(car::leveneTest(value ~ group, data = tmp), error = function(e) NULL)
        equal_var <- !is.null(lv) && lv[["Pr(>F)"]][1] > 0.05
        use_parametric <- all_normal && equal_var

        if (k == 2) {
          if (use_parametric) {
            tt <- tryCatch(t.test(value ~ group, data = tmp), error = function(e) NULL)
            if (!is.null(tt)) {
              add_stat(col, "welch_t", tt$statistic, tt$p.value)
              log_msg("[plot] ", col, " by ", group_col, " -> ", basename(gfname),
                      " | Welch's t-test t=", round(tt$statistic, 2), " p=", signif(tt$p.value, 3), missing_note)
            }
          } else {
            wt <- tryCatch(wilcox.test(value ~ group, data = tmp), error = function(e) NULL)
            if (!is.null(wt)) {
              add_stat(col, "mann_whitney", wt$statistic, wt$p.value)
              log_msg("[plot] ", col, " by ", group_col, " -> ", basename(gfname),
                      " | Mann-Whitney U W=", round(wt$statistic, 2), " p=", signif(wt$p.value, 3), missing_note)
            }
          }
        } else {
          if (use_parametric) {
            av <- tryCatch(aov(value ~ group, data = tmp), error = function(e) NULL)
            if (!is.null(av)) {
              av_summ <- summary(av)[[1]]
              f_stat <- av_summ[["F value"]][1]
              f_p <- av_summ[["Pr(>F)"]][1]
              add_stat(col, "anova", f_stat, f_p)
              log_msg("[plot] ", col, " by ", group_col, " -> ", basename(gfname),
                      " | One-way ANOVA F=", round(f_stat, 2), " p=", signif(f_p, 3), missing_note)
              tk <- tryCatch(TukeyHSD(av), error = function(e) NULL)
              if (!is.null(tk)) {
                tk_df <- as.data.frame(tk$group)
                sig <- rownames(tk_df)[tk_df$`p adj` < 0.05]
                log_msg("[note] Tukey HSD post-hoc for ", col, ": significant pairs (p<.05): ",
                        if (length(sig)) paste(sig, collapse = ", ") else "none")
              }
            }
          } else {
            kw <- tryCatch(kruskal.test(value ~ group, data = tmp), error = function(e) NULL)
            if (!is.null(kw)) {
              add_stat(col, "kruskal", kw$statistic, kw$p.value)
              log_msg("[plot] ", col, " by ", group_col, " -> ", basename(gfname),
                      " | Kruskal-Wallis chi-sq=", round(kw$statistic, 2), " p=", signif(kw$p.value, 3), missing_note)
              dt <- tryCatch(rstatix::dunn_test(tmp, value ~ group), error = function(e) NULL)
              if (!is.null(dt)) {
                sig <- dt$p.adj.signif != "ns"
                pairs_sig <- paste0(dt$group1[sig], "-", dt$group2[sig])
                log_msg("[note] Dunn post-hoc for ", col, " (BH-adjusted): significant pairs (p<.05): ",
                        if (any(sig)) paste(pairs_sig, collapse = ", ") else "none")
              }
            }
          }
        }
      }
    }
  } else if (role == "datetime") {
    # column_profile.csv only assigns role "datetime" when read_any() already
    # parsed the column as Date/POSIXct (classify_column()'s inherits() check
    # requires it) — so x here is guaranteed to be a real date/time vector,
    # not a string that merely looks like one.
    ts <- df %>% filter(!is.na(.data[[col]])) %>% count(.data[[col]], name = "n")
    names(ts)[1] <- "date"
    p <- ggplot(ts, aes(x = date, y = n)) +
      geom_line(color = "#0072B2", linewidth = 0.8) +
      geom_point(color = "#0072B2", size = 1.6, alpha = 0.8) +
      labs(title = paste("Count over time:", col), x = col, y = "Count") +
      theme_cb()
    with_warning_log(ggsave(fname, p, width = 7, height = 4, dpi = 150, bg = "white"), paste("count-over-time of", col))
    log_msg("[plot] ", col, " -> ", basename(fname), " | datetime, range ",
            format(min(x, na.rm = TRUE)), " to ", format(max(x, na.rm = TRUE)), missing_note)
  } else if (role %in% c("categorical_low", "categorical_high", "discrete_numeric")) {
    # Low-cardinality numeric columns (e.g. a 0/1 flag or a 3-level count) plot
    # better as a bar chart of counts than as a density curve — a density
    # estimate over 2-3 distinct values is misleading, not informative.
    counts <- df %>% count(.data[[col]], sort = TRUE)
    top_n <- 15
    if (nrow(counts) > top_n) {
      log_msg("[note] ", col, " has ", nrow(counts), " categories — showing top ", top_n)
      counts <- head(counts, top_n)
    }
    # discrete_numeric columns are ordinal (cyl, gear, carb, a Likert score) —
    # reordering their bars by frequency destroys the order that makes them
    # readable. Only nominal categoricals get frequency ordering.
    if (role == "discrete_numeric") {
      x_aes <- factor(counts[[col]], levels = sort(unique(counts[[col]])))
    } else {
      x_aes <- fct_reorder(as.factor(counts[[col]]), counts$n)
    }
    p <- ggplot(counts, aes(x = x_aes, y = n)) +
      geom_col(fill = "#0072B2") +
      coord_flip() +
      labs(title = paste("Counts of", col), x = NULL, y = "Count") +
      theme_cb()
    with_warning_log(ggsave(fname, p, width = 6, height = max(3, 0.35 * nrow(counts)), dpi = 150, bg = "white"),
                      paste("counts of", col))
    n_unique_val <- dplyr::n_distinct(x, na.rm = TRUE)
    log_msg("[plot] ", col, " -> ", basename(fname), " | ", n_unique_val, " unique values", missing_note)

    # Chi-square routing (column_to_plot_guide.md Step 3). Skipped for
    # discrete_numeric: "uniform" isn't a meaningful null for an ordinal
    # count/Likert column the way it is for a nominal category.
    if (role %in% c("categorical_low", "categorical_high")) {
      tab <- table(x)
      if (length(tab) >= 2 && all(tab > 0)) {
        gof <- tryCatch(chisq.test(tab), error = function(e) NULL)
        if (!is.null(gof)) {
          add_stat(col, "chisq_gof", gof$statistic, gof$p.value)
          log_msg("[plot] ", col, " | Chi-square goodness-of-fit (vs. uniform) X-sq=",
                  round(gof$statistic, 2), " p=", signif(gof$p.value, 3))
        }
      }
      if (!is.na(group_col) && group_col != col) {
        tab2 <- table(x, df[[group_col]])
        if (all(dim(tab2) >= 2)) {
          expected_ok <- tryCatch({
            e <- suppressWarnings(chisq.test(tab2))$expected
            all(e >= 5)
          }, error = function(e) FALSE)
          if (expected_ok) {
            ind <- tryCatch(chisq.test(tab2), error = function(e) NULL)
            if (!is.null(ind)) {
              add_stat(col, "chisq_ind", ind$statistic, ind$p.value)
              log_msg("[plot] ", col, " vs ", group_col, " | Chi-square test of independence X-sq=",
                      round(ind$statistic, 2), " p=", signif(ind$p.value, 3))
            }
          } else {
            fe <- tryCatch(fisher.test(tab2), error = function(e) NULL)
            if (!is.null(fe)) {
              add_stat(col, "fisher_exact", NA, fe$p.value)
              log_msg("[plot] ", col, " vs ", group_col, " | Fisher's exact test (expected cell < 5) p=",
                      signif(fe$p.value, 3))
            }
          }
        }
      }
    }
  } else {
    log_msg("[skip] ", col, " (role '", role, "' not handled by this template — extend manually)")
  }
}

numeric_cols <- profile$column[profile$role %in% c("continuous", "discrete_numeric")]
if (length(numeric_cols) >= 2) {
  # Pearson assumes a roughly linear, normally-distributed relationship;
  # default to Spearman when most of the columns going into the matrix
  # failed Shapiro-Wilk, per column_to_plot_guide.md Step 3.
  normal_flags <- vapply(numeric_cols, function(cn) {
    xv <- df[[cn]]
    xv <- xv[!is.na(xv)]
    if (length(xv) >= 3 && length(xv) <= 5000 && dplyr::n_distinct(xv) > 1) {
      sw <- tryCatch(shapiro.test(xv), error = function(e) NULL)
      !is.null(sw) && sw$p.value > 0.05
    } else TRUE
  }, logical(1))
  cor_method <- if (mean(normal_flags) < 0.5) "spearman" else "pearson"

  corr_mat <- cor(df[numeric_cols], method = cor_method, use = "pairwise.complete.obs")
  corr_df <- as.data.frame(as.table(corr_mat))
  names(corr_df) <- c("var1", "var2", "correlation")
  idx1 <- match(corr_df$var1, colnames(corr_mat))
  idx2 <- match(corr_df$var2, colnames(corr_mat))
  corr_df <- corr_df[idx1 > idx2, ]  # one triangle only, diagonal dropped
  p <- ggplot(corr_df, aes(var1, var2, fill = correlation)) +
    geom_tile(color = "white") +
    geom_text(aes(label = sprintf("%.2f", correlation)), size = 3) +
    scale_fill_gradient2(low = "#0072B2", mid = "white", high = "#D55E00", midpoint = 0, limits = c(-1, 1)) +
    labs(title = paste0("Correlation matrix (", cor_method, ")"), x = NULL, y = NULL) +
    theme_cb() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  with_warning_log(ggsave(file.path(plot_dir, "eda_correlation_matrix.png"), p, width = 7, height = 6, dpi = 150, bg = "white"),
                    "correlation matrix")
  log_msg("")
  log_msg("[note] correlation method: ", cor_method, " (", sum(!normal_flags), "/", length(normal_flags),
          " columns non-normal per Shapiro-Wilk)")
  log_msg("[plot] correlation matrix -> eda_correlation_matrix.png (", length(numeric_cols), " numeric columns)")

  diag(corr_mat) <- 0
  best <- which(abs(corr_mat) == max(abs(corr_mat)), arr.ind = TRUE)[1, ]
  v1 <- rownames(corr_mat)[best[1]]; v2 <- colnames(corr_mat)[best[2]]
  log_msg("[note] strongest pairwise correlation: ", v1, " vs ", v2, " (r=", round(corr_mat[best[1], best[2]], 3), ")")
}

if (length(stats_rows) > 0) {
  stats_df <- dplyr::bind_rows(stats_rows)
  write_csv(stats_df, file.path(output_dir, "column_stats.csv"))
  log_msg("Stats written -> ", file.path(output_dir, "column_stats.csv"))
}

writeLines(log_lines, log_path)
log_msg("")
log_msg("Log written -> ", log_path)
