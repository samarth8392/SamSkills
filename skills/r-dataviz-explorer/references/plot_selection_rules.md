# Plot Selection Rules

Reference: [r-graph-gallery.com](https://r-graph-gallery.com/) and the
bundled `ggplot2.pdf` manual.

## Column-type thresholds

| Constant | Value |
|---|---|
| `CATEGORICAL_CARDINALITY_RATIO` | 0.05 |
| `CATEGORICAL_MAX_UNIQUE` | 15 |
| `IDENTIFIER_UNIQUE_RATIO` | 0.9 |
| `NUMERIC_DISCRETE_MAX_UNIQUE` | 30 |

## Column-type detection order

1. If the column is an ordered factor -> `ordinal`.
2. If the column is `Date`/`POSIXct`, or is character with a name matching
   `/date|time/i` that parses cleanly with `lubridate` -> `datetime`.
3. If exactly 2 unique non-NA values -> `binary`.
4. If numeric:
   - low cardinality (`unique/n < 0.05` and `unique <= 15`) -> `categorical`
   - else all values are whole numbers and `unique <= 30` -> `numeric_discrete`
   - else -> `numeric_continuous`
5. If character/factor:
   - `unique/n > 0.9` -> `identifier_text`
   - else -> `categorical`

## Plot type per column type

| Column type | Univariate plot(s) |
|---|---|
| `numeric_continuous` | histogram + density overlay, boxplot |
| `numeric_discrete` | histogram + density overlay, boxplot (noted as count/discrete data) |
| `categorical` | bar chart ordered by frequency (lollipop if > 12 levels) |
| `binary` | bar chart |
| `ordinal` | bar chart ordered by factor level |
| `datetime` | timeline / value-over-time line plot |
| `identifier_text` | none (reported in overview table only) |

## Plot type per column pair

| Pair | Plot |
|---|---|
| numeric x numeric | scatter plot + `geom_smooth`; correlation heatmap if <= 8 numeric columns total |
| numeric x categorical | grouped boxplot/violin |
| categorical x categorical | grouped/stacked bar chart |

## Colorblind-safe palettes

- Continuous scales: `viridis::scale_color_viridis()` /
  `scale_fill_viridis()`.
- Discrete scales: Okabe-Ito 8-color palette:
  `c("#E69F00", "#56B4E9", "#009E73", "#F0E442", "#0072B2", "#D55E00", "#CC79A7", "#000000")`.
- Shared theme: `theme_dataviz_explorer()` (see `scripts/plot_theme.R`),
  based on `ggplot2::theme_minimal()`.
