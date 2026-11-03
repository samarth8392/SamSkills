# plot_theme.R
# Shared ggplot2 theme and colorblind-safe palettes for r-dataviz-explorer.

suppressPackageStartupMessages({
  library(ggplot2)
  library(viridis)
})

# Okabe-Ito 8-color palette: colorblind-safe, from Okabe & Ito (2008).
okabe_ito_palette <- c(
  "#E69F00", "#56B4E9", "#009E73", "#F0E442",
  "#0072B2", "#D55E00", "#CC79A7", "#000000"
)

#' A clean, minimal theme shared by all r-dataviz-explorer plots.
theme_dataviz_explorer <- function(base_size = 12) {
  ggplot2::theme_minimal(base_size = base_size) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold", size = ggplot2::rel(1.1)),
      plot.subtitle = ggplot2::element_text(color = "grey40"),
      panel.grid.minor = ggplot2::element_blank(),
      legend.position = "bottom",
      strip.text = ggplot2::element_text(face = "bold")
    )
}

# Colorblind-safe palette generator: uses the 8 Okabe-Ito colors directly
# for <= 8 levels, and interpolates between them for more levels (still far
# more distinguishable than ggplot2's default hue wheel at high cardinality).
# Used via discrete_scale() rather than scale_*_manual() because manual
# scales require a fixed-length vector supplied up front and error out
# ("Insufficient values in manual scale") once the data has more levels than
# colors provided -- discrete_scale()'s palette function is instead called
# with the actual number of levels needed at draw time.
okabe_ito_extended_palette <- function(n) {
  if (n <= length(okabe_ito_palette)) {
    okabe_ito_palette[seq_len(n)]
  } else {
    grDevices::colorRampPalette(okabe_ito_palette)(n)
  }
}

scale_fill_dataviz_discrete <- function(...) {
  ggplot2::discrete_scale(aesthetics = "fill", palette = okabe_ito_extended_palette, ...)
}

scale_color_dataviz_discrete <- function(...) {
  ggplot2::discrete_scale(aesthetics = "colour", palette = okabe_ito_extended_palette, ...)
}

scale_fill_dataviz_continuous <- function(...) {
  viridis::scale_fill_viridis(...)
}

scale_color_dataviz_continuous <- function(...) {
  viridis::scale_color_viridis(...)
}
