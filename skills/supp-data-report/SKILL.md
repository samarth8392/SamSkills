---
name: supp-data-report
version: 1.0.0
description: >
  Use when asked to analyze supplementary data files (Excel/CSV/TSV) from a
  manuscript under review and produce a Quarto (.qmd) report that plots and
  stress-tests each table against specific peer review claims.
  Dispatches parallel subagents per sheet/table group. Orchestrator collates
  all analyses into a single .qmd with executive summary tied to the review.
  Trigger: "analyze supplementary data against review", "plot supp tables",
  "build data report for review", "$supp-data-report".
skills_used:
  - superpowers:dispatching-parallel-agents
  - superpowers:subagent-driven-development
  - scientific-agent-skills:document-skills
  - scientific-agent-skills:scientific-writing
author: user
---

# supp-data-report

## Purpose

For each supplementary table in the manuscript's Excel workbook:
1. Load and parse the sheet
2. Understand column semantics from headers and table-title text
3. Map the sheet to the peer review claim it evidences
4. Write R analysis code: data wrangling + statistical tests + ggplot2 figures
5. Produce a single .qmd file that compiles all analyses into a reviewer-ready
   HTML report — one section per claim, each section containing:
   - Context paragraph (what the table shows, what the claim is)
   - One or more plots
   - Statistical test output
   - Interpretation sentence tying the result back to the review comment

---

## ORCHESTRATOR WORKFLOW

### STEP 0 — Inputs

Collect if not provided:
  - `EXCEL_FILE`: path to supplementary Excel workbook (.xlsx)
  - `REVIEW_FILE`: path to peer_review*.md
  - `OUTPUT_QMD`: default `supp_analysis_report.qmd`
  - `OUTPUT_DIR`: directory for rendered HTML and assets; default same as Excel
  - `R_LIBS`: optional path to R library if not in default `.libPaths()`

---

### STEP 1 — Load workbook manifest

Use Python (openpyxl or pandas/xlrd) to read all sheet names and extract,
for each sheet:
  - Sheet name (e.g. "S17")
  - Row 0: full table title / description string
  - Row 1: column names
  - Nrow, ncol (data rows only, excluding title rows)
  - First 3 data rows for type-sniffing

Write manifest to `_qmd_tmp/manifest.json`:
```json
[
  {
    "sheet": "S17",
    "title": "Supplementary Table S17. Kinship coefficient...",
    "columns": ["population","ID1","ID2","N_SNP","HetHet","IBS0","Kinship"],
    "nrow": 467,
    "ncol": 7,
    "sample_rows": [...]
  }
]
```

---

### STEP 2 — Map sheets to review claims

Read `REVIEW_FILE`. For each sheet in the manifest, assign:
  - `claim_id`: which CRITICAL/MAJOR/MINOR comment it evidences
  - `claim_title`: short label
  - `analysis_type`: one of [kinship, fst, demographic, ne_estimate,
    enrichment, lof_annotation, species_delim, sequencing_qc, divergence]

Use the SHEET-TO-CLAIM MAP below as the canonical assignment.
Store in `_qmd_tmp/manifest.json` under `claim_id` and `analysis_type`.

---

### STEP 3 — Dispatch parallel subagents

Use `superpowers:dispatching-parallel-agents`.
One subagent per sheet (or per logical group — see SHEET GROUPS below).
Each subagent receives:
  - Its sheet manifest entry (JSON)
  - The full text of its mapped review claim
  - The SUBAGENT PROMPT TEMPLATE below
  - Output path: `_qmd_tmp/chunk_<SHEET>.qmd`

Wait for all subagents before Step 4.

---

### STEP 4 — Validate chunks

For each `_qmd_tmp/chunk_<SHEET>.qmd`:
  - Confirm it contains: ## section header, context paragraph, ```{r} block(s),
    at minimum one ggplot2 call, and an interpretation sentence
  - If missing any element: re-dispatch that subagent once
  - If still malformed: write a placeholder chunk with a TODO note

---

### STEP 5 — Assemble .qmd

Write `OUTPUT_QMD` by assembling:

```
YAML front matter (see QMD TEMPLATE below)
Executive summary section
Sections in order: CRITICAL → MAJOR → MINOR → APPENDIX
  (each = one chunk file, pasted verbatim)
Session info appendix
```

Do not alter any R code inside chunks. Only the executive summary and
section-order scaffolding are written by the orchestrator.

---

### STEP 6 — Render

Run:
```bash
quarto render OUTPUT_QMD --to html
```

If render fails, capture stderr, identify the failing chunk by line number,
fix the R syntax error (do not change logic), and re-render once.

Report output HTML path and any chunks that required fixes.

---

### STEP 7 — Cleanup

Remove `_qmd_tmp/`. Keep `.qmd`, rendered `.html`, and `_files/` directory.

---

## SHEET-TO-CLAIM MAP

| Sheet | Analysis type | Maps to claim | Short label |
|-------|--------------|---------------|-------------|
| S1 | sequencing_qc | MC7 + OVERARCHING | Sample metadata & sequencing QC |
| S2 | snp_counts | OVERARCHING | SNP distribution by dataset |
| S3 | fst | MC4 | Fst coefficients — DGD outlier |
| S4 | species_delim | MC2 | BPP posterior probabilities |
| S5 | fixed_missense_genes | MC3 | Fixed missense gene catalogue |
| S6 | lineage_specific_missense | MC3 | Lineage-specific fixed missense |
| S7 | enrichment | MC3 | GO/KEGG enrichment — fixed missense |
| S8 | demographic | MC6 | fastsimcoal2 round 1 model selection |
| S9 | demographic | MC6 | fastsimcoal2 round 2 gene flow models |
| S10 | demographic | MC6 | fastsimcoal2 round 3 bottleneck models |
| S11 | ne_estimate | MC6 | Ne bootstrap confidence intervals |
| S12 | lof_genes | MC8 | Geneset I — LoF absent in DGD |
| S13 | enrichment | MC8 | GO/KEGG — Geneset I LoF |
| S14 | lof_genes | MC8 | Geneset II — LoF fixed in DGD |
| S15 | enrichment | MC8 | GO/KEGG — Geneset II LoF |
| S16 | lof_annotation | MC8 | High-confidence fixed LoF variants |
| S17 | kinship | MC1 (CRITICAL) | Kinship — DGD relatedness |
| S18 | divergence | MC4 | Evolutionary divergence matrix |

---

## SHEET GROUPS (for subagent consolidation)

Group sheets that share R setup or are interpreted together:
- **GROUP A** (kinship): S17 alone — highest priority, longest analysis
- **GROUP B** (fst + divergence): S3 + S18
- **GROUP C** (demographic): S8 + S9 + S10 + S11
- **GROUP D** (species delim): S4
- **GROUP E** (genetic load / LoF): S12 + S14 + S16
- **GROUP F** (enrichment): S7 + S13 + S15
- **GROUP G** (QC / SNPs): S1 + S2
- **GROUP H** (fixed missense): S5 + S6

8 subagents total (one per group).

---

## QMD TEMPLATE (front matter)

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
    number-sections: true
    theme: flatly
    code-fold: true
    code-summary: "Show R code"
    embed-resources: true
    fig-width: 8
    fig-height: 5
    fig-dpi: 150
    df-print: kable
execute:
  echo: true
  warning: false
  message: false
  cache: false
---
```

---

## SUBAGENT PROMPT TEMPLATE

Fill: `{{GROUP_ID}}`, `{{SHEETS}}`, `{{MANIFEST_JSON}}`,
`{{CLAIM_IDS}}`, `{{CLAIM_TEXT}}`, `{{EXCEL_PATH}}`, `{{OUTPUT_CHUNK}}`.

```xml
<task>
You are a computational biologist and biostatistician writing R analysis code
for a Quarto report. Your task is to analyze one or more supplementary tables
from a manuscript under peer review and produce a self-contained .qmd chunk
that plots the data and tests the statistical claims made in the peer review.

<group>{{GROUP_ID}}</group>
<sheets>{{SHEETS}}</sheets>

<manifest>
{{MANIFEST_JSON}}
</manifest>

<review_claim>
Claim IDs: {{CLAIM_IDS}}
Text:
{{CLAIM_TEXT}}
</review_claim>

<excel_path>{{EXCEL_PATH}}</excel_path>

<instructions>

## Your output

Write a single .qmd chunk file to {{OUTPUT_CHUNK}}.
The file must contain exactly:

1. A level-2 section header:
   ## <Claim ID>: <Short descriptive title>

2. A context paragraph (plain prose, no code, ~80 words):
   - What these tables contain
   - What the review claims about them
   - What the analysis will show

3. One or more ```{r} code blocks following the R CODING STANDARDS below

4. An interpretation paragraph (plain prose, ~60 words):
   - What the statistical result shows
   - Whether it supports or contradicts the review claim
   - What specific numbers (test statistics, p-values, effect sizes) mean

## R CODING STANDARDS

### Data loading
Always use readxl::read_excel() with explicit sheet name and skip= to skip
the merged title row (skip=1 for sheets with a title in row 0, skip=0 if
column names are in row 0). Strip whitespace from column names with
janitor::clean_names() or base trimws(). Coerce numeric columns explicitly.

```r
library(readxl); library(tidyverse); library(ggplot2); library(patchwork)
library(janitor); library(rstatix); library(ggpubr)
```

### Figure standards
- Use ggplot2 throughout. No base R plots.
- Theme: theme_bw(base_size=12) + theme(panel.grid.minor=element_blank())
- Color palette: use viridis or manually: DGD = "#E24B4A" (red), 
  mainland pops = "#378ADD" (blue), outgroup = "#888780" (gray)
- Highlight DGD explicitly in every comparison plot
- Add geom_hline or geom_vline for biologically meaningful thresholds
  (e.g. kinship 0.0884 = 2nd degree, 0.177 = 1st degree, 0.354 = MZ/dup)
- fig.cap="..." on each chunk with a complete figure caption
- One figure per chunk unless patchwork composite is cleaner

### Statistical tests (choose based on data structure)

**Kinship (S17):**
  - Kruskal-Wallis across all populations (non-parametric, n varies)
  - Post-hoc: Dunn test with Bonferroni correction (rstatix::dunn_test)
  - Effect size: epsilon-squared (rstatix::kruskal_effsize)
  - DGD-specific: report N pairs above each threshold (0.0884, 0.177, 0.354)
  - Compare: wilcox.test(DGD_kinship, non_DGD_kinship, alternative="greater")
  - Table: summary statistics per population (n, mean, median, max, n_related)

**Fst (S3):**
  - Plot all pairwise Fst as ordered dot plot, DGD labeled
  - Annotate intraspecific vs interspecific reference ranges
  - No formal test needed — descriptive comparison with annotated thresholds

**Demographic (S8/S9/S10):**
  - Recalculate AIC = 2k - 2*(-negLogL) where k = parameter count
  - Cross-check against reported AIC (flag discrepancies)
  - Plot: delta-AIC barplot per model, best model highlighted
  - S11: Ne estimates — boxplot or CI plot per parameter across 50 runs

**Species delim (S4):**
  - Table of posterior probabilities across BPP algorithm × prior combinations
  - Heatmap of PP values; annotate cells where PP < 0.95

**LoF annotation (S16):**
  - Bar chart of variant consequence types
  - Genomic distribution (chromosome × position strip)
  - Table of all 31+3 high-confidence variants with gene, consequence, chr

**Enrichment (S7/S13/S15):**
  - Horizontal barplot of top 15 terms by -log10(p-value)
  - Color by category (BP/MF/CC/KEGG)
  - Add FDR threshold line at 0.05 and 0.10 if no FDR column exists
    (note in caption that raw p-values are shown, FDR not reported in table)

**Sequencing QC (S1):**
  - Violin + jitter of coverage depth by population and dataset
  - Flag any samples below 10x depth

**Do not** run tests that require raw genotype data not in the Excel file.
**Do not** fabricate numbers. Read only from the Excel file.
**Do not** install packages — assume tidyverse, readxl, rstatix, ggpubr,
  patchwork, janitor, viridis, knitr, DT are available.

</instructions>
</task>
```

---

## EXECUTIVE SUMMARY TEMPLATE

The orchestrator writes this section after all chunks are assembled.

```markdown
## Executive Summary {.unnumbered}

This report analyzes {{N_SHEETS}} supplementary tables from Qi et al. against
{{N_CLAIMS}} peer review claims ({{N_CRITICAL}} critical, {{N_MAJOR}} major).
Each section loads data directly from the authors' supplementary Excel workbook,
applies appropriate statistical tests, and interprets results in the context of
the specific reviewer concern.

### Key findings at a glance

| Claim | Table(s) | Finding | Supports review? |
|-------|---------|---------|-----------------|
| MC1: DGD kinship (CRITICAL) | S17 | X of 20 DGD samples form ≥1st-degree kin clusters | ✓ Yes |
| MC4: Fst inflation | S3 | Fst range {{min}}–{{max}}; 0.473 not a lower bound for relevant comparisons | ✓ Yes |
| MC6: AIC inconsistency | S8–S10 | Recalculated AIC {{agrees/disagrees}} with reported ranking | TBD |
| MC6: Ne CIs | S11 | NBOTDGD 95% CI: {{lo}}–{{hi}} | Shown |
| MC2: BPP sensitivity | S4 | PP {{stable/variable}} across algorithm × prior | TBD |
| MC8: LoF annotation | S16 | {{N}} consequence types; inconsistencies flagged | TBD |
...

*Fill TBD cells after all subagents complete.*
```

---

## NOTES FOR ORCHESTRATOR

- Skip=1 for all sheets — row 0 is a merged title, row 1 is the column header
- S18 is a symmetric distance matrix — reshape to long format before plotting
- S8/S9/S10 are wide-format model-comparison tables — pivot longer before
  AIC recalculation; parameter count k must be inferred from non-NA rows
- For AIC: the sign of Lhood matters — these are negative log-likelihoods,
  so AIC = 2k + 2*(negLogL). Flag if reported AIC suggests they used +2*(negLogL)
  (correct) vs -2*(negLogL) (wrong sign) vs something else
- S11 has 50 bootstrap runs — use all 50 as the CI distribution, not the
  reported CI columns, so readers can see the full distribution
- Do not expose file paths in rendered HTML — use basename() in chunk labels
