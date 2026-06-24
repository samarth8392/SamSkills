---
name: interactify-qmd
version: 1.0.0
description: >
  Use when asked to upgrade a Quarto (.qmd) analysis report so that every
  table and figure becomes maximally interactive and visually consistent with
  the target peer-review HTML aesthetic. Dispatches parallel subagents, one
  per logical section group, each owning its R chunks end-to-end. Orchestrator
  assembles a new .qmd and re-renders.
  Trigger phrases: "make interactive", "upgrade plots", "interactify",
  "add plotly", "$interactify-qmd".
skills_used:
  - superpowers:dispatching-parallel-agents
  - superpowers:subagent-driven-development
  - scientific-agent-skills:document-skills
author: user
---

# interactify-qmd

## Purpose

Transform every static ggplot2 figure and kable table in the source .qmd into
an interactive, visually polished equivalent using plotly, DT, crosstalk,
reactable, and htmlwidgets — while preserving all data-loading logic and
statistical conclusions. Output is a drop-in replacement .qmd that renders to
a self-contained HTML with no external dependencies.

---

## ORCHESTRATOR WORKFLOW

### STEP 0 — Inputs

Collect if not provided:
- `QMD_FILE`: path to source .qmd (default: `supp_analysis_report.qmd`)
- `CSS_FILE`: path to custom.css (default: `custom.css`)
- `OUTPUT_QMD`: default `supp_analysis_report_interactive.qmd`
- `EXCEL_FILE`: path to `Supporting_Information-Tables.xlsx`

Do not proceed until `QMD_FILE` is confirmed and readable.

---

### STEP 1 — Parse the source QMD

Extract the full YAML front matter.
Produce `_iqmd_tmp/chunk_inventory.json` listing every named code chunk:

```json
[
  {
    "chunk_id": "s17_kinship_setup",
    "section": "S17 Kinship",
    "group": "A",
    "role": "setup",
    "lines": [120, 210],
    "output_types": ["none"],
    "libraries_current": ["readxl","tidyverse","ggplot2","rstatix","knitr"]
  },
  ...
]
```

`role` is one of: `setup`, `plot`, `table`, `test`, `narrative`.
`output_types` is one of: `ggplot`, `kable`, `DT`, `text`, `none`.

Also extract the prose narrative blocks (non-chunk content) between sections —
these are passed to subagents verbatim and must not be altered.

---

### STEP 2 — Resolve the upgrade library matrix

For each group, the canonical target libraries are:

| Group | Section | Tables → | Figures → | Interactivity layer |
|-------|---------|-----------|-----------|---------------------|
| A | S17 Kinship | DT (searchable, color-coded) | plotly scatter + violin | crosstalk SharedData for cross-filter |
| B | Fst + Divergence | DT + reactable | plotly lollipop + heatmap (heatmaply) | plotly linked views |
| C | Demographic S8-S11 | reactable (grouped) | plotly bar (delta-AIC) + boxplot | plotly subplot |
| D | BPP S4 | DT heatmap cells | heatmaply | color scale + tooltip |
| E | LoF S12/S14/S16 | DT | plotly bar + strip | crosstalk filter by consequence |
| F | Enrichment S7/S13/S15 | DT | plotly horizontal bar | tab widget (see JS below) |
| G | QC S1/S2 | DT | plotly violin + bar | crosstalk filter by population |
| H | Fixed missense S5/S6 | reactable | plotly bar + strip | None needed |

Packages to add to every chunk setup block:
```r
library(plotly)
library(DT)
library(reactable)
library(crosstalk)
library(heatmaply)
library(htmltools)
library(htmlwidgets)
```

---

### STEP 3 — Write the new YAML front matter

Replace the source YAML with:

```yaml
---
title: "Supplementary Data Analysis Report"
subtitle: "Evidence review: Drift and isolation drive genomic erosion — Qi et al."
date: today
author: "Multi-reviewer agentic panel"
format:
  html:
    toc: true
    toc-depth: 3
    toc-location: left
    toc-title: "Sections"
    number-sections: true
    theme: [flatly, custom.css]
    css: custom.css
    code-fold: true
    code-summary: "Show R code"
    embed-resources: true
    self-contained-math: true
    fig-width: 9
    fig-height: 6
    fig-dpi: 150
    df-print: kable
    smooth-scroll: true
    page-layout: article
    grid:
      sidebar-width: 230px
      body-width: 960px
      margin-width: 40px
    include-in-header:
      text: |
        <script>
        // Tab widget initialiser — runs after page load
        document.addEventListener('DOMContentLoaded', function() {
          document.querySelectorAll('.tab-group').forEach(function(group) {
            var btns   = group.querySelectorAll('.tab-btn');
            var panels = group.querySelectorAll('.tab-panel');
            btns.forEach(function(btn, i) {
              btn.addEventListener('click', function() {
                btns.forEach(function(b){ b.classList.remove('active'); });
                panels.forEach(function(p){ p.classList.remove('active'); });
                btn.classList.add('active');
                panels[i].classList.add('active');
              });
            });
            if (btns.length > 0) { btns[0].click(); }
          });

          // Section stripe colouring by heading text keyword
          var stripeMap = {
            'critical': ['kinship','bpp','species','mc1','mc2'],
            'major':    ['fst','divergence','demographic','mc4','mc5','mc6'],
            'minor':    ['lof','enrichment','missense','mc3','mc7','mc8'],
            'repro':    ['repro','qc','metadata','s1','s2'],
            'stats':    ['statistical','aic','bootstrap']
          };
          document.querySelectorAll('h2').forEach(function(h) {
            var txt = h.textContent.toLowerCase();
            for (var cls in stripeMap) {
              if (stripeMap[cls].some(function(kw){ return txt.includes(kw); })) {
                h.setAttribute('data-section', cls);
                break;
              }
            }
          });
        });
        </script>
execute:
  echo: true
  warning: false
  message: false
  cache: false
---
```

---

### STEP 4 — Write the interactive executive summary section

Replace the static markdown `### Key findings at a glance` table with:

```r
#| label: exec-summary-table
#| echo: false

library(DT)
library(htmltools)

badge_html <- function(x) {
  map <- c(
    "Yes"     = "pill pill-ok",
    "No"      = "pill pill-critical",
    "Partial" = "pill pill-partial",
    "Shown"   = "pill pill-shown",
    "TBD"     = "pill pill-major"
  )
  cls <- ifelse(!is.na(map[x]), map[x], "pill")
  paste0('<span class="', cls, '">', x, '</span>')
}

exec_df <- tibble::tribble(
  ~Claim, ~`Table(s)`, ~Finding, ~`Supports review?`,
  "MC1: DGD kinship (CRITICAL)", "S17",
    "22 >= 2nd-degree, 6 >= 1st-degree, 3 >= MZ/dup (max = 0.4729)",
    "Yes",
  "MC4: Fst inflation",  "S3",
    "DGD-littoralis = 0.278; DGD-lasiotis = 0.296; 0.473 is not a lower bound",
    "Yes",
  "MC4: Divergence matrix", "S18",
    "Lower-triangular matrix parsed and clustered; DGD samples highlighted",
    "Shown",
  "MC6: AIC inconsistency", "S8-S10",
    "All 27 recalculated AIC values disagree with reported values",
    "Yes",
  "MC6: Ne CIs", "S11",
    "NBOTDGD 95th-percentile CI = 115.4-624.8 across 50 bootstrap runs",
    "Shown",
  "MC2: BPP sensitivity", "S4",
    "16/108 PP cells < 0.95; PP = 1.0 is conditional on fixed A10 setup",
    "Yes",
  "MC8: LoF annotation", "S12/S14/S16",
    "1,042 Geneset I genes vs 85 Geneset II; 34 S16 variants across 4 classes",
    "Yes",
  "MC3/MC8: Enrichment", "S7/S13/S15",
    "Raw p-values only; no FDR q-values, background, or gene-ratio reported",
    "Yes",
  "MC7/OVERARCHING: QC", "S1/S2",
    "21 samples < 10x; S2 non-integer SNP counts in Dataset II",
    "Yes",
  "MC3: Fixed missense", "S5/S6",
    "S5: 2,353 genes, no chromosome field; S6: 251 unique genes (10.7% of S5)",
    "Yes"
)

exec_df$`Supports review?` <- badge_html(exec_df$`Supports review?`)

DT::datatable(
  exec_df,
  escape      = FALSE,
  rownames    = FALSE,
  caption     = "Key findings at a glance — click any column header to sort",
  filter      = "top",
  options     = list(
    pageLength  = 10,
    dom         = "ftp",
    autoWidth   = TRUE,
    columnDefs  = list(
      list(width = "140px", targets = 0),
      list(width = "70px",  targets = 1),
      list(className = "dt-left", targets = "_all")
    ),
    initComplete = DT::JS(
      "function(settings, json) {",
      "  $(this.api().table().header()).css({'background':'var(--bg)',",
      "    'font-size':'10.5px','text-transform':'uppercase',",
      "    'letter-spacing':'0.06em','color':'var(--text-dim)'});",
      "}"
    )
  )
)
```

---

### STEP 5 — Dispatch 8 parallel subagents

Use `superpowers:dispatching-parallel-agents`.
Each subagent receives:
- The SUBAGENT PROMPT TEMPLATE below, filled with its group variables
- The full chunk text for its group (extracted from chunk_inventory.json)
- The new YAML and library matrix
- Output path: `_iqmd_tmp/group_<ID>.qmd`

Dispatch all 8 simultaneously. Wait for all before Step 6.

---

### STEP 6 — Validate and assemble

For each `_iqmd_tmp/group_<ID>.qmd`:
- Confirm: at least one `plotly` or `DT` or `reactable` call present
- Confirm: all `ggplot(...)` calls are wrapped in `plotly::ggplotly(...)` or
  replaced with native plotly; any that cannot be wrapped get a note
- Confirm: all `knitr::kable(...)` calls are replaced with `DT::datatable(...)`,
  `reactable::reactable(...)`, or retained with a `# TODO` if conversion is
  non-trivial
- If a chunk fails either check: re-dispatch once with an explicit
  "You must use plotly/DT/reactable — no static ggplot2/kable output" directive

Assemble output .qmd:
```
YAML front matter (from Step 3)
Executive summary section (from Step 4)
group_A.qmd
group_B.qmd
group_C.qmd
group_D.qmd
group_E.qmd
group_F.qmd
group_G.qmd
group_H.qmd
Session info appendix
```

---

### STEP 7 — Render

```bash
quarto render OUTPUT_QMD --to html
```

On failure, capture stderr, identify the failing chunk, fix R syntax (not
logic), re-render once. Report path and any chunks that needed manual fallback.

---

### STEP 8 — Cleanup

Remove `_iqmd_tmp/`. Keep `.qmd` and rendered `.html`.

---

## SUBAGENT PROMPT TEMPLATE

Fill: `{{GROUP_ID}}`, `{{SECTION_LABEL}}`, `{{CHUNK_CODE}}`,
`{{EXCEL_PATH}}`, `{{REVIEW_CLAIM}}`, `{{OUTPUT_PATH}}`.

```xml
<task>
You are a senior R developer and data-viz specialist. Your task is to rewrite
a specific set of R code chunks from a Quarto analysis report so that every
table and figure is maximally interactive and visually consistent with the
target CSS design system described below.

<group>{{GROUP_ID}}</group>
<section>{{SECTION_LABEL}}</section>
<excel_path>{{EXCEL_PATH}}</excel_path>
<output_path>{{OUTPUT_PATH}}</output_path>

<review_claim>
{{REVIEW_CLAIM}}
</review_claim>

<source_chunks>
{{CHUNK_CODE}}
</source_chunks>

<css_design_tokens>
All interactive output must use these CSS variables for color consistency.
Do NOT hardcode hex values in R — use the CSS variables via the
`config` argument in plotly layout or pass them as character strings that
match the design system below:

  Background:    #f8f7f4
  Surface:       #ffffff
  Border:        #e0ddd5
  Text:          #1a1a1a / #333333
  Muted text:    #666666
  DGD highlight: #E24B4A  (red)
  Mainland:      #378ADD  (blue)
  Outgroup:      #888780  (gray)
  Critical:      #a32d2d / bg #fcebeb
  Major:         #854f0b / bg #faeeda
  Minor:         #3b6d11 / bg #eaf3de
  Shown:         #185fa5 / bg #e6f1fb
  Violet:        #534ab7 / bg #eeedfe
  Teal:          #0f6e56 / bg #e1f5ee

Plotly layout baseline (apply to every plotly figure):
  paper_bgcolor = "#ffffff"
  plot_bgcolor  = "#f8f7f4"
  font.family   = "system-ui, -apple-system, sans-serif"
  font.size     = 12
  font.color    = "#333333"
  margin        = list(l=60, r=40, t=60, b=60)
  hoverlabel    = list(bgcolor="#fff", font=list(size=12))
</css_design_tokens>

<instructions>

## Your output

Write a single .qmd chunk file to {{OUTPUT_PATH}} containing:

1. A level-2 section header matching the original section
2. All prose context paragraphs copied verbatim (do NOT alter text)
3. Upgraded R code chunks using the rules below
4. All interpretation paragraphs copied verbatim

## MANDATORY UPGRADE RULES

### Rule 1 — No static ggplot2 output
Every `ggplot(...)` call that produces a figure must be either:
  (a) Wrapped: `plotly::ggplotly(p, tooltip = c("x","y","text"))` then
      piped through `plotly::layout(...)` to apply the design tokens above, OR
  (b) Replaced entirely with native plotly if ggplotly conversion loses
      important features (e.g. facets with free scales, geom_segment networks,
      complex repel labels). Native plotly is preferred for complex figures.

Always assign the ggplot to a variable `p` first, then convert:
```r
p <- ggplot(data, aes(...)) + ...
plotly::ggplotly(p, tooltip = "text") |>
  plotly::layout(
    paper_bgcolor = "#ffffff",
    plot_bgcolor  = "#f8f7f4",
    font = list(family = "system-ui, -apple-system, sans-serif",
                size = 12, color = "#333333"),
    hoverlabel = list(bgcolor = "#fff", font = list(size = 12)),
    margin = list(l = 60, r = 40, t = 60, b = 60)
  ) |>
  plotly::config(displayModeBar = TRUE, displaylogo = FALSE,
                 modeBarButtonsToRemove = c("pan2d","lasso2d","select2d",
                                             "autoScale2d","toggleSpikelines"))
```

### Rule 2 — No knitr::kable() / kable() output
Replace every `knitr::kable(df, ...)` with either:

**DT::datatable()** for tables with > 10 rows or that benefit from search/sort:
```r
DT::datatable(
  df,
  rownames    = FALSE,
  escape      = FALSE,     # required when badge_html() is used
  filter      = "top",
  caption     = "Caption text here",
  extensions  = c("Buttons","ColReorder"),
  options     = list(
    pageLength  = 15,
    dom         = "Bfrtip",
    buttons     = list("csv","excel","copy"),
    scrollX     = TRUE,
    autoWidth   = TRUE,
    initComplete = DT::JS(
      "function(settings, json) {",
      "  $(this.api().table().header()).css({",
      "    'background':'#f8f7f4',",
      "    'font-size':'10.5px',",
      "    'text-transform':'uppercase',",
      "    'letter-spacing':'0.06em',",
      "    'color':'#888888'",
      "  });",
      "}"
    )
  )
)
```

**reactable::reactable()** for tables where grouping, expandable rows, or
inline sparklines add meaningful value (e.g. population summary tables,
AIC audit tables):
```r
reactable::reactable(
  df,
  searchable    = TRUE,
  filterable    = TRUE,
  striped       = FALSE,
  highlight     = TRUE,
  bordered      = FALSE,
  compact       = TRUE,
  defaultPageSize = 15,
  theme = reactable::reactableTheme(
    color            = "#333333",
    backgroundColor  = "#ffffff",
    borderColor      = "#e0ddd5",
    stripedColor     = "#fafaf8",
    highlightColor   = "#f8f7f4",
    headerStyle      = list(
      background     = "#f8f7f4",
      color          = "#888888",
      fontSize       = "10.5px",
      textTransform  = "uppercase",
      letterSpacing  = "0.06em"
    )
  ),
  columns = list(...)  # specify per-column renderers as needed
)
```

### Rule 3 — DGD must always be highlighted
In every plot, DGD must appear in #E24B4A (red). Add a `text` aesthetic or
`customdata` column that includes the population name and key statistic for
the hover tooltip. Example pattern:
```r
df <- df |> mutate(
  tooltip_text = paste0(
    "<b>", population, "</b><br>",
    "Kinship: ", round(Kinship, 4), "<br>",
    "Class: ", relationship_class
  )
)
```

### Rule 4 — Thresholds must be visible lines with hover text
Replace `geom_hline`/`geom_vline` with plotly `shapes` + `annotations`:
```r
plotly::layout(
  shapes = list(
    list(type="line", x0=0, x1=1, xref="paper",
         y0=0.354, y1=0.354, yref="y",
         line=list(color="#a32d2d", width=1, dash="dash")),
    ...
  ),
  annotations = list(
    list(x=0.02, xref="paper", y=0.354, yref="y",
         text="MZ/duplicate (0.354)", showarrow=FALSE,
         font=list(size=10, color="#a32d2d"),
         bgcolor="#fcebeb", borderpad=3)
  )
)
```

### Rule 5 — Crosstalk for linked panels (Groups A, B, E, G)
When the section has multiple plots or a plot+table combination that share
the same data frame, wrap the shared data in a `crosstalk::SharedData` object
and use the same key across both plotly and DT/reactable widgets:
```r
library(crosstalk)
shared <- SharedData$new(df, key = ~sample_id, group = "section_A")
# Use shared instead of df in plot and table
```
Add a `bscols()` layout only when filter controls are added via
`filter_select()` or `filter_checkbox()`.

### Rule 6 — Multi-panel figures use plotly::subplot()
Replace `patchwork` layouts with:
```r
plotly::subplot(p1, p2, nrows = 1, shareX = FALSE, shareY = FALSE,
                titleX = TRUE, titleY = TRUE) |>
  plotly::layout(...)
```

### Rule 7 — Tab widget for multi-sheet enrichment (Group F)
Wrap each sheet's plot+table in a div with the CSS tab classes so the JS
initialiser (in the YAML header) picks it up:
```r
htmltools::tagList(
  htmltools::tags$div(class = "tab-group",
    htmltools::tags$div(class = "tab-nav",
      htmltools::tags$button(class = "tab-btn", "S7 Fixed missense"),
      htmltools::tags$button(class = "tab-btn", "S13 Geneset I LoF"),
      htmltools::tags$button(class = "tab-btn", "S15 Geneset II LoF")
    ),
    htmltools::tags$div(class = "tab-panel",
      plotly_s7_widget,
      DT_s7_table
    ),
    htmltools::tags$div(class = "tab-panel",
      plotly_s13_widget,
      DT_s13_table
    ),
    htmltools::tags$div(class = "tab-panel",
      plotly_s15_widget,
      DT_s15_table
    )
  )
)
```

### Rule 8 — Verdict strip in executive summary
Add this HTML block after the YAML and before the first section using
`htmltools::HTML()` inside an `#| output: asis` chunk:
```r
htmltools::tagList(
  htmltools::tags$div(class = "verdict-strip",
    htmltools::tags$div(class = "vcard",
      htmltools::tags$div(class = "vcard-label", "Critical / fatal"),
      htmltools::tags$div(class = "vcard-value v-critical", "2"),
      htmltools::tags$div(class = "vcard-sub", "all 5 reviewers")
    ),
    htmltools::tags$div(class = "vcard",
      htmltools::tags$div(class = "vcard-label", "Major comments"),
      htmltools::tags$div(class = "vcard-value v-major", "8"),
      htmltools::tags$div(class = "vcard-sub", "≥ 3 reviewers")
    ),
    htmltools::tags$div(class = "vcard",
      htmltools::tags$div(class = "vcard-label", "Minor comments"),
      htmltools::tags$div(class = "vcard-value v-minor", "10"),
      htmltools::tags$div(class = "vcard-sub", "2 reviewers")
    ),
    htmltools::tags$div(class = "vcard",
      htmltools::tags$div(class = "vcard-label", "Specific flags"),
      htmltools::tags$div(class = "vcard-value v-flag", "12"),
      htmltools::tags$div(class = "vcard-sub", "line / figure level")
    )
  )
)
```

## GROUP-SPECIFIC INSTRUCTIONS

### Group A — S17 Kinship [CRITICAL]
Priority: highest. This section must be the most polished.
- Main kinship violin: native plotly with jitter trace overlay;
  `add_trace(type="violin")` + `add_trace(type="scatter", mode="markers")`;
  DGD in #E24B4A, mainlands in #378ADD.
- Ranked heatmap of DGD-DGD pairs: `plot_ly(type="heatmap")` with magma
  colorscale; hover shows pair IDs, kinship value, relationship class.
- Threshold barplot: `plot_ly(type="bar")` faceted by population via subplot.
- Population summary table: reactable with conditional cell coloring —
  `reactable::colDef(style=function(value){...})` to color max_kinship red
  when >= 0.354, amber when >= 0.177.
- Statistical test results: DT with badge_html() applied to p_value column.
- Add crosstalk: SharedData keyed on `population`; filter_select for
  "Filter populations" linked to the violin plot and summary table.

### Group B — Fst + Divergence (S3 + S18)
- S3 dot plot: native plotly scatter; DGD points in red, labeled;
  dashed shape line at 0.473 with annotation; hover shows exact Fst.
- S3 table: DT with `formatStyle("fst", background=...)` to color rows
  below/above the claimed bound.
- S18 heatmap: `heatmaply::heatmaply(div_mat, ...)` with DGD rows/cols
  annotated; use `row_side_colors` for DGD flag.

### Group C — Demographic S8-S11
- Delta-AIC barplot: native plotly; best model highlighted in green;
  hover shows model name, negLogL, k, recalculated AIC, reported AIC,
  difference; color bars by audit_status (matches/differs).
- AIC audit table: reactable with inline bar column for delta_aic_recalc
  using `colDef(cell=reactable::bar_chart(...))`.
- S11 bootstrap: plotly subplot, one box+jitter panel per parameter;
  NBOTDGD panel highlighted; hover shows run number and value.
- Ne CI table: DT with CV > 0.5 rows highlighted via formatStyle.

### Group D — BPP S4
- heatmaply heatmap anchored at PP = 0.95 midpoint; cells below 0.95
  get orange border via custom cell rendering; hover shows exact PP.
- DT table of full PP matrix with formatStyle coloring cells < 0.95 in
  amber background.

### Group E — LoF S12/S14/S16 (crosstalk across consequence types)
- Geneset size bar: plotly; tooltip explains the demographic vs selection
  interpretation.
- S16 consequence bar: plotly; crosstalk SharedData keyed on consequence_type.
- S16 chromosome strip: plotly scatter; crosstalk SharedData same group,
  so clicking a consequence type in the bar filters the chromosome strip.
- S16 variant table: DT linked to same SharedData group;
  columns: gene, chr, position, consequence (badge_html), description.
- Add `filter_select("Consequence", "Filter by consequence", shared,
  ~consequence_type)` using bscols().

### Group F — Enrichment S7/S13/S15 (tab widget)
- One tab per sheet. Within each tab:
  - plotly horizontal lollipop for top 20 terms ranked by -log10(raw_p);
    points sized by gene_ratio; colored by category (BP/MF/CC/KEGG);
    dashed shape line at -log10(0.05) and dot-dash at BH q = 0.05 threshold.
  - DT table with all terms; columns: category (badge), id, description,
    count, raw_p (formatted), bh_q_within_table; sortable.
  - A `callout-warning` block (htmltools) noting that FDR q-values, background
    universe, and gene-length correction are absent from the authors' tables.

### Group G — QC S1/S2 (crosstalk filter by population)
- S1 depth violin+jitter: plotly; SharedData keyed on `population`;
  10x threshold as dashed shape; DGD in red; tooltip shows sample_id,
  depth, coverage, mapping_rate, dataset.
- S1 low-depth table: DT, yellow highlight on depth < 10 rows via
  formatStyle; linked to same SharedData.
- S1 count barplot: plotly grouped bar; faceted by dataset via subplot.
- S2 non-integer count plot: plotly bar (log10 y); tooltip shows exact value;
  non-integer cells highlighted in amber.
- S1 metadata audit: reactable with emoji-style status column
  (✓ / ✗) for represented_in_s1.

### Group H — Fixed missense S5/S6
- S5 field availability: plotly horizontal bar.
- S6 chromosome distribution: plotly bar with Mb positions; color by
  chromosome arm if possible.
- S5/S6 ratio: plotly waterfall or two-bar comparison; add annotation
  explaining 10.7% is a catalogue ratio, not a genome-wide enrichment test.
- reactable for the chromosome-gene-site comparison table with
  inline bar for site_rows_per_unique_gene.

## WHAT NOT TO DO
- Do NOT alter any data-loading or statistical test logic.
- Do NOT change prose narrative paragraphs.
- Do NOT introduce additional data not in the Excel workbook.
- Do NOT fabricate numbers.
- Do NOT install packages — assume plotly, DT, reactable, crosstalk,
  heatmaply, htmltools, htmlwidgets, tidyverse, readxl, rstatix, knitr,
  patchwork, janitor, ggrepel, viridis are all available.
- Do NOT use `ggplotly()` when native plotly would produce a better result.
- Do NOT leave any `knitr::kable()` calls in output chunks unless wrapped
  in a `# TODO: ` comment explaining why conversion is non-trivial.

Output ONLY the .qmd chunk content for your group — no preamble, no
explanation. Include chunk labels, options, prose, and interpretation
paragraphs exactly as they appeared in the source, with only the R code
upgraded.

</instructions>
</task>
```

---

## NOTES FOR ORCHESTRATOR

- Verify `embed-resources: true` is in YAML — required for all htmlwidgets
  (plotly, DT, reactable, heatmaply) to be self-contained in the output HTML.
- Render order: if a subagent uses crosstalk SharedData, its group ID must
  be globally unique within the document — prefix with the group letter.
- heatmaply imports plotly and ggplot2; do not double-import.
- DT `extensions: Buttons` requires the DataTables Buttons plugin, which is
  bundled in the DT package — no extra CDN dependency.
- reactable inline bar charts use `reactable::bar_chart()` helper — include
  this helper function in the setup chunk of any group that uses it:
  ```r
  bar_chart <- function(label, width = "100%", height = "1rem", fill = "#378ADD") {
    bar <- htmltools::div(
      style = paste0(
        "width:", width, ";height:", height,
        ";background:", fill, ";border-radius:2px;"
      )
    )
    htmltools::div(
      style = "display:flex;align-items:center;gap:6px;",
      bar,
      htmltools::span(label, style="font-size:11px;color:#666;")
    )
  }
  ```
- If render fails on heatmaply (sometimes conflicts with plotly version),
  fall back to a native plotly heatmap for that chunk only.
- Final render command:
  ```bash
  quarto render supp_analysis_report_interactive.qmd --to html 2>&1 | tee render.log
  ```
  Parse `render.log` for `ERROR` lines to locate failing chunks.
