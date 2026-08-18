suppressPackageStartupMessages({
  library(ggplot2)
})

cb_palette_qualitative <- c(
  "#0072B2", "#E69F00", "#009E73", "#D55E00",
  "#CC79A7", "#56B4E9", "#F0E442", "#999999"
)

theme_cb <- function(base_size = 13, base_family = "") {
  theme_bw(base_size = base_size, base_family = base_family) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(color = "grey90", linewidth = 0.3),
      plot.title = element_text(face = "bold", size = rel(1.05)),
      plot.subtitle = element_text(color = "grey30", size = rel(0.9)),
      legend.position = "top",
      legend.title = element_text(face = "bold", size = rel(0.85)),
      strip.background = element_rect(fill = "grey20", color = NA),
      strip.text = element_text(color = "white", face = "bold")
    )
}

scale_color_cb_d <- function(...) scale_color_manual(values = cb_palette_qualitative, ...)
scale_fill_cb_d  <- function(...) scale_fill_manual(values = cb_palette_qualitative, ...)
scale_color_cb_c <- function(...) scale_color_viridis_c(...)
scale_fill_cb_c  <- function(...) scale_fill_viridis_c(...)

save_cb_plot <- function(plot, path, width = 7, height = 5, dpi = 300) {
  ggsave(path, plot = plot, width = width, height = height, dpi = dpi, bg = "white")
  message("Saved: ", path)
}
