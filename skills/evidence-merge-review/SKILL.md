---
name: evidence-merge-review
version: 1.0.0
description: >
  Use when asked to merge quantitative evidence from a supplementary data
  analysis report (QMD/HTML) into an existing peer review HTML document.
  Dispatches parallel subagents to extract evidence per claim, then the
  orchestrator surgically injects evidence blocks into the correct locations
  in the peer review HTML, preserving all existing design and structure.
  Trigger phrases: "merge evidence", "connect the reports", "inject evidence",
  "update review with data", "$evidence-merge-review".
skills_used:
  - superpowers:dispatching-parallel-agents
  - superpowers:subagent-driven-development
  - scientific-agent-skills:document-skills
  - scientific-agent-skills:scientific-writing
author: user
---

# evidence-merge-review

## Purpose

The peer review document (HTML) makes claim-level arguments based on reading
the manuscript. The supplementary data analysis report (QMD/HTML) independently
loads the authors' own Excel data and runs statistical tests that confirm,
quantify, or extend each claim. This skill merges the two: every Major Comment,
Critical flag, and key Specific Comment in the peer review receives an inline
**Evidence block** drawn from the data analysis report, placed immediately
after the reviewer prose and before any next comment. The final output is a
single enriched peer review HTML that is self-contained, visually consistent,
and citation-linked.

---

## INPUTS

| Variable | Default | Description |
|---|---|---|
| `REVIEW_HTML` | `Peer Review — Macaque Island Genomics.html` | Target peer review HTML |
| `ANALYSIS_QMD` | `supp_analysis_report_interactive.qmd` | Source of extracted evidence |
| `ANALYSIS_HTML` | `supp_analysis_report_interactive.html` | Rendered analysis HTML (fallback) |
| `EXCEL_FILE` | `Supporting_Information-Tables.xlsx` | Raw data (for subagent re-computation) |
| `OUTPUT_HTML` | `Peer Review — Macaque Island Genomics — Evidence Merged.html` | Output |

Collect all before proceeding. Do not proceed if `REVIEW_HTML` or
`ANALYSIS_QMD` are missing.

---

## ORCHESTRATOR WORKFLOW

### STEP 0 — Ingest both documents

**Peer review HTML:**
Parse the HTML into a structured claim map. For each `<div class="major-card">`,
`<div class="section">`, and `<div class="spec-block">`, extract:
- `claim_id` — inferred from the card title (e.g. "MC1", "MC2", etc.)
- `claim_title` — the text inside `.major-card-title` or `.section-title`
- `severity` — from `.severity` badge text
- `reviewer_tags` — list of `R1`–`R5` tags present
- `prose` — the paragraph text in `<p>` within the card
- `dom_anchor` — a CSS selector or unique string that identifies exactly where
  in the HTML to inject the evidence block after

Store as `_emerge_tmp/claim_map.json`:
```json
[
  {
    "claim_id": "MC1",
    "claim_title": "DGD relatedness must be addressed before core inference",
    "severity": "CRITICAL · 5/5",
    "reviewer_tags": ["R1","R2","R3","R4","R5"],
    "prose": "Supplementary Table S17 reports high DGD–DGD kinship values...",
    "dom_anchor": "div.major-card:nth-of-type(1)",
    "section": "major"
  },
  ...
]
```

**Analysis QMD:**
Parse the QMD to extract the prose interpretation paragraph at the end of each
section (the summary sentence that cites exact numbers). Store as
`_emerge_tmp/analysis_map.json`:
```json
[
  {
    "section_label": "S17 Kinship - DGD Relatedness",
    "maps_to_claim": "MC1",
    "interpretation_paragraph": "The S17 results support the MC1 concern...",
    "key_statistics": [
      "190 DGD-DGD pairs total",
      "3 MZ/duplicate pairs (>= 0.354)",
      "6 pairs at or above first-degree threshold",
      "max kinship = 0.4729 (dgd3-dgd19)",
      "Kruskal-Wallis H, p < 0.0001",
      "One-sided Wilcoxon DGD > non-DGD, p < 0.0001"
    ],
    "audit_flags": [],
    "supporting_tables": ["S17"],
    "qmd_section_anchor": "#s17-kinship---dgd-relatedness"
  },
  ...
]
```

Store both maps before dispatching subagents.

---

### STEP 1 — Build the full claim-to-evidence mapping table

Use `_emerge_tmp/claim_map.json` and `_emerge_tmp/analysis_map.json` to
produce `_emerge_tmp/merge_plan.json`. This is the canonical assignment of
which analysis section populates which review claim, plus what HTML to inject.

Use the CANONICAL CLAIM→EVIDENCE MAP below as the authoritative assignment.
Do not infer mappings — follow the table exactly.

#### CANONICAL CLAIM→EVIDENCE MAP

| Review location | claim_id | Analysis section | Key stats to surface | Audit flags to surface |
|---|---|---|---|---|
| Major Comment 1 (CRITICAL) | MC1 | S17 Kinship | n pairs ≥ 2nd-degree, ≥ 1st-degree, ≥ MZ; max kinship; KW H & p; Wilcoxon p | None |
| Major Comment 2 (CRITICAL) | MC2 | BPP S4 | N cells < 0.95; PP stability across algorithms; CD vs DGD contrast | PP = 1.0 is model-conditional only |
| Major Comment 3 | MC3 | Enrichment S7 + Fixed missense S5/S6 | N terms with raw p < 0.05; N terms surviving within-table BH; FDR absent | No adjusted q-values, no background universe reported |
| Major Comment 4 | MC4 | Fst S3 + Divergence S18 | DGD-littoralis Fst = 0.278, DGD-lasiotis = 0.296; full Fst range | 0.473 is not a lower bound per S3 |
| Major Comment 5 | MC5 | Fst S3 | No dedicated analysis section; cite S3 DGD values as bounding evidence | |
| Major Comment 6 | MC6 | Demographic S8-S11 | N AIC mismatches of N total; best model by recalculated AIC per round; NBOTDGD 95% CI | AIC formula inconsistency confirmed across all 3 rounds |
| Major Comment 7 | MC7 | QC S1/S2 | N samples < 10x; N metadata fields absent; N non-integer S2 counts | Metadata fields absent: sex, age, sample type, collection date, troop |
| Major Comment 8 | MC8 | LoF S12/S14/S16 + Enrichment S13/S15 | Geneset I n genes; Geneset II n genes; ratio; S16 consequence labels present; indel-like labels found/absent | start_loss classification inconsistency |
| Overarching Limitations §1 | OVARCH1 | S17 + S3 | Kinship + Fst summary | |
| Overarching Limitations §2 | OVARCH2 | S17 | Pseudoreplication summary | |
| Overarching Limitations §3 | OVARCH3 | S8-S10 AIC | AIC inconsistency summary | |
| Overarching Limitations §4 | OVARCH4 | S1 | Reproducibility QC summary | |
| Reproducibility section | REPRO | S1 QC | Software versioning gaps; metadata gaps | |
| Statistical Concerns section | STATS | S8-S10 + S17 + S7 | AIC inconsistency; pseudoreplication; FDR absence | |
| Specific: Lines 170–179 / Fst | SPEC_FST | S3 | Exact DGD Fst values contradicting 0.473 lower bound claim | |
| Specific: Lines 416–438 / LoF purging | SPEC_LOF | S12/S14/S16 | Geneset sizes; demographic null argument | |
| Minor Comment 8 (non-integer SNPs) | MIN8 | S2 | N non-integer count fields; dataset location | |

---

### STEP 2 — Dispatch 6 parallel extraction subagents

Each subagent reads its assigned QMD sections and the EXCEL file to produce
a fully rendered HTML evidence block — a `<div class="evidence-block">` — for
each claim it owns. It does NOT modify the peer review HTML. It only outputs
HTML fragments.

**Subagent roster:**

| ID | Owns claims | QMD sections | Output |
|---|---|---|---|
| E1 | MC1, OVARCH1, OVARCH2, SPEC_KINSHIP | S17 | `_emerge_tmp/evidence_E1.json` |
| E2 | MC2, MC4, MC5, SPEC_FST | S4, S3, S18 | `_emerge_tmp/evidence_E2.json` |
| E3 | MC3, MC8, SPEC_LOF | S7, S13, S15, S5, S6, S12, S14, S16 | `_emerge_tmp/evidence_E3.json` |
| E4 | MC6, OVARCH3, STATS (AIC) | S8, S9, S10, S11 | `_emerge_tmp/evidence_E4.json` |
| E5 | MC7, REPRO, OVARCH4, MIN8 | S1, S2 | `_emerge_tmp/evidence_E5.json` |
| E6 | STATS (global) | All sections | `_emerge_tmp/evidence_E6.json` |

Each output JSON has the structure:
```json
[
  {
    "claim_id": "MC1",
    "evidence_html": "<div class=\"evidence-block\">...</div>",
    "inject_after_selector": "div.major-card:nth-of-type(1) > p",
    "confidence": "high"
  }
]
```

Wait for all 6 before Step 3.

---

### STEP 3 — Validate evidence blocks

For each evidence block:
- Confirm it contains at least one `<span class="ev-stat">` (a key number)
- Confirm it contains an `<a class="ev-link">` pointing to the analysis section
- Confirm it does NOT contain claims not in the source QMD interpretation paragraphs
- Confirm no fabricated numbers — all statistics must trace to the QMD

If any block fails: re-dispatch that subagent once with explicit instruction
to copy exact numbers from the QMD interpretation paragraph verbatim.

---

### STEP 4 — Inject evidence blocks into the peer review HTML

Load `REVIEW_HTML`. Parse DOM. For each evidence block in `merge_plan.json`,
find the injection point and insert the block HTML **after** the final `<p>`
inside the target card or section div.

Injection rules:
- `major-card` claims: inject immediately before the closing `</div>` of that `.major-card`
- `section` claims (Overarching, Repro, Stats): inject as the last child of
  the `.prose` div within that section
- `spec-block` claims: inject immediately before the closing `</div>` of that `.spec-block`
- `minor-item` claims: inject a `<span class="ev-inline">` at the end of the
  `<p>` within that `.minor-item` (inline, not block)

After all injections, add the **Evidence Legend** and **Global Stats Bar**
immediately after the `<!-- Verdict strip -->` comment and before the TOC div.

---

### STEP 5 — Inject shared CSS and JS into the `<head>`

Add the EVIDENCE BLOCK CSS (see below) into the existing `<style>` block in
the peer review HTML. Do not replace any existing CSS — append only.

Add the EVIDENCE JS (see below) before the closing `</body>` tag.

---

### STEP 6 — Write output and verify

Write the merged HTML to `OUTPUT_HTML`. Open and check:
- All `<div class="major-card">` elements now have a child `.evidence-block`
- The verdict strip still renders correctly
- The `#overview`, `#limitations`, `#major`, `#minor`, `#specific`, `#repro`,
  `#stats` section IDs are all intact
- The TOC `<a href>` links still resolve

Report path and a count of: claims injected, claims skipped (no evidence), any
fabrication warnings.

---

### STEP 7 — Cleanup

Remove `_emerge_tmp/`. Keep output HTML only.

---

## SUBAGENT PROMPT TEMPLATE

Fill: `{{AGENT_ID}}`, `{{OWNED_CLAIMS}}`, `{{QMD_SECTIONS}}`,
`{{QMD_TEXT}}`, `{{EXCEL_PATH}}`, `{{OUTPUT_JSON}}`.

```xml
<task>
You are a scientific writer and HTML developer. Your task is to read specific
sections of a supplementary data analysis report (provided as QMD source text)
and produce self-contained HTML evidence blocks for injection into a peer
review document. You extract real numbers from the QMD's interpretation
paragraphs, format them as evidence blocks matching the peer review HTML
design system, and output JSON.

<agent_id>{{AGENT_ID}}</agent_id>
<owned_claims>{{OWNED_CLAIMS}}</owned_claims>
<qmd_sections>{{QMD_SECTIONS}}</qmd_sections>
<excel_path>{{EXCEL_PATH}}</excel_path>
<output_json>{{OUTPUT_JSON}}</output_json>

<qmd_text>
{{QMD_TEXT}}
</qmd_text>

<instructions>

## What you must produce

For each claim in {{OWNED_CLAIMS}}, produce one JSON entry with:
- `claim_id`: the claim identifier (e.g. "MC1")
- `evidence_html`: a complete `<div class="evidence-block">` string (see template below)
- `inject_after_selector`: CSS selector of the peer review element to inject after
- `confidence`: "high" if numbers come directly from QMD interpretation paragraphs;
  "medium" if inferred from context; "low" if QMD section was not found

## Evidence block HTML template

```html
<div class="evidence-block">
  <div class="ev-header">
    <span class="ev-badge">Data Analysis Report</span>
    <span class="ev-tables">{{TABLE_IDS}}</span>
    <button class="ev-toggle btn btn-sm btn-secondary"
            onclick="toggleEvidence(this)"
            aria-expanded="true">Hide evidence</button>
  </div>
  <div class="ev-body">
    <p class="ev-summary">{{ONE_SENTENCE_SUMMARY}}</p>
    <div class="ev-stats-row">
      <!-- Repeat for each key statistic -->
      <div class="ev-stat-card">
        <div class="ev-stat-value">{{VALUE}}</div>
        <div class="ev-stat-label">{{LABEL}}</div>
      </div>
    </div>
    <!-- If audit flags exist -->
    <div class="ev-flags">
      <span class="ev-flag-label">Audit flags</span>
      <ul class="ev-flag-list">
        <li class="ev-flag-item ev-flag-confirmed">{{FLAG_TEXT}}</li>
      </ul>
    </div>
    <!-- Interpretation sentence verbatim from QMD -->
    <blockquote class="ev-quote">{{INTERPRETATION_PARAGRAPH_EXCERPT}}</blockquote>
    <a class="ev-link" href="{{ANALYSIS_HTML_ANCHOR}}" target="_blank">
      View full analysis →
    </a>
  </div>
</div>
```

## Population of each field

`{{ONE_SENTENCE_SUMMARY}}`:
Write ONE sentence that bridges the reviewer's claim to the data result.
Format: "Supplementary Table {{TABLE}} independently confirms that {{CLAIM}};
the data show {{RESULT}}."
Never start with "I" or "The analysis". Never add hedging beyond what is in
the QMD interpretation paragraph.

`{{VALUE}}` / `{{LABEL}}` pairs for ev-stat-cards:
Extract the most informative 2–4 numbers from the QMD interpretation paragraph.
Examples of good stat cards:
- Value: "0.4729" / Label: "Max DGD-DGD kinship"
- Value: "3 pairs" / Label: "MZ/duplicate (≥ 0.354)"
- Value: "0.278" / Label: "DGD–littoralis Fst (S3)"
- Value: "27/27" / Label: "AIC values disagree with reported"
- Value: "21 samples" / Label: "Below 10x depth (S1)"
Do NOT include stat cards for numbers not in the QMD text.

`{{FLAG_TEXT}}` — use these exact class labels per flag type:
- `ev-flag-confirmed` — the QMD analysis confirms the reviewer concern
- `ev-flag-discrepancy` — the QMD finds an internal inconsistency in the data
- `ev-flag-missing` — the QMD confirms data/metadata is absent
- `ev-flag-caution` — the QMD result needs additional qualification

`{{INTERPRETATION_PARAGRAPH_EXCERPT}}`:
Copy verbatim the final interpretation sentence from the relevant QMD section.
Maximum 3 sentences. Do not paraphrase. Do not add commentary.

`{{ANALYSIS_HTML_ANCHOR}}`:
Use the format `supp_analysis_report_interactive.html#{{SECTION_ID}}` where
SECTION_ID is the lowercased, hyphenated section heading from the QMD.

## Per-claim evidence specification

### MC1 — DGD relatedness [CRITICAL]
Source: QMD section "S17 Kinship — DGD Relatedness" interpretation paragraph.
Stat cards: max kinship, n MZ pairs, n first-degree-or-closer, Wilcoxon p-value.
Audit flags: none (data confirms concern directly).
inject_after_selector: `div.major-card:nth-of-type(1) > p`

### MC2 — Species status overstated [CRITICAL]
Source: QMD section "MC2: BPP posterior probabilities" interpretation paragraph.
Stat cards: N cells < 0.95, total cells, PP = 1.0 is conditional.
Audit flags: `ev-flag-caution` — "PP = 1.0 for DGD is consistent across all
parameter combinations but is model-conditional on the fixed A10 candidate
grouping, guide tree, and no-migration assumption."
inject_after_selector: `div.major-card:nth-of-type(2) > p`

### MC3 — Selection/purging claims need null models
Source: QMD sections "Group F enrichment" + "Group H fixed missense".
Stat cards: N S7 terms with raw p < 0.05, N surviving BH correction within
table, FDR reported (No), background universe reported (No).
Audit flags: `ev-flag-missing` — "No FDR-adjusted q-values, background
universe, gene-length correction, or duplicate-removal rules reported in S7,
S13, or S15."
inject_after_selector: `div.major-card:nth-of-type(3) > p`

### MC4 — Fst and divergence claims need correction
Source: QMD section "Major Comment 4: Fst and Pairwise Divergence".
Stat cards: DGD–littoralis Fst, DGD–lasiotis Fst, claimed lower bound 0.473,
overall Fst range min–max.
Audit flags: `ev-flag-discrepancy` — "Supplementary Table S3 contains DGD
comparisons below 0.473, directly contradicting the abstract's framing of
this value as a lower bound."
inject_after_selector: `div.major-card:nth-of-type(4) > p`

### MC5 — Gene-flow claims too categorical
Source: QMD section "Fst S3" (no dedicated section; cite bounding values).
Stat cards: DGD Fst range (min, max) across all S3 comparisons.
Audit flags: none (S3 does not directly test gene-flow directionality; note
the limitation in the summary sentence).
inject_after_selector: `div.major-card:nth-of-type(5) > p`

### MC6 — Demographic modeling not auditable [CRITICAL]
Source: QMD section "MC6 demographic-model audit: S8-S11".
Stat cards: N AIC mismatches of N total models, best model by recalculated
AIC for each round (S8/S9/S10), NBOTDGD 95% CI lower–upper.
Audit flags: `ev-flag-discrepancy` — "Recalculated AIC (2k + 2·negLogL)
disagrees with all 27 reported AIC values in S8–S10; the sign convention
and parameter-count procedure require clarification."
inject_after_selector: `div.major-card:nth-of-type(6) > p`

### MC7 — Sampling and conservation underdeveloped
Source: QMD section "Group G: S1 Sample Metadata/QC and S2 SNP Count".
Stat cards: N samples < 10x, N metadata fields absent of N requested,
N non-integer S2 count fields.
Audit flags: `ev-flag-missing` — "S1 is missing sex, age class, sample type,
collection date, and troop-level location for all 130 parsed sample rows."
inject_after_selector: `div.major-card:nth-of-type(7) > p`

### MC8 — LoF annotation pipeline inconsistent
Source: QMD section "Major Comment 8: Auditing LoF Consequence Classes".
Stat cards: Geneset I gene count, Geneset II gene count, ratio, N S16 consequence
labels, presence of indel-like consequence terms (yes/no).
Audit flags: `ev-flag-discrepancy` — "The S16 catalogue includes start_loss
among high-confidence fixed LoF classes, which conflicts with the low-impact
treatment of start_loss variants elsewhere in the supplementary."
inject_after_selector: `div.major-card:nth-of-type(8) > p`

### OVARCH1 — Overarching §1 (drift vs speciation narrative)
Source: MC4 and MC1 evidence. Short — 2 stat cards only.
inject_after_selector: `div#limitations .prose p:nth-of-type(1)`

### OVARCH2 — Overarching §2 (non-independence)
Source: MC1 / S17. Short — kinship max and n close-kin pairs only.
inject_after_selector: `div#limitations .prose p:nth-of-type(2)`

### OVARCH3 — Overarching §3 (statistical framework)
Source: MC6 / AIC. Short — N AIC mismatches.
inject_after_selector: `div#limitations .prose p:nth-of-type(3)`

### OVARCH4 — Overarching §4 (reproducibility)
Source: MC7 / S1. Short — N metadata fields absent, non-integer SNP counts.
inject_after_selector: `div#limitations .prose p:nth-of-type(4)`

### SPEC_FST — Specific: Lines 170–179 / Fst
Source: S3 values.
Short inline evidence: one ev-stat-card each for DGD–littoralis and DGD–lasiotis.
inject_after_selector: `div.spec-block:nth-of-type(7) > p`

### SPEC_LOF — Specific: Lines 416–438 / LoF purging
Source: S12/S14/S16 LoF section.
Stat cards: Geneset I vs II size; ratio.
inject_after_selector: `div.spec-block:nth-of-type(10) > p`

### MIN8 — Minor Comment 8 (non-integer SNP counts)
Source: S2 QC section. Inline only.
Format: `<span class="ev-inline"> — S2 audit confirms: {{N}} non-integer
count fields found, concentrated in Dataset II.</span>`
inject_after_selector: `li.minor-item:nth-of-type(8) p`

### REPRO — Reproducibility section
Source: S1 QC.
Stat cards: N software items missing version, N metadata fields absent.
Extra: add a pill row mirroring the peer review's existing pill row style,
inserting confirmed-missing items as `pill pill-missing` and items that were
present but partial as `pill pill-partial`.
inject_after_selector: `div#repro .prose p:last-of-type`

### STATS — Statistical Concerns section
Source: S8-S10 AIC + S17 kinship + S7 enrichment.
Stat cards: N AIC mismatches, pseudoreplication confirmed (yes/no),
FDR absent from enrichment tables (yes/no).
inject_after_selector: `div#stats .prose p:last-of-type`

## Rules

- Copy numbers VERBATIM from QMD interpretation paragraphs. Never round
  differently from what the QMD states.
- If the QMD does not report a number you need, mark the stat card value as
  "see analysis" — do NOT fabricate.
- Do NOT add any claim that is not in the QMD interpretation paragraphs.
- Do NOT editorialize beyond the QMD's own conclusions.
- Do NOT modify the reviewer's prose — your blocks are additions only.
- The `ev-quote` blockquote must be copied verbatim — not paraphrased.
- Output ONLY valid JSON. No preamble.

</instructions>
</task>
```

---

## EVIDENCE BLOCK CSS (append to existing `<style>` in peer review HTML)

```css
/* ── Evidence blocks ─────────────────────────────────────────────────── */
.evidence-block {
  margin-top: 1rem;
  border: 0.5px solid #b8d4f0;
  border-left: 3px solid #185fa5;
  border-radius: 10px;
  background: #f0f6fc;
  overflow: hidden;
  transition: box-shadow 0.18s ease;
}
.evidence-block:hover { box-shadow: 0 2px 10px rgba(24,95,165,0.12); }

.ev-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 0.6rem 1rem;
  background: #e6f1fb;
  border-bottom: 0.5px solid #b8d4f0;
}
.ev-badge {
  font-size: 10px;
  font-weight: 600;
  color: #185fa5;
  text-transform: uppercase;
  letter-spacing: 0.07em;
}
.ev-tables {
  font-size: 10px;
  color: #4a7ab5;
  background: #fff;
  border: 0.5px solid #b8d4f0;
  border-radius: 20px;
  padding: 1px 8px;
}
.ev-toggle {
  margin-left: auto;
  font-size: 10px !important;
  padding: 2px 8px !important;
}

.ev-body { padding: 0.85rem 1rem 1rem; }

.ev-summary {
  font-size: 13px;
  color: #1a3a5c;
  margin-bottom: 0.75rem;
  line-height: 1.6;
}

/* Stat cards row */
.ev-stats-row {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 0.75rem;
}
.ev-stat-card {
  background: #fff;
  border: 0.5px solid #b8d4f0;
  border-radius: 8px;
  padding: 0.5rem 0.85rem;
  min-width: 100px;
  flex: 1 1 100px;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
}
.ev-stat-card:hover {
  transform: translateY(-1px);
  box-shadow: 0 2px 8px rgba(24,95,165,0.1);
}
.ev-stat-value {
  font-size: 18px;
  font-weight: 500;
  color: #185fa5;
  line-height: 1.2;
}
.ev-stat-label {
  font-size: 10px;
  color: #666;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  margin-top: 3px;
}

/* Stat card variants for critical/confirmed values */
.ev-stat-card.ev-critical .ev-stat-value { color: #a32d2d; }
.ev-stat-card.ev-critical { border-color: #f7c1c1; background: #fcebeb; }
.ev-stat-card.ev-warn .ev-stat-value { color: #854f0b; }
.ev-stat-card.ev-warn { border-color: #fac775; background: #faeeda; }
.ev-stat-card.ev-ok .ev-stat-value { color: #0f6e56; }
.ev-stat-card.ev-ok { border-color: #9ed4c6; background: #e1f5ee; }

/* Audit flags */
.ev-flags {
  margin-bottom: 0.75rem;
  padding: 0.5rem 0.75rem;
  background: #fff;
  border: 0.5px solid #e0ddd5;
  border-radius: 8px;
}
.ev-flag-label {
  font-size: 10px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.07em;
  color: #888;
  display: block;
  margin-bottom: 0.35rem;
}
.ev-flag-list {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  flex-direction: column;
  gap: 4px;
}
.ev-flag-item {
  font-size: 12px;
  padding: 3px 0 3px 14px;
  position: relative;
  line-height: 1.5;
  color: #333;
}
.ev-flag-item::before {
  content: '●';
  position: absolute;
  left: 0;
  font-size: 8px;
  top: 5px;
}
.ev-flag-confirmed::before  { color: #3b6d11; }
.ev-flag-discrepancy::before{ color: #a32d2d; }
.ev-flag-missing::before    { color: #854f0b; }
.ev-flag-caution::before    { color: #185fa5; }

/* Verbatim quote from QMD */
.ev-quote {
  font-size: 12.5px;
  color: #444;
  border-left: 2.5px solid #b8d4f0;
  margin: 0.75rem 0;
  padding: 0.4rem 0.85rem;
  background: #f8fafd;
  border-radius: 0 6px 6px 0;
  font-style: italic;
  line-height: 1.65;
}

/* Link to full analysis */
.ev-link {
  font-size: 11px;
  font-weight: 500;
  color: #185fa5;
  text-decoration: none;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  margin-top: 0.25rem;
}
.ev-link:hover { color: #0c447c; text-decoration: underline; }

/* Inline evidence (for minor comments) */
.ev-inline {
  font-size: 12px;
  color: #185fa5;
  background: #e6f1fb;
  border: 0.5px solid #b8d4f0;
  border-radius: 4px;
  padding: 1px 6px;
  margin-left: 6px;
  white-space: nowrap;
}

/* Global evidence status bar */
.ev-status-bar {
  background: #fff;
  border: 0.5px solid #e0ddd5;
  border-radius: 10px;
  padding: 0.85rem 1.25rem;
  margin-bottom: 1.25rem;
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  align-items: center;
}
.ev-status-label {
  font-size: 11px;
  color: #888;
  text-transform: uppercase;
  letter-spacing: 0.07em;
  flex-shrink: 0;
}
.ev-status-pills { display: flex; flex-wrap: wrap; gap: 6px; flex: 1; }
.ev-status-pill {
  font-size: 11px;
  font-weight: 500;
  padding: 3px 10px;
  border-radius: 20px;
  border: 0.5px solid;
  white-space: nowrap;
}
.ev-status-confirmed { background: #eaf3de; color: #3b6d11; border-color: #c0dd97; }
.ev-status-discrepancy { background: #fcebeb; color: #a32d2d; border-color: #f7c1c1; }
.ev-status-missing { background: #faeeda; color: #854f0b; border-color: #fac775; }

/* Collapse animation */
.ev-body.collapsed { display: none; }
```

---

## EVIDENCE JS (append before `</body>`)

```html
<script>
/* Evidence block collapse / expand */
function toggleEvidence(btn) {
  var block = btn.closest('.evidence-block');
  var body  = block.querySelector('.ev-body');
  var open  = btn.getAttribute('aria-expanded') === 'true';
  body.classList.toggle('collapsed', open);
  btn.textContent     = open ? 'Show evidence' : 'Hide evidence';
  btn.setAttribute('aria-expanded', String(!open));
}

/* Animate stat-card values counting up on scroll */
(function() {
  var animated = new Set();
  function animateValue(el, end, duration) {
    var start = 0;
    var isFloat = String(end).includes('.');
    var decimals = isFloat ? String(end).split('.')[1].length : 0;
    var step = (end / (duration / 16));
    function tick() {
      start = Math.min(start + step, end);
      el.textContent = isFloat ? start.toFixed(decimals) : Math.floor(start);
      if (start < end) requestAnimationFrame(tick);
    }
    requestAnimationFrame(tick);
  }

  var obs = new IntersectionObserver(function(entries) {
    entries.forEach(function(e) {
      if (!e.isIntersecting) return;
      var el = e.target;
      if (animated.has(el)) return;
      animated.add(el);
      var raw = el.getAttribute('data-value');
      var num = parseFloat(raw);
      if (!isNaN(num)) animateValue(el, num, 900);
    });
  }, { threshold: 0.4 });

  document.querySelectorAll('.ev-stat-value[data-value]').forEach(function(el) {
    obs.observe(el);
  });
})();

/* Add data-value attributes to numeric ev-stat-values for the counter */
document.querySelectorAll('.ev-stat-value').forEach(function(el) {
  var txt = el.textContent.trim();
  var num = parseFloat(txt.replace(/[^0-9.]/g, ''));
  if (!isNaN(num) && txt.match(/^[0-9]/)) {
    el.setAttribute('data-value', num);
    el.textContent = '0';
  }
});
</script>
```

---

## GLOBAL STATS BAR HTML (inject after verdict strip, before TOC)

The orchestrator builds this block from the final counts across all injected
evidence blocks and inserts it into the peer review HTML:

```html
<div class="ev-status-bar">
  <span class="ev-status-label">Evidence status</span>
  <div class="ev-status-pills">
    <span class="ev-status-pill ev-status-confirmed">
      ✓ {{N_CONFIRMED}} claims confirmed by data
    </span>
    <span class="ev-status-pill ev-status-discrepancy">
      ✗ {{N_DISCREPANCY}} internal discrepancies found
    </span>
    <span class="ev-status-pill ev-status-missing">
      ⚠ {{N_MISSING}} missing data/metadata items flagged
    </span>
  </div>
  <a class="ev-link" href="supp_analysis_report_interactive.html" target="_blank">
    Open full data analysis report →
  </a>
</div>
```

---

## NOTES FOR ORCHESTRATOR

**On number fidelity:**
Every statistic in an evidence block must trace to one of:
(a) a verbatim number in the QMD interpretation paragraph, OR
(b) a number that the subagent recomputes by re-reading the Excel workbook.
If neither is available, the stat card value must read `"see analysis"`.
Violation of this rule is the only reason to re-dispatch a subagent.

**On DOM injection:**
The peer review HTML uses a handcrafted DOM — there is no JavaScript framework.
String-replace or BeautifulSoup-style parsing is acceptable. The nth-of-type
selectors in the claim map are 1-indexed and match the order of `.major-card`
divs in the `#major` section. Verify the count before injecting.

**On the Overarching Limitations section:**
The four paragraphs in `div#limitations .prose` correspond to the four
overarching themes in OVARCH1–OVARCH4. They do not have IDs — match by
paragraph position (1-indexed nth-of-type).

**On the Specific Comments section:**
Each `div.spec-block` has a `.spec-label` child with the line reference. Match
by label text content, not by nth-of-type, to be robust to reordering.
Example: `div.spec-block` where `.spec-label` contains "170–179".

**On Minor Comment 8:**
The `.minor-item` elements are `<li>` children of `.minor-list`. Match by
ordinal position (8th item). The injection is inline (`ev-inline` span),
not a block div, so it does not break the list layout.

**On the output file:**
The output HTML must be fully self-contained — no external stylesheets,
no CDN references beyond those already in the source peer review HTML.
All new CSS is injected into the existing `<style>` block.
All new JS is appended before `</body>`.
