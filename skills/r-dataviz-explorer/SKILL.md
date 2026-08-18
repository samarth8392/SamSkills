---
name: r-dataviz-explorer
description: Use when given a CSV or Excel file and asked to explore, visualize, or run statistics on it in R — profiles every column, decides appropriate ggplot2 chart types and statistical tests per column, iteratively writes and runs R scripts while checking their own output, produces final colorblind-safe tidyverse/ggplot2 figures, and assembles everything into a self-contained HTML report. Technology-specific to R (tidyverse/ggplot2), not Python.
license: MIT license
metadata:
    skill-author: user
---

# R Data Visualization Explorer

## Overview

Turns a raw CSV/Excel file into publication-quality, colorblind-safe R visualizations without the user having to specify chart types up front. The skill profiles each column, decides what plot(s) and statistical test(s) fit its data type, writes and runs R scripts to explore every column, **reads its own script's output/log and fixes what's wrong before moving on**, then produces a small set of polished final figures and a single self-contained HTML report bundling every plot, stat result, and finding.

**REQUIRED BACKGROUND:** None beyond R/tidyverse familiarity. For Python data visualization use `matplotlib`/`seaborn`/`scientific-visualization` instead — this skill is R-specific.

## When to Use

- User provides a `.csv`, `.xlsx`, or `.xls` file and asks to "explore," "visualize," "plot," or "analyze" it in R
- User wants exploratory data analysis (EDA) plus appropriate statistical tests per variable
- User wants final, presentation-ready ggplot2 figures that are safe for colorblind viewers
- Do NOT use for Python plotting (see matplotlib/seaborn), or when the user already specified exact chart types and just wants the ggplot2 code for one plot (skip straight to `references/plot_gallery.md` for that)

## Workflow

Don't assume R and its packages are already set up in this environment — check first, especially in a
fresh container or a machine this skill hasn't run on before. `which Rscript` (or `Rscript --version`)
tells you if R itself exists:

- **R not found at all:** this is a language runtime, not a package — installing it is a bigger, more
  consequential action (a real download, needs a system package manager or admin rights, may need
  compiler toolchains for building packages from source) than adding an R package. Tell the user R needs
  to be installed rather than silently doing it, and give them the right command for their platform:
  macOS → `brew install r`; Debian/Ubuntu → `sudo apt install r-base`; other → https://cran.r-project.org.
- **R found:** run `Rscript scripts/00_check_setup.R` before step 1. It checks every package all five
  workflow scripts need, combined, in one shot, and either confirms you're ready or prints the exact
  `install.packages(...)` command for whatever's missing. Installing an R package (unlike installing R
  itself) is the low-risk, ordinary kind of setup step — fine to run directly, the same way you'd run
  `npm install` or `pip install` for a project that needs it.

```
0. SETUP     -> Rscript scripts/00_check_setup.R
               Confirms R + all required packages across 01-05 are present in
               one combined check (see above) before starting the workflow.
1. PROFILE   -> Rscript scripts/01_profile_data.R <file> <output_dir>
               Deduces column types/roles, missingness, cardinality.
               Prints a suggested plot + stat test per column. Also writes
               session_info.txt (R/package versions) to <output_dir>.
2. PLAN      -> Read the profile. Cross-check unusual columns against
               references/column_to_plot_guide.md. Decide the grouping
               column (if any) and which relationships matter.
3. EXPLORE   -> Rscript scripts/02_explore_columns.R <file> <output_dir> scripts/cb_theme.R
               One diagnostic plot per column (including a count-over-time
               line for datetime columns, auto-binned to week/month once
               daily resolution would just be noise) + correlation matrix
               (Pearson or Spearman, chosen by normality) if >=2 numeric
               columns. Routes
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
               Also writes final_plots_log.txt — ggsave() warnings (e.g. NAs
               dropped from a boxplot) fire at render time same as step 3's,
               so they're captured the same way rather than only hitting
               stderr.
6. VERIFY    -> Rscript scripts/04_review_checks.R <file> <output_dir>
               Mechanical version of step 4's read-the-log-and-open-the-PNGs
               check: confirms every profiled column shows up in the log,
               flags high missingness and near-zero-variance columns, checks
               each column's log line matches its role (specifically: a
               continuous column whose line carries the categorical branch's
               "unique values" text — the "unique per column, not by naive
               is.numeric()" contamination this skill exists to prevent),
               flags any final/ PNG small enough to be blank, and surfaces
               any warning final_plots_log.txt captured (a final figure may
               be quietly missing rows). Doesn't replace opening the plots —
               it catches what's checkable in code so step 4 can focus on
               judgment calls.
7. REPORT    -> Write a short markdown write-up (key findings, caveats,
               suggested follow-ups — the same judgment call as step 4,
               in prose) to a file, e.g. <output_dir>/narrative.md. Then:
               Rscript scripts/05_generate_report.R <file> <output_dir> [narrative.md]
               Assembles column_profile.csv, column_stats.csv,
               exploration_log.txt, review_checklist.txt, and every PNG in
               exploration/ and final/ into <output_dir>/report.md (relative
               image links, so it stays readable/diffable next to the PNGs
               it references), then renders that same content as
               <output_dir>/report.html — a single self-contained file
               (images base64-embedded, no external assets, no pandoc/
               rmarkdown dependency) that still opens correctly if the
               output directory is copied or emailed elsewhere. The
               narrative argument is optional but is the only place actual
               interpretation (which columns mattered, what the plots mean)
               enters the report — everything else is mechanically derived
               from the other scripts' own output files, exactly like step 6.
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

- `scripts/00_check_setup.R` — combined dependency check across all five workflow scripts; run this first
- `scripts/01_profile_data.R` — column profiler (type/role/missingness/cardinality + suggested plot & test), writes `session_info.txt`
- `scripts/02_explore_columns.R` — per-column diagnostic plots + routed stat tests + `exploration_log.txt` + `column_stats.csv`
- `scripts/03_final_plots.R` — curated final colorblind-safe figure set with a combined summary panel + `final_plots_log.txt`
- `scripts/04_review_checks.R` — mechanical log-completeness/missingness/variance/blank-PNG/dropped-row checks, writes `review_checklist.txt`
- `scripts/05_generate_report.R` — assembles every artifact above (+ an optional agent-written narrative) into `report.md` and a self-contained `report.html`
- `scripts/cb_theme.R` — `theme_cb()`, `scale_*_cb_d()`/`scale_*_cb_c()`, `save_cb_plot()`
- `references/column_to_plot_guide.md` — full classification + plot + test decision logic
- `references/plot_gallery.md` — ggplot2 chart catalog organized by purpose
- `references/colorblind_palettes.md` — Okabe-Ito/viridis palettes and accessibility rules
- `examples/iris_walkthrough.md` — worked example: 4 continuous + 1 categorical column
- `examples/mtcars_walkthrough.md` — worked example: 11 numeric columns, includes the self-correction step

`01`, `03`, and `04` require `readr`, `readxl`, `dplyr` (plus `purrr`/`tibble` for `01`, `forcats`/`ggplot2`/`patchwork` for `03`). `02` additionally requires `car` (Levene's test) and `rstatix` (Dunn's post-hoc test) on top of `ggplot2`/`forcats` — install with `install.packages(c("car", "rstatix"))` if missing; each script checks for its own required packages up front and stops with an explicit list rather than failing inside a bare `library()` call. `05` needs only `readr`/`readxl` (already covered by `00_check_setup.R`'s combined list) — it embeds images with a small hand-rolled base64 encoder rather than adding a package (e.g. `base64enc`) just for that; it also doesn't care whether `final/*.png` came from `03_final_plots.R` itself or a hand-written replacement (see "Common Mistakes" below) — it just picks up whatever matches `final_panel_*.png`. Verified end-to-end against R 4.1.2 / ggplot2 3.5.1 / patchwork 1.1.2 and separately against R 4.3.3 / ggplot2 3.4.4 / patchwork 1.2.0 / car 3.1.2 / rstatix 0.7.2 (where the combined summary panel renders directly, without the `tryCatch` fallback below) using the iris, mtcars, and `.xlsx` inputs, plus degenerate inputs (1 column, 2 rows, tiny/uneven groups). `05` verified separately against a 10,000-row, 12-column real-world CSV with no continuous columns and no grouping column at all.

## Common Mistakes

- **Histogram/density on a low-cardinality numeric column.** A 0/1 flag or a 3-level count plotted with `geom_density()` produces a misleading multi-modal blob. Route anything with `n_unique <= 10` and integer-valued to a bar chart of counts instead (see role `discrete_numeric` in the profiler).
- **Trusting `column_profile.csv` blindly.** The profiler is a first pass, not ground truth — a numeric column that's really a categorical code, or a `categorical_high` column better served by collapsing categories, needs a human/agent judgment call (see "Common misclassifications" in `column_to_plot_guide.md`).
- **`patchwork::wrap_plots()` failing with `'==' only defined for equally-sized data frames`.** This is a known `patchwork` (<1.2.0) + `ggplot2` (>=3.5) guide-collection incompatibility, not a bug in the plotting code. `scripts/03_final_plots.R` already wraps the combine step in `tryCatch` (and deletes the blank PNG `ggsave()` leaves behind on failure) so individual panels still save; if you hit this, either upgrade `patchwork` or skip the combined summary image.
- **A file existing doesn't mean the plot is correct.** `ggsave()` opens its device before some errors fire, so a failed render can still leave a 0-content or blank file at the target path. A directory listing is not verification — open the PNG (or check pixel content) before reporting success.
- **Red/green diverging color scales.** Collide under the most common forms of color blindness. Always use the blue/vermillion diverging scale in `cb_theme.R`, never `scale_fill_gradient2()`'s default red-blue or a raw `RdYlGn` palette.
- **Pie charts for part-of-whole data.** Use an ordered bar chart (see `plot_gallery.md`) — angle judgments are measurably less accurate than length judgments.
- **Non-ASCII characters in plot text.** A Greek letter (e.g. `ρ` for Spearman's rho) or an en/em-dash in a `labs()`/`subtitle` string can silently render as a missing-glyph placeholder (boxes, or garbled dots) depending on the PNG device's default font, even when the R string itself is correct. `scripts/03_final_plots.R` writes "Spearman rho" rather than "Spearman ρ" for this reason — caught by opening the actual PNG, not by reading the code. This has bitten a hand-written replacement for `03_final_plots.R` too (see next entry): stick to plain ASCII (`-`, not `–`/`—`) in any `subtitle`/`labs()` text.
- **`03_final_plots.R` produces 0 panels on a dataset with no continuous columns and no natural grouping column** (e.g. an all-categorical/identifier/datetime customer registry) — its 4 panel types are all built around a numeric-variable-by-group comparison. This isn't a bug to fix in the template; write a small dataset-specific finalize script instead (following `cb_theme.R`'s conventions, saving to `<output_dir>/final/final_panel_N.png`) and skip straight to step 6. `scripts/05_generate_report.R` (step 7) doesn't care which script populated `final/` — it just picks up whatever matches `final_panel_*.png`.
- **Attributing images to columns by scanning log text instead of by filename.** In `scripts/05_generate_report.R`, a grouped-comparison log line like `"Sepal.Length by Species -> eda_Sepal.Length_by_Species.png"` mentions *both* column names, so a naive text search would (wrongly) embed that plot under `Species`'s section too, doubling the report's size for every grouped plot. The script instead matches PNG filenames against `eda_<make.names(col)>.png` / `eda_<make.names(col)>_by_*.png` prefixes — which 02_explore_columns.R's own naming convention makes unambiguous per-column — and only uses log-text matching for the (cheap, harmless-if-duplicated) text bullets.
