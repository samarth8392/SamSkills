# ggplot2 Chart Gallery (by purpose)

Curated from the [R Graph Gallery](https://r-graph-gallery.com/ggplot2-package.html) taxonomy and organized by what question a chart answers, not by geom name. When [column_to_plot_guide.md](column_to_plot_guide.md) says "use a distribution plot," come here to pick which one.

## Distribution — shape/spread of one variable

| Chart | Code | When to use |
|---|---|---|
| Histogram | `geom_histogram(bins = 30)` | Default for one continuous variable, n > ~30 |
| Density plot | `geom_density(fill = ..., alpha = 0.5)` | Smoother alternative to histogram; good for overlaying groups |
| Histogram + density overlay | `geom_histogram(aes(y = after_stat(density))) + geom_density()` | Show both binned counts and smooth shape at once |
| Boxplot | `geom_boxplot()` | Compare distribution summary (median/IQR/outliers) across groups |
| Violin plot | `geom_violin()` | Like boxplot but shows full shape; best with n > ~15 per group |
| Boxplot + jitter | `geom_boxplot(outlier.shape = NA) + geom_jitter(width = 0.15, alpha = 0.4)` | Boxplot summary without hiding the raw points |
| Ridgeline plot | `ggridges::geom_density_ridges()` | Many groups' distributions stacked vertically |
| Rug plot | `geom_rug()` | Add as a layer under a scatter/histogram to show exact data points on an axis |
| ECDF | `stat_ecdf()` | Compare distributions without choosing a bin width |

## Correlation — relationship between two continuous variables

| Chart | Code | When to use |
|---|---|---|
| Scatterplot | `geom_point(alpha = 0.7)` | Default for two continuous variables |
| Scatter + trend line | `geom_point() + geom_smooth(method = "lm")` | Show linear relationship + confidence band |
| Scatter + LOESS | `geom_smooth(method = "loess")` | Non-linear trend, exploratory |
| Hexbin | `geom_hex(bins = 30)` | Scatter with too many overlapping points (n > ~2000) |
| 2D density | `geom_density_2d()` or `geom_density_2d_filled()` | Where points cluster, for large n |
| Correlation heatmap | `geom_tile(aes(fill = correlation)) + geom_text(aes(label = ...))` | Many numeric variables at once (see `scripts/02_explore_columns.R`) |
| Bubble chart | `geom_point(aes(size = z))` | Add a third continuous variable via point size |

## Ranking / Comparison — compare discrete categories

| Chart | Code | When to use |
|---|---|---|
| Bar chart (ordered) | `geom_col() + coord_flip()` after `fct_reorder(cat, value)` | Default for comparing counts/values across categories; always order by value, never leave alphabetical |
| Grouped bar | `geom_col(position = "dodge")` | Compare two categorical dimensions at once |
| Lollipop chart | `geom_segment(aes(xend = cat, y = 0, yend = value)) + geom_point()` | Same use as bar chart, lighter ink, good for many categories |
| Cleveland dot plot | `geom_point()` on a reordered categorical axis | Compare a single value across many categories without bar clutter |
| Diverging bar | `geom_col()` with values centered on 0 | Show positive/negative deviation from a baseline per category |

## Part-of-whole — composition

| Chart | Code | When to use |
|---|---|---|
| Stacked bar | `geom_col(position = "stack")` | Composition within categories; use `position = "fill"` to normalize to 100% |
| Treemap | `treemapify::geom_treemap()` | Hierarchical part-of-whole, many categories |
| **Avoid pie charts** | — | Angle judgments are hard; a sorted bar chart communicates the same data more accurately |

## Evolution — trends over time or an ordered sequence

| Chart | Code | When to use |
|---|---|---|
| Line plot | `geom_line()` | Default for a continuous variable over time/order |
| Line + ribbon (CI/error band) | `geom_line() + geom_ribbon(aes(ymin, ymax), alpha = 0.2)` | Show uncertainty around a trend |
| Area chart | `geom_area()` | Emphasize magnitude/cumulative volume over time |
| Connected scatterplot | `geom_point() + geom_path()` | Small number of ordered observations where both value and sequence matter |
| Slope chart | `geom_line(aes(group = id))` between two time points | Before/after comparison per subject |

## Multivariate / small multiples

| Chart | Code | When to use |
|---|---|---|
| Faceted plot | `facet_wrap(~ group)` or `facet_grid(rows ~ cols)` | Repeat the same chart per level of a categorical variable instead of overplotting hue |
| Pair plot | `GGally::ggpairs()` | Every pairwise relationship among several numeric variables at once |
| Parallel coordinates | `GGally::ggparcoord()` | Compare many numeric variables per observation |

## General-purpose layers (combine with anything above)

- `geom_hline()` / `geom_vline()` — mark a threshold or reference value
- `geom_text()` / `geom_label()` / `ggrepel::geom_text_repel()` — label specific points without overlap
- `annotate()` — one-off text/rect/segment not tied to data
- `patchwork::wrap_plots()` — combine multiple ggplot objects into one figure (see `scripts/03_final_plots.R`)

## Choosing among close options

- **Histogram vs. density vs. boxplot**: histogram/density show shape (modality, skew); boxplot shows summary stats and is best for comparing many groups side by side.
- **Bar vs. lollipop vs. dot plot**: all rank categories; prefer lollipop/dot plots over full bars when there are more than ~15 categories (less visual weight).
- **Scatter vs. hexbin**: switch to hexbin once points overplot so heavily that density is unreadable (rule of thumb: n > 2000, or a scatter that visually saturates into a solid blob).
- **Line vs. area vs. connected scatter**: line for a trend, area to emphasize magnitude/stacking, connected scatter only when both the value and the visiting order matter and n is small.
