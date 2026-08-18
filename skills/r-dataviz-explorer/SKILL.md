---
name: r-dataviz-explorer
description: Use when given a CSV or Excel file and asked to explore, visualize, or run statistics on it in R — profiles every column, decides appropriate ggplot2 chart types and statistical tests per column, iteratively writes and runs R scripts while checking their own output, and produces final colorblind-safe tidyverse/ggplot2 figures. Technology-specific to R (tidyverse/ggplot2), not Python.
license: MIT license
metadata:
    skill-author: user
---

# R Data Visualization Explorer

## Overview

Turns a raw CSV/Excel file into publication-quality, colorblind-safe R visualizations without the user having to specify chart types up front. The skill profiles each column, decides what plot(s) and statistical test(s) fit its data type, writes and runs R scripts to explore every column, **reads its own script's output/log and fixes what's wrong before moving on**, then produces a small set of polished final figures.

**REQUIRED BACKGROUND:** None beyond R/tidyverse familiarity. For Python data visualization use `matplotlib`/`seaborn`/`scientific-visualization` instead — this skill is R-specific.

## When to Use

- User provides a `.csv`, `.xlsx`, or `.xls` file and asks to "explore," "visualize," "plot," or "analyze" it in R
- User wants exploratory data analysis (EDA) plus appropriate statistical tests per variable
- User wants final, presentation-ready ggplot2 figures that are safe for colorblind viewers
- Do NOT use for Python plotting (see matplotlib/seaborn), or when the user already specified exact chart types and just wants the ggplot2 code for one plot (skip straight to `references/plot_gallery.md` for that)

## Workflow

```
1. PROFILE   -> Rscript scripts/01_profile_data.R <file> <output_dir>
               Deduces column types/roles, missingness, cardinality.
               Prints a suggested plot + stat test per column. Also writes
               session_info.txt (R/package versions) to <output_dir>.
2. PLAN      -> Read the profile. Cross-check unusual columns against
               references/column_to_plot_guide.md. Decide the grouping
               column (if any) and which relationships matter.
3. EXPLORE   -> Rscript scripts/02_explore_columns.R <file> <output_dir> scripts/cb_theme.R
               One diagnostic plot per column (including a count-over-time
               line for datetime columns) + correlation matrix (Pearson or
               Spearman, chosen by normality) if >=2 numeric columns. Routes
               each continuous-by-group comparison to Welch's t/Mann-Whitney
               (2 groups) or ANOVA+Tukey/Kruskal-Wallis+Dunn (3+ groups)
               based on per-group Shapiro-Wilk + Levene's test, and runs
               chi-square (goodness-of-fit and independence, or Fisher's
               exact below n=5/cell) on categorical columns. Writes
               exploration_log.txt (ggplot warnings included) and
               column_stats.csv (machine-readable test results step 5 ranks
               on).
4. REASSESS  -> Open exploration_log.txt and the PNGs it produced. Look for:
               - a numeric column with <=2-3 distinct values plotted as a
                 density curve instead of a bar chart (misleading)
               - a categorical_high column truncated to top-15 that hid
                 the category the user actually cares about
               - a Shapiro-Wilk/Kruskal-Wallis result that contradicts the
                 test the script chose (re-route to the non-parametric branch)
               If something's wrong, EDIT the script and re-run step 3.
               Do not silently accept a plot that looks wrong.
5. FINALIZE  -> Rscript scripts/03_final_plots.R <file> <output_dir> <group_col> scripts/cb_theme.R
               Curated 3-4 panel set: grouped distribution for the variable
               ranked most-separating in column_stats.csv, strongest
               correlation scatter (with within-group r/rho called out, so
               a Simpson's-paradox pairing doesn't go unnoticed), correlation
               heatmap (one triangle, diagonal dropped), group counts —
               styled with the colorblind-safe theme, saved at 300 DPI.
6. VERIFY    -> Rscript scripts/04_review_checks.R <file> <output_dir>
               Mechanical version of step 4's read-the-log-and-open-the-PNGs
               check: confirms every profiled column shows up in the log,
               flags high missingness and near-zero-variance columns, checks
               each column's log line matches its role, and flags any final/
               PNG small enough to be blank. Doesn't replace opening the
               plots — it catches what's checkable in code so step 4 can
               focus on judgment calls.
```

Steps 3-4 are a loop, not a straight line — re-run after every fix until the log and plots make sense. This mirrors what happened building this skill: the first pass plotted mtcars's binary `vs`/`am` columns as density curves, which was wrong and got caught by reading the log and looking at the plots (see `examples/mtcars_walkthrough.md`).

## Quick Reference: column type -> plot -> test

| Column looks like | Plot | Test |
|---|---|---|
| Continuous number, many unique values | Histogram + density | Shapiro-Wilk normality |
| Continuous number, split by 2 groups | Boxplot + jitter | Welch's t-test (normal + equal var) / Mann-Whitney (else) |
| Continuous number, split by 3+ groups | Boxplot + jitter | ANOVA + Tukey HSD (normal + equal var) / Kruskal-Wallis + Dunn (else) |
| Integer with <=10 levels (e.g. counts, Likert) | Bar chart of counts, natural order | Kruskal-Wallis/ANOVA if grouped (not chi-square — it's ordinal, not nominal) |
| 0/1 or yes/no flag | Bar chart of counts (not histogram!) | Chi-square / Fisher's exact vs. another category |
| Text/factor, <=8 levels | Bar chart, ordered by frequency | Chi-square goodness-of-fit (vs. uniform) / independence (vs. another category) |
| Text/factor, >8 levels | Bar chart of top 15 + "other" | Same, on top-N |
| Date/POSIXct | Line/count-over-time | — |
| 2+ numeric columns together | Correlation heatmap (one triangle) + scatter of top pair | Pearson (normal) / Spearman (non-normal), decided from Shapiro-Wilk |
| Unique-per-row (ID/name) | Skip — not informative to plot | — |

Full decision logic (including when to override the default): `references/column_to_plot_guide.md`. Full chart-type catalog organized by purpose (distribution/correlation/ranking/part-of-whole/evolution): `references/plot_gallery.md`, curated from the [R Graph Gallery](https://r-graph-gallery.com/ggplot2-package.html).

## Colorblind-Safe Styling

Source `scripts/cb_theme.R` and use its helpers instead of ggplot2 defaults:

```r
source("cb_theme.R")

ggplot(df, aes(x = group, y = value, fill = group)) +
  geom_boxplot() +
  scale_fill_cb_d() +        # Okabe-Ito qualitative palette (<=8 categories)
  theme_cb()                 # clean theme_bw variant, top legend, bold titles

# continuous fill/color -> scale_fill_cb_c() / scale_color_cb_c() (viridis)
# correlation/diverging  -> scale_fill_gradient2(low="#0072B2", high="#D55E00", midpoint=0)
```

Full palette hex codes and rules (why not red/green, viridis over jet, redundant shape+color encoding): `references/colorblind_palettes.md`.

## Resources

- `scripts/01_profile_data.R` — column profiler (type/role/missingness/cardinality + suggested plot & test), writes `session_info.txt`
- `scripts/02_explore_columns.R` — per-column diagnostic plots + routed stat tests + `exploration_log.txt` + `column_stats.csv`
- `scripts/03_final_plots.R` — curated final colorblind-safe figure set with a combined summary panel
- `scripts/04_review_checks.R` — mechanical log-completeness/missingness/variance/blank-PNG checks, writes `review_checklist.txt`
- `scripts/cb_theme.R` — `theme_cb()`, `scale_*_cb_d()`/`scale_*_cb_c()`, `save_cb_plot()`
- `references/column_to_plot_guide.md` — full classification + plot + test decision logic
- `references/plot_gallery.md` — ggplot2 chart catalog organized by purpose
- `references/colorblind_palettes.md` — Okabe-Ito/viridis palettes and accessibility rules
- `examples/iris_walkthrough.md` — worked example: 4 continuous + 1 categorical column
- `examples/mtcars_walkthrough.md` — worked example: 11 numeric columns, includes the self-correction step

`01`, `03`, and `04` require `readr`, `readxl`, `dplyr` (plus `purrr`/`tibble` for `01`, `forcats`/`ggplot2`/`patchwork` for `03`). `02` additionally requires `car` (Levene's test) and `rstatix` (Dunn's post-hoc test) on top of `ggplot2`/`forcats` — install with `install.packages(c("car", "rstatix"))` if missing; each script checks for its own required packages up front and stops with an explicit list rather than failing inside a bare `library()` call. Verified end-to-end against R 4.1.2 / ggplot2 3.5.1 / patchwork 1.1.2 and separately against R 4.3.3 / ggplot2 3.4.4 / patchwork 1.2.0 (where the combined summary panel renders directly, without the `tryCatch` fallback below) using the iris and mtcars datasets.

## Common Mistakes

- **Histogram/density on a low-cardinality numeric column.** A 0/1 flag or a 3-level count plotted with `geom_density()` produces a misleading multi-modal blob. Route anything with `n_unique <= 10` and integer-valued to a bar chart of counts instead (see role `discrete_numeric` in the profiler).
- **Trusting `column_profile.csv` blindly.** The profiler is a first pass, not ground truth — a numeric column that's really a categorical code, or a `categorical_high` column better served by collapsing categories, needs a human/agent judgment call (see "Common misclassifications" in `column_to_plot_guide.md`).
- **`patchwork::wrap_plots()` failing with `'==' only defined for equally-sized data frames`.** This is a known `patchwork` (<1.2.0) + `ggplot2` (>=3.5) guide-collection incompatibility, not a bug in the plotting code. `scripts/03_final_plots.R` already wraps the combine step in `tryCatch` (and deletes the blank PNG `ggsave()` leaves behind on failure) so individual panels still save; if you hit this, either upgrade `patchwork` or skip the combined summary image.
- **A file existing doesn't mean the plot is correct.** `ggsave()` opens its device before some errors fire, so a failed render can still leave a 0-content or blank file at the target path. A directory listing is not verification — open the PNG (or check pixel content) before reporting success.
- **Red/green diverging color scales.** Collide under the most common forms of color blindness. Always use the blue/vermillion diverging scale in `cb_theme.R`, never `scale_fill_gradient2()`'s default red-blue or a raw `RdYlGn` palette.
- **Pie charts for part-of-whole data.** Use an ordered bar chart (see `plot_gallery.md`) — angle judgments are measurably less accurate than length judgments.
- **Non-ASCII characters in plot text.** A Greek letter (e.g. `ρ` for Spearman's rho) in a `labs()`/`subtitle` string can silently render as a missing-glyph placeholder (boxes, or two dots) depending on the PNG device's default font, even when the R string itself is correct. `scripts/03_final_plots.R` writes "Spearman rho" rather than "Spearman ρ" for this reason — caught by opening the actual PNG, not by reading the code.
