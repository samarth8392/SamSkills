# Column Type → Plot & Stat Test Decision Guide

This is the logic `scripts/01_profile_data.R` encodes automatically. Use this table when reasoning about a column by hand, or when extending the script to a role it doesn't classify well.

## Step 1: classify each column

| Signal | Role |
|---|---|
| `n_unique == 1` | `constant` — zero variance, skip entirely |
| `n_unique == nrow(df)` | `identifier` — unique per row (ID, name, row key), skip plotting |
| Numeric, `n_unique <= 2` | Binary flag — treat as **categorical**, not continuous (a density curve over 2 values is misleading) |
| Numeric, `n_unique <= 10` and all integers | `discrete_numeric` — low-cardinality count/ordinal (e.g. number of cylinders); plot as a bar chart of counts, not a histogram |
| Numeric, otherwise | `continuous` |
| Character/factor/logical, `n_unique <= 8` | `categorical_low` |
| Character/factor/logical, `n_unique > 8` | `categorical_high` — plot top-N + "other", or reconsider whether it should be grouped/binned first |
| `Date`/`POSIXct` | `datetime` |

## Step 2: pick a plot per role

| Role | Univariate plot | Bivariate plot (vs. a `categorical_low`/binary grouping column) |
|---|---|---|
| `continuous` | Histogram + density (`plot_gallery.md` → Distribution) | Boxplot or violin, grouped |
| `discrete_numeric` | Bar chart of value counts, **natural numeric order** (it's ordinal — frequency-ordering a cylinder count or a Likert score destroys the order that makes it readable) | Grouped bar / faceted count |
| `categorical_low` | Bar chart of counts, ordered by frequency (nominal — no natural order to preserve) | Stacked/grouped bar (contingency) |
| `categorical_high` | Bar chart of top 15 + "other" bucket | Same, top-N only |
| `datetime` | Line/count-over-time | Faceted line per group |

Once ≥2 `continuous`/`discrete_numeric` columns exist, always add a **correlation matrix** (`geom_tile`) and a scatterplot of the most-correlated pair — this is the single highest-value chart for a new tabular dataset and costs one function call.

## Step 3: pick a stat test per role

| Comparison | Test | R |
|---|---|---|
| One continuous variable, is it normal? | Shapiro-Wilk (n ≤ 5000) | `shapiro.test(x)` |
| Continuous across 2 groups, normal + equal variance | Welch's t-test (default; robust to unequal variance) | `t.test(x ~ group)` |
| Continuous across 2 groups, non-normal | Mann-Whitney U | `wilcox.test(x ~ group)` |
| Continuous across 3+ groups, normal | One-way ANOVA + Tukey HSD post-hoc | `aov(x ~ group)`, `TukeyHSD()` |
| Continuous across 3+ groups, non-normal | Kruskal-Wallis + Dunn post-hoc | `kruskal.test(x ~ group)`, `rstatix::dunn_test()` |
| Two continuous variables | Pearson (normal) or Spearman (non-normal/ordinal) correlation | `cor.test(x, y, method = ...)` |
| Two categorical variables | Chi-square test of independence (or Fisher's exact if any expected cell < 5) | `chisq.test(table(x, y))` |
| One categorical vs. a uniform expectation | Chi-square goodness-of-fit | `chisq.test(table(x))` |

**Default to the non-parametric test when in doubt.** Run Shapiro-Wilk first (within each group, not just pooled — a column can be non-normal pooled but normal per group, or the reverse); only use the parametric test (t-test/ANOVA/Pearson) when every group passes (p > .05) and `car::leveneTest()` also passes for equal variance. This is what `scripts/02_explore_columns.R` does automatically for every continuous-by-group pair, including the post-hoc test (`TukeyHSD()` after ANOVA, `rstatix::dunn_test()` after Kruskal-Wallis) and the correlation-matrix Pearson/Spearman choice — all logged to `exploration_log.txt` and `column_stats.csv`.

## Common misclassifications to catch on review

- A numeric column that's really a categorical code (e.g. `1`/`2`/`3` for "region") will be classified `discrete_numeric` — correct for plotting (bar, not histogram) but re-check whether it should be releveled with meaningful labels before the final plots.
- A `categorical_high` column is often an over-granular version of a `categorical_low` one (e.g. 50 US states vs. 4 census regions) — consider whether the analysis question is better served by collapsing categories before plotting, rather than truncating to top-N.
- `identifier` columns are sometimes actually useful as a facet/label (e.g. sample ID in a small n paired design) — the "skip" rule is a default, not an absolute.
