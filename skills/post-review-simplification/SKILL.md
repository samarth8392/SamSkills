---
name: post-review-simplification
description: Simplify an existing multi-reviewer scientific peer review by rereading the source manuscript, verifying the prior critique, and retaining only publication-critical, feasible revision requests. Use after a full peer review already exists; do not use for a first-pass manuscript review.
---

# Post-review simplification

Turn an overgrown peer review into a short, favorable-where-justified review that protects scientific validity without expanding the revision into a new study. Treat the manuscript as the source of truth and the existing review as an issue inventory, not as a checklist that must survive.

## Required inputs

Identify:

1. The manuscript PDF or document.
2. Any supplementary files.
3. The existing full peer review, preferably Markdown.
4. The output folder, normally the folder containing those files.

When the user gives a folder rather than individual files, inspect it with absolute paths and identify the manuscript, supplement, and non-simplified review automatically. Do not ask the user to change directories. Ask only if multiple plausible manuscripts or reviews cannot be matched safely.

Default outputs are `<existing-review-stem>_simplified.md` and `<existing-review-stem>_simplified.pdf` in the same folder. Never overwrite the manuscript, supplement, or original review.

## Workflow

### 1. Reconstruct the evidence

- Read the existing review completely to learn what was previously criticized.
- Convert the manuscript and supplements to searchable text using the available document/PDF tooling, but also inspect the rendered PDF visually.
- Read the manuscript from beginning to end, including data availability, ethics, contributions, tables, captions, and supplements.
- Render and inspect every figure or table implicated by the old review. Text extraction is not sufficient evidence that a band, label, estimate, or table entry is absent.
- When the manuscript cites public accessions or other time-sensitive records, verify only the records relevant to a retained concern using authoritative sources. Cite the live record in the simplified review when it reveals a mismatch.

Record corrections to the old critique explicitly in the internal synthesis. Examples include uncertainty bands or numerical values that are visibly present, limitations the authors already acknowledge, and public records that are already available.

### 2. Run a constrained independent panel

If multi-agent review is available, dispatch six independent reviewers in parallel. This skill explicitly authorizes that delegation. Use domain lenses suited to the manuscript, while retaining statistical, computational/reproducibility, biological/application, and scientific-writing coverage. Give each reviewer the manuscript, supplements, original review, and relevant rendered figures.

Every reviewer must follow these constraints:

- Report no more than three essential issues.
- Re-evaluate the manuscript independently; do not inherit the old review's severity labels.
- Retain only issues supported by a precise section, figure, table, or external record.
- Prefer an existing-data check, correction, metadata repair, or narrower claim over a new experiment.
- Identify old-review requests that should be dropped or downgraded.
- Do not request new sampling, sequencing, a large comparative analysis, or major workflow infrastructure unless the main conclusion cannot be made reliable without it.

If subagents are unavailable, perform the same lenses sequentially and keep their findings separate until synthesis.

### 3. Apply the retention test

Keep a proposed major comment only when all four conditions hold:

1. It materially affects a main result, interpretation, ethical/provenance record, or management recommendation.
2. The concern remains after rereading the relevant source material and visually checking the evidence.
3. The requested remedy is feasible during an ordinary revision, preferably with existing data.
4. The manuscript has not already addressed the concern adequately.

Consensus indicates salience, not severity. Classify severity by scientific consequence. A scale-bar contradiction noticed by five reviewers can still be a minor factual correction; a single verified pipeline or archive contradiction may be essential. Do not call a flaw fatal when a correction, targeted reanalysis, or calibrated rewrite can resolve it.

Usually retain:

- Internal sample, feature-count, parameter, or figure/text contradictions.
- A primary analysis whose stated inputs or assumptions cannot produce the reported interpretation.
- Missing validation for the paper's central and unusual result when existing data can supply it.
- Public archive metadata that conflict with the Methods or analyzed dataset.
- Unsupported causal, temporal, safety, adaptation, or management claims.
- A small sensitivity analysis that directly tests whether the focal conclusion depends on one questionable choice.

Usually drop or downgrade:

- Concerns disproved by visual inspection.
- Analyses already qualified appropriately in the manuscript.
- Blanket requests for confidence intervals, power analyses, extra support statistics, or all possible model variants.
- Exhaustive software versions, containers, a new code repository, and every intermediate file when a few specific parameters or artifacts are enough.
- New fieldwork, broader sampling, new sequencing, or a different study design that would answer a new question rather than repair this paper.
- Genus-wide comparisons, matched reanalyses, selection scans, ecological models, or management programs that are useful future work but unnecessary for the submitted contribution.
- Copyediting and figure aesthetics as major scientific objections.

### 4. Synthesize before drafting

Create a temporary issue inventory containing:

- The reviewer count for each underlying issue.
- Exact manuscript evidence.
- Whether the old critique was confirmed, narrowed, or disproved.
- The smallest sufficient remedy.
- The final consequence-based severity.

Merge duplicate concerns across reviewer vocabulary. Limit the final review to one to four major comments; use more only when each independently passes the retention test. Aim for roughly 1,000-1,800 words and stay below 2,200 unless the retained science genuinely requires more.

### 5. Write the simplified review

Use this compact structure:

```markdown
# Peer Review: <title>

<Manuscript/journal/authors/date and accurate multi-reviewer disclosure>

## Overview
<Value, journal fit, recommendation, number of issues, and explicit statement that no fatal flaw was found when true.>

## Overarching Limitations
<Only limitations that actually constrain the submitted design.>

## Major Comments
### Major Comment 1: <actionable title>
<Evidence, consequence, and smallest sufficient revision.>

## Minor Comments
<Short numbered corrections.>

## Specific Comments
<Only necessary figure/table/proof corrections.>

## Writing, Clarity & Framing
<Claim calibration and a high-value rewrite only when useful.>

## Reproducibility & Methods Transparency
<Specific missing records, parameters, or provenance; reject infrastructure busywork explicitly when disproportionate.>

## Statistical Concerns
<Only analysis-specific concerns; state when blanket CI, power, or multiple-testing requests are unwarranted.>

<Short favorable-where-supported conclusion and explicit boundary on revision scope.>
```

Lead with the paper's contribution. Use collegial, direct prose. Do not repeat the same concern in multiple sections; cross-reference it briefly. State which large requests are not necessary when doing so protects the revision from scope creep. Preserve an accurate disclosure of agentic review involvement.

### 6. Editorial and artifact checks

Read the complete simplified draft start to finish. Remove severity tags, repetitive openings, canned transitions, redundant hedging, and uniform paragraph cadence without changing substance. Confirm that every retained claim matches the manuscript or cited external record.

Create a matching PDF using the available PDF skill/tooling. The PDF must have selectable text, clear headings, readable margins, page numbers, and no clipping. Extract its text to confirm all sections are present, render every output page, and inspect every page visually.

Report the final Markdown and PDF paths, the old and new word counts, the reduced number of major comments, and the main categories removed. Clean temporary extraction, reviewer, and rendering files after successful verification.
