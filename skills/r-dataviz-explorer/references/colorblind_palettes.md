# Colorblind-Safe Palettes for ggplot2

`scripts/cb_theme.R` implements the qualitative palette and continuous scales below — source it and use `scale_color_cb_d()`/`scale_fill_cb_d()`/`scale_color_cb_c()`/`scale_fill_cb_c()` instead of ggplot2 defaults.

## Qualitative (discrete categories) — Okabe-Ito

The Okabe-Ito palette is distinguishable under protanopia, deuteranopia, and tritanopia, and still reads correctly in grayscale print.

| Color | Hex | Use |
|---|---|---|
| Blue | `#0072B2` | Primary/first category |
| Orange | `#E69F00` | Second category |
| Green | `#009E73` | Third category |
| Vermillion | `#D55E00` | Fourth category / "highlight" or contrast color |
| Reddish purple | `#CC79A7` | Fifth category |
| Sky blue | `#56B4E9` | Sixth category |
| Yellow | `#F0E442` | Seventh category — use sparingly, low contrast on white |
| Grey | `#999999` | Eighth category / "other" bucket |

```r
scale_color_manual(values = cb_palette_qualitative)  # up to 8 categories
```

Beyond 8 categories, stop using a qualitative palette — facet instead of coloring, or collapse rare categories into "other" (see `column_to_plot_guide.md`).

## Sequential (ordered/continuous, one direction)

Use **viridis** — perceptually uniform in lightness, so it reads correctly in grayscale and under all three common color-vision deficiencies.

```r
scale_color_viridis_c()   # continuous variable, color
scale_fill_viridis_c()    # continuous variable, fill (e.g. heatmap)
scale_fill_viridis_d()    # ordered discrete variable
```

Avoid the default ggplot2 blue-gradient (`scale_fill_gradient`) and rainbow/jet-style palettes — they are not perceptually uniform and create false visual boundaries.

## Diverging (values centered on a meaningful midpoint, e.g. correlation, fold-change)

```r
scale_fill_gradient2(low = "#0072B2", mid = "white", high = "#D55E00", midpoint = 0)
```

Blue–white–vermillion reads correctly for all common color-vision deficiencies (unlike red-green diverging scales, which collide under deuteranopia/protanopia — the most common forms). This is what `scripts/02_explore_columns.R` and `scripts/03_final_plots.R` use for correlation matrices.

## General rules

1. **Never rely on red vs. green alone** to distinguish two categories or two ends of a scale — this is the single most common colorblind-accessibility mistake in default plotting software.
2. **Don't encode a variable in color alone** if it's also feasible to encode it in position, shape, or a text label — redundant encoding (e.g. `shape` + `color` for the same grouping variable) survives both grayscale printing and color blindness.
3. **Check contrast against white background**: yellow (`#F0E442`) and light colors need a dark outline (`color = "black"`, `linewidth = 0.2`) on points/bars to stay legible.
4. **Preview in grayscale** before finalizing: `scales::show_col(desaturate(cb_palette_qualitative))` (requires the `colorspace` package) — if two categories collapse to the same gray, don't rely on adjacency in a legend to disambiguate them; add direct labels instead.
