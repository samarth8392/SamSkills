#!/usr/bin/env Rscript
# Usage: Rscript 05_generate_report.R <input.csv|.xlsx> <output_dir> [narrative_md_path]
# Assembles every artifact from steps 01-04 (column_profile.csv, column_stats.csv,
# exploration_log.txt, review_checklist.txt, final_plots_log.txt, and every PNG
# in exploration/ and final/) into report.md, then renders that same content as
# a single self-contained report.html - images base64-embedded inline, no
# external assets, no pandoc/rmarkdown dependency, so the report still opens if
# output_dir is copied or emailed elsewhere. narrative_md_path is an optional
# short markdown file: write the "key findings & suggestions" write-up there
# (the interpretive judgment call from step 4/5 - which columns actually
# mattered, what the plots mean, what to do next - not something this script
# can derive from the CSVs alone) before running this, and it's folded into
# the report verbatim.
required_pkgs <- c("readr", "readxl")
missing_pkgs <- required_pkgs[!vapply(required_pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_pkgs) > 0) {
  stop("Missing required package(s): ", paste(missing_pkgs, collapse = ", "),
       ". Install with: install.packages(c(", paste(sprintf('"%s"', missing_pkgs), collapse = ", "), "))")
}
suppressPackageStartupMessages({
  library(readr)
  library(readxl)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("Usage: Rscript 05_generate_report.R <input.csv|.xlsx> <output_dir> [narrative_md_path]")
input_path <- args[1]
output_dir <- args[2]
narrative_path <- if (length(args) >= 3 && nzchar(args[3])) args[3] else NA

read_any <- function(path) {
  ext <- tolower(tools::file_ext(path))
  if (ext == "csv") read_csv(path, show_col_types = FALSE) else read_excel(path)
}

# --- Read pipeline artifacts (all optional except column_profile.csv) ---
profile_path <- file.path(output_dir, "column_profile.csv")
if (!file.exists(profile_path)) stop("column_profile.csv not found in ", output_dir, " — run 01_profile_data.R first")
profile <- read_csv(profile_path, show_col_types = FALSE)
df <- read_any(input_path)
n_rows <- nrow(df)
n_cols <- nrow(profile)

stats_path <- file.path(output_dir, "column_stats.csv")
col_stats <- if (file.exists(stats_path)) read_csv(stats_path, show_col_types = FALSE) else NULL

log_path <- file.path(output_dir, "exploration_log.txt")
log_lines <- if (file.exists(log_path)) readLines(log_path) else character(0)

final_log_path <- file.path(output_dir, "final_plots_log.txt")
final_log_lines <- if (file.exists(final_log_path)) readLines(final_log_path) else character(0)

checklist_path <- file.path(output_dir, "review_checklist.txt")
checklist_lines <- if (file.exists(checklist_path)) readLines(checklist_path) else character(0)

session_path <- file.path(output_dir, "session_info.txt")
session_lines <- if (file.exists(session_path)) readLines(session_path) else character(0)

explore_dir <- file.path(output_dir, "exploration")
final_dir <- file.path(output_dir, "final")

narrative_lines <- character(0)
if (!is.na(narrative_path)) {
  if (file.exists(narrative_path)) {
    narrative_lines <- readLines(narrative_path)
  } else {
    message("[note] narrative_md_path '", narrative_path, "' not found — skipping narrative section")
  }
}

# --- Small self-contained utilities (no new package deps for this step) ---

# Word-boundary literal match, same trick 04_review_checks.R uses, so a column
# named e.g. "wt" doesn't false-match inside "gearwt".
col_mentioned <- function(col, lines) {
  pattern <- paste0("(^|[^A-Za-z0-9._])", "\\Q", col, "\\E", "([^A-Za-z0-9._]|$)")
  lines[grepl(pattern, lines, perl = TRUE)]
}

slugify <- function(x) {
  s <- tolower(x)
  s <- gsub("[^a-z0-9]+", "-", s)
  gsub("^-+|-+$", "", s)
}

esc_html <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  gsub(">", "&gt;", x, fixed = TRUE)
}

# Deliberately minimal: handles exactly the markdown constructs this script
# itself emits (code spans, links, bold, italic) - not a general CommonMark
# parser, since we control every string that flows through it.
md_inline_html <- function(x) {
  x <- esc_html(x)
  x <- gsub("`([^`]+)`", "<code>\\1</code>", x)
  x <- gsub("\\[([^\\]]+)\\]\\(([^)]+)\\)", '<a href="\\2">\\1</a>', x)
  x <- gsub("\\*\\*([^*]+)\\*\\*", "<strong>\\1</strong>", x)
  gsub("(?<!\\*)\\*([^*]+)\\*(?!\\*)", "<em>\\1</em>", x, perl = TRUE)
}

# Pure-base-R base64 (avoids adding e.g. base64enc just to inline a handful of
# PNGs) so report.html has zero package requirements beyond readr/readxl.
b64_encode_file <- function(path) {
  raw_bytes <- readBin(path, what = "raw", n = file.info(path)$size)
  b64_chars <- c(LETTERS, letters, as.character(0:9), "+", "/")
  n <- length(raw_bytes)
  pad <- (3 - n %% 3) %% 3
  bytes <- c(as.integer(raw_bytes), rep(0L, pad))
  m <- matrix(bytes, nrow = 3)
  c1 <- m[1, ] %/% 4L
  c2 <- bitwAnd(m[1, ], 3L) * 16L + m[2, ] %/% 16L
  c3 <- bitwAnd(m[2, ], 15L) * 4L + m[3, ] %/% 64L
  c4 <- bitwAnd(m[3, ], 63L)
  chars <- b64_chars[as.vector(rbind(c1, c2, c3, c4)) + 1L]
  out <- paste(chars, collapse = "")
  if (pad > 0) substr(out, nchar(out) - pad + 1, nchar(out)) <- paste(rep("=", pad), collapse = "")
  out
}
img_data_uri <- function(path) paste0("data:image/png;base64,", b64_encode_file(path))

fmt_num <- function(x) ifelse(is.na(x), "NA", formatC(x, format = "g", digits = 3))
md_cell <- function(x) gsub("\n", " ", gsub("|", "\\|", as.character(x), fixed = TRUE), fixed = TRUE)

# --- Content blocks: build once, render twice (markdown + html), so the two
# outputs can never drift out of sync with each other. ---
blocks <- list()
add <- function(b) blocks[[length(blocks) + 1]] <<- b
h  <- function(level, text, id = NULL) list(type = paste0("h", level), text = text, id = id)
p  <- function(text) list(type = "p", text = text)
ul <- function(items) list(type = "ul", items = items)
img <- function(path, alt, caption = NULL) list(type = "img", path = path, alt = alt, caption = caption)
tbl <- function(header, rows) list(type = "table", header = header, rows = rows)
kv  <- function(pairs) list(type = "table", header = c("Field", "Value"), rows = pairs)
checklist_block <- function(items, summary_line) list(type = "checklist", items = items, summary = summary_line)

# --- Title ---
add(h(1, paste("Data Exploration Report:", basename(input_path))))
add(p(paste0("*Generated ", format(Sys.time(), "%Y-%m-%d %H:%M %Z"), " by the r-dataviz-explorer skill*")))

# --- Overview ---
group_col_note <- "not determined"
gc_line <- grep("^Grouping column used for split plots:", log_lines, value = TRUE)
if (length(gc_line) == 1) group_col_note <- trimws(sub("^Grouping column used for split plots:", "", gc_line))

skip_lines_all <- grep("^\\[skip\\]", log_lines, value = TRUE)
skipped_cols <- profile$column[vapply(profile$column, function(cn) length(col_mentioned(cn, skip_lines_all)) > 0, logical(1))]
plotted_cols <- setdiff(profile$column, skipped_cols)
n_missing_cols <- sum(profile$pct_missing > 0)

add(h(2, "Overview"))
add(kv(list(
  c("Input file", input_path),
  c("Rows", format(n_rows, big.mark = ",")),
  c("Columns", as.character(n_cols)),
  c("Columns plotted", as.character(length(plotted_cols))),
  c("Columns skipped (identifier/constant/other)", as.character(length(skipped_cols))),
  c("Grouping column", group_col_note),
  c("Columns with missing data", as.character(n_missing_cols)),
  c("Output directory", output_dir)
)))

# --- Contents ---
add(h(2, "Contents"))
toc_items <- c()
if (length(narrative_lines)) toc_items <- c(toc_items, "[Key Findings & Suggestions](#key-findings-suggestions)")
toc_items <- c(toc_items, "[Column Profile](#column-profile)")
if (!is.null(col_stats) && nrow(col_stats) > 0) toc_items <- c(toc_items, "[Statistical Test Results](#statistical-test-results)")
for (cn in plotted_cols) toc_items <- c(toc_items, sprintf("[%s](#%s)", cn, slugify(cn)))
if (file.exists(file.path(explore_dir, "eda_correlation_matrix.png"))) toc_items <- c(toc_items, "[Correlation Matrix](#correlation-matrix)")
toc_items <- c(toc_items, "[Final Curated Figures](#final-curated-figures)")
if (length(checklist_lines)) toc_items <- c(toc_items, "[Review Checklist](#review-checklist)")
toc_items <- c(toc_items, "[Reproducibility](#reproducibility)")
add(ul(toc_items))

# --- Key Findings & Suggestions (agent-authored narrative, folded in verbatim) ---
add(h(2, "Key Findings & Suggestions", id = "key-findings-suggestions"))
if (length(narrative_lines)) {
  # Minimal parser for the agent's own prose: headers become a fixed h4 (this
  # section is always subordinate to the h2 above), "- "/"* " lines become a
  # bullet list, blank lines separate paragraphs - deliberately not a full
  # markdown grammar, just enough for the header/bullet/paragraph prose an
  # agent actually writes after reading the plots.
  para_buf <- c()
  bullet_buf <- c()
  flush_para <- function() {
    if (length(para_buf)) { add(p(paste(para_buf, collapse = " "))); para_buf <<- c() }
  }
  flush_bullets <- function() {
    if (length(bullet_buf)) { add(ul(bullet_buf)); bullet_buf <<- c() }
  }
  for (ln in narrative_lines) {
    if (grepl("^\\s*$", ln)) {
      flush_para(); flush_bullets()
    } else if (grepl("^#+\\s+", ln)) {
      flush_para(); flush_bullets()
      add(h(4, sub("^#+\\s+", "", ln)))
    } else if (grepl("^[-*]\\s+", ln)) {
      flush_para()
      bullet_buf <- c(bullet_buf, sub("^[-*]\\s+", "", ln))
    } else {
      flush_bullets()
      para_buf <- c(para_buf, trimws(ln))
    }
  }
  flush_para(); flush_bullets()
} else {
  add(p("_No narrative summary was provided for this run. Pass a short markdown write-up (key findings, caveats, suggested follow-ups) as the third argument to `05_generate_report.R` to populate this section._"))
}

# --- Column Profile ---
add(h(2, "Column Profile", id = "column-profile"))
add(tbl(
  c("Column", "Type", "Role", "% Missing", "Unique Values", "Suggested Plot", "Suggested Test"),
  lapply(seq_len(nrow(profile)), function(i) c(
    profile$column[i], profile$r_type[i], profile$role[i],
    as.character(profile$pct_missing[i]), as.character(profile$n_unique[i]),
    profile$suggested_plot[i], profile$suggested_test[i]
  ))
))

# --- Statistical Test Results ---
if (!is.null(col_stats) && nrow(col_stats) > 0) {
  add(h(2, "Statistical Test Results", id = "statistical-test-results"))
  ranked <- col_stats[order(col_stats$p_value), ]
  add(tbl(
    c("Column", "Test", "Statistic", "p-value", "Significant (p<0.05)", "Note"),
    lapply(seq_len(nrow(ranked)), function(i) c(
      ranked$column[i], ranked$test[i], fmt_num(ranked$statistic[i]), fmt_num(ranked$p_value[i]),
      ifelse(!is.na(ranked$p_value[i]) && ranked$p_value[i] < 0.05, "yes", "no"),
      ifelse(is.na(ranked$note[i]), "", as.character(ranked$note[i]))
    ))
  ))
}

# --- Exploratory Findings ---
add(h(2, "Exploratory Findings"))
if (length(skipped_cols)) {
  add(p(paste0("**Skipped** (unique-per-row identifiers, constant, or otherwise not plot-worthy): ",
               paste(paste0("`", skipped_cols, "`"), collapse = ", "))))
}

tagged_log <- grep("^\\[(plot|skip|note|warn)\\]", log_lines, value = TRUE)

# Filenames follow 02_explore_columns.R's own convention exactly
# (eda_<make.names(col)>.png / eda_<make.names(col)>_by_<group>.png) rather
# than being scraped from log text, so a continuous column's own plot is
# never also attributed to its grouping column's section (both names could
# legally appear in the same log line, e.g. "Sepal.Length by Species").
col_images <- function(cn) {
  if (!dir.exists(explore_dir)) return(character(0))
  files <- list.files(explore_dir, pattern = "\\.png$")
  prefix <- paste0("eda_", make.names(cn))
  exact <- files == paste0(prefix, ".png")
  grouped <- grepl(paste0("^\\Q", prefix, "_by_\\E"), files, perl = TRUE)
  files[exact | grouped]
}

for (cn in plotted_cols) {
  prow <- profile[profile$column == cn, ][1, ]
  add(h(3, cn, id = slugify(cn)))
  add(p(sprintf("role: `%s` | %s unique values | %s%% missing", prow$role, prow$n_unique, prow$pct_missing)))
  for (fn in col_images(cn)) {
    add(img(file.path("exploration", fn), paste(cn, "diagnostic plot")))
  }
  lines_here <- col_mentioned(cn, tagged_log)
  if (length(lines_here)) {
    add(ul(vapply(lines_here, function(ln) sub("^\\[(\\w+)\\]\\s*", "`[\\1]` ", ln), character(1), USE.NAMES = FALSE)))
  }
}

corr_png <- file.path(explore_dir, "eda_correlation_matrix.png")
if (file.exists(corr_png)) {
  add(h(3, "Correlation Matrix", id = "correlation-matrix"))
  add(img(file.path("exploration", "eda_correlation_matrix.png"), "Correlation matrix"))
  corr_notes <- grep("correlation", tagged_log, value = TRUE, ignore.case = TRUE)
  if (length(corr_notes)) {
    add(ul(vapply(corr_notes, function(ln) sub("^\\[(\\w+)\\]\\s*", "`[\\1]` ", ln), character(1), USE.NAMES = FALSE)))
  }
}

# --- Final Curated Figures ---
add(h(2, "Final Curated Figures", id = "final-curated-figures"))
if (dir.exists(final_dir)) {
  pngs <- list.files(final_dir, pattern = "\\.png$")
  panel_pngs <- sort(grep("^final_panel_[0-9]+\\.png$", pngs, value = TRUE))
  summary_png <- if ("final_summary.png" %in% pngs) "final_summary.png" else NA
  if (length(panel_pngs) == 0 && is.na(summary_png)) {
    add(p("_No final curated figures were generated — run `03_final_plots.R`, or this dataset had no continuous/grouping columns suited to the generic panel template (see Exploratory Findings above instead)._"))
  } else {
    for (fn in panel_pngs) {
      panel_num <- sub("^final_panel_([0-9]+)\\.png$", "\\1", fn)
      add(h(3, paste("Panel", panel_num)))
      add(img(file.path("final", fn), paste("Final panel", panel_num)))
    }
    if (!is.na(summary_png)) {
      add(h(3, "Combined Summary"))
      add(img(file.path("final", summary_png), "Combined summary panel"))
    }
  }
  final_notes <- grep("^\\[(warn|note)\\]", final_log_lines, value = TRUE)
  if (length(final_notes)) {
    add(p("Notes from the finalize step:"))
    add(ul(vapply(final_notes, function(ln) sub("^\\[(\\w+)\\]\\s*", "`[\\1]` ", ln), character(1), USE.NAMES = FALSE)))
  }
} else {
  add(p("_No `final/` directory found — run `03_final_plots.R` before generating the report to include curated figures._"))
}

# --- Review Checklist ---
if (length(checklist_lines)) {
  add(h(2, "Review Checklist", id = "review-checklist"))
  items <- grep("^\\[(PASS|WARN|FAIL)\\]", checklist_lines, value = TRUE)
  status <- sub("^\\[([A-Z]+)\\].*", "\\1", items)
  msg <- sub("^\\[[A-Z]+\\]\\s*", "", items)
  summary_line <- checklist_lines[length(checklist_lines)]
  add(checklist_block(data.frame(status = status, message = msg, stringsAsFactors = FALSE), summary_line))
}

# --- Reproducibility ---
add(h(2, "Reproducibility", id = "reproducibility"))
r_version_line <- if (length(session_lines)) session_lines[grepl("^R version", session_lines)][1] else NA
add(kv(list(
  c("Input file", normalizePath(input_path, mustWork = FALSE)),
  c("Output directory", normalizePath(output_dir, mustWork = FALSE)),
  c("R session", if (!is.na(r_version_line)) r_version_line else "see session_info.txt"),
  c("Report generated", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  c("Skill", "r-dataviz-explorer")
)))

# --- Render: markdown ---
md_render <- function(blocks) {
  out <- c()
  for (b in blocks) {
    if (b$type %in% c("h1", "h2", "h3", "h4")) {
      level <- as.integer(substr(b$type, 2, 2))
      out <- c(out, paste0(strrep("#", level), " ", b$text), "")
    } else if (b$type == "p") {
      out <- c(out, b$text, "")
    } else if (b$type == "ul") {
      out <- c(out, paste0("- ", b$items), "")
    } else if (b$type == "img") {
      out <- c(out, sprintf("![%s](%s)", b$alt, gsub("\\\\", "/", b$path)), "")
    } else if (b$type == "table") {
      header <- vapply(b$header, md_cell, character(1))
      out <- c(out, paste0("| ", paste(header, collapse = " | "), " |"),
                paste0("|", paste(rep("---", length(header)), collapse = "|"), "|"))
      for (row in b$rows) {
        out <- c(out, paste0("| ", paste(vapply(row, md_cell, character(1)), collapse = " | "), " |"))
      }
      out <- c(out, "")
    } else if (b$type == "checklist") {
      for (i in seq_len(nrow(b$items))) {
        out <- c(out, sprintf("- **%s** %s", b$items$status[i], b$items$message[i]))
      }
      out <- c(out, "", paste0("**", b$summary, "**"), "")
    }
  }
  out
}

# --- Render: html ---
html_render <- function(blocks, output_dir) {
  out <- c()
  for (b in blocks) {
    if (b$type %in% c("h1", "h2", "h3", "h4")) {
      level <- substr(b$type, 2, 2)
      id_attr <- if (!is.null(b$id)) sprintf(' id="%s"', b$id) else ""
      out <- c(out, sprintf("<h%s%s>%s</h%s>", level, id_attr, md_inline_html(b$text), level))
    } else if (b$type == "p") {
      out <- c(out, sprintf("<p>%s</p>", md_inline_html(b$text)))
    } else if (b$type == "ul") {
      out <- c(out, "<ul>", paste0("<li>", md_inline_html(b$items), "</li>"), "</ul>")
    } else if (b$type == "img") {
      full_path <- file.path(output_dir, b$path)
      if (file.exists(full_path)) {
        cap <- if (!is.null(b$caption)) sprintf("<figcaption>%s</figcaption>", md_inline_html(b$caption)) else ""
        out <- c(out, sprintf('<figure><img src="%s" alt="%s" loading="lazy">%s</figure>',
                               img_data_uri(full_path), esc_html(b$alt), cap))
      } else {
        out <- c(out, sprintf('<p class="missing-img">[image not found: %s]</p>', esc_html(b$path)))
      }
    } else if (b$type == "table") {
      out <- c(out, '<div class="table-wrap"><table><thead><tr>',
                paste0("<th>", md_inline_html(b$header), "</th>", collapse = ""),
                "</tr></thead><tbody>")
      for (row in b$rows) {
        out <- c(out, paste0("<tr>", paste0("<td>", md_inline_html(row), "</td>", collapse = ""), "</tr>"))
      }
      out <- c(out, "</tbody></table></div>")
    } else if (b$type == "checklist") {
      out <- c(out, '<ul class="checklist">')
      for (i in seq_len(nrow(b$items))) {
        cls <- tolower(b$items$status[i])
        out <- c(out, sprintf('<li><span class="badge badge-%s">%s</span> %s</li>',
                               cls, b$items$status[i], md_inline_html(b$items$message[i])))
      }
      out <- c(out, "</ul>", sprintf('<p class="checklist-summary">%s</p>', esc_html(b$summary)))
    }
  }
  paste(out, collapse = "\n")
}

md_lines <- md_render(blocks)
md_path <- file.path(output_dir, "report.md")
writeLines(md_lines, md_path)

html_body <- html_render(blocks, output_dir)

css <- paste(
  ":root { --bg:#faf9f7; --card-bg:#ffffff; --text:#1f2328; --text-muted:#57606a; --border:#e3e1dd;",
  "  --blue:#0072B2; --vermillion:#D55E00; --green:#009E73; --orange:#E69F00; --code-bg:#f0eee9; }",
  "@media (prefers-color-scheme: dark) {",
  "  :root { --bg:#1a1c1e; --card-bg:#24272b; --text:#e6e6e6; --text-muted:#a0a6ab; --border:#383c40; --code-bg:#2d3034; }",
  "}",
  "* { box-sizing:border-box; }",
  "body { margin:0; background:var(--bg); color:var(--text);",
  "  font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Helvetica,Arial,sans-serif; line-height:1.55; }",
  ".report { max-width:920px; margin:0 auto; padding:2.5rem 1.5rem 4rem; }",
  "h1 { font-size:1.9rem; border-bottom:3px solid var(--blue); padding-bottom:0.5rem; margin-bottom:0.4rem; }",
  "h2 { font-size:1.4rem; margin-top:2.5rem; border-bottom:1px solid var(--border); padding-bottom:0.35rem; }",
  "h3 { font-size:1.15rem; margin-top:1.8rem; color:var(--blue); }",
  "h4 { font-size:1rem; margin-top:1.2rem; }",
  "em { color:var(--text-muted); }",
  "code { background:var(--code-bg); padding:0.1em 0.35em; border-radius:4px; font-size:0.9em;",
  "  font-family:ui-monospace,SFMono-Regular,Menlo,monospace; }",
  "ul { padding-left:1.4rem; } li { margin:0.25rem 0; }",
  "a { color:var(--blue); }",
  ".table-wrap { overflow-x:auto; margin:0.8rem 0; }",
  "table { border-collapse:collapse; width:100%; font-size:0.92rem; }",
  "th, td { border:1px solid var(--border); padding:0.5rem 0.7rem; text-align:left; }",
  "th { background:var(--code-bg); font-weight:600; }",
  "figure { margin:1.2rem 0; text-align:center; }",
  "figure img { max-width:100%; border:1px solid var(--border); border-radius:8px; box-shadow:0 1px 4px rgba(0,0,0,0.08); }",
  "figcaption { color:var(--text-muted); font-size:0.85rem; margin-top:0.4rem; font-style:italic; }",
  ".missing-img { color:var(--vermillion); font-style:italic; }",
  ".checklist { list-style:none; padding-left:0; }",
  ".badge { display:inline-block; padding:0.15em 0.55em; border-radius:999px; font-size:0.75em;",
  "  font-weight:700; color:white; margin-right:0.4em; letter-spacing:0.02em; }",
  ".badge-pass { background:var(--green); } .badge-warn { background:var(--orange); } .badge-fail { background:var(--vermillion); }",
  ".checklist-summary { font-weight:600; margin-top:0.6rem; }",
  sep = "\n"
)

html_doc <- paste0(
  "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n",
  "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n",
  "<title>", esc_html(paste("Data Exploration Report:", basename(input_path))), "</title>\n",
  "<style>\n", css, "\n</style>\n</head>\n<body>\n<div class=\"report\">\n", html_body, "\n</div>\n</body>\n</html>\n"
)
html_path <- file.path(output_dir, "report.html")
writeLines(html_doc, html_path)

message("\nReport assembled from ", n_cols, " profiled columns (", length(plotted_cols), " plotted, ",
        length(skipped_cols), " skipped).")
message("Markdown report written -> ", md_path)
message("HTML report written -> ", html_path)
