# DSM-5-TR Study Notes — Authoring Spec

These notes are a private study and lookup aid built from the user's own copy of the
DSM-5-TR. A clinical-documentation agent will use them later to act as a subject-matter
expert when writing client notes. Write for that agent and for a clinician who is studying:
accurate, dense and easy to scan.

## Source
- Chapter text files: `references/source/dsm5tr_text/NN-*.md (relative to this repository)`
- `<!-- pdf page N -->` markers give the PDF page. Cite pages as `(p. N)` with this PDF page number.
- Files are long, so use Read with `offset` and `limit` (about 800 lines at a time). Read the **whole**
  assigned range. Do not skim or guess from memory; the notes must reflect the TR text,
  including TR changes such as prolonged grief disorder, unspecified mood disorder and the
  updated ICD-10-CM codes.

## Copyright rule
Paraphrase. Do **not** copy the criteria or prose verbatim beyond short phrases of 12 words or
fewer. Encode criteria structurally: thresholds, counts, durations, exclusions and required
features, e.g. "≥5 of 9 sx, same 2-wk period, ≥1 must be depressed mood or anhedonia".
ICD-10-CM codes, disorder names and specifier names are fine to copy exactly.

## Output layout
Root: `references/dsm5tr/chapters/NN-chapter-slug/ (relative to this repository)`
(use the same NN-slug as the source file).

1. `_overview.md`: chapter spark notes
   - What unites the chapter and how its disorders differ (duration, timing, etiology)
   - Section map: every disorder in order with PDF pages, linking to its file
   - TR changes or notable updates mentioned in the text
   - Chapter-level pitfalls and differential logic: how to tell neighbours apart
   - Shared specifiers and coding conventions for the chapter
2. One file per diagnosable disorder: `<disorder-slug>.md`. "Other specified X" and
   "unspecified X" can share one file per chapter, `other-specified-and-unspecified.md`, that
   lists the example presentations. Substance/medication-induced and due-to-another-medical-
   condition variants get their own files when the chapter gives them full text.

## Disorder file template (follow exactly — the index is parsed from the front-matter)

```markdown
---
name: Major Depressive Disorder
aliases: [MDD, unipolar depression, clinical depression]
chapter: Depressive Disorders
chapter_dir: 07-depressive-disorders
pdf_pages: 302-318
icd10: ["F32.0", "F32.1", "F32.2", "F32.3", "F32.4", "F32.5", "F32.9", "F33.0", "F33.1", "F33.2", "F33.3", "F33.41", "F33.42", "F33.9"]
key_features: [depressed mood, anhedonia, sleep change, appetite/weight change, psychomotor change, fatigue, worthlessness/guilt, poor concentration, suicidal ideation]
min_duration: "2 weeks"
age_notes: "Any age; irritability may substitute for depressed mood in children/adolescents"
differentials: [Bipolar I Disorder, Bipolar II Disorder, Persistent Depressive Disorder, Prolonged Grief Disorder, Adjustment Disorder, Substance/Medication-Induced Depressive Disorder]
specifiers: [with anxious distress, with mixed features, with melancholic features, with atypical features, with mood-congruent psychotic features, with mood-incongruent psychotic features, with catatonia, with peripartum onset, with seasonal pattern]
---

# Major Depressive Disorder

> **Spark note:** 2–4 sentences: the essence of the disorder and the one thing people get wrong.

## Criteria at a glance
Structured paraphrase of every criterion (A, B, C…) with exact thresholds and exclusions.

## Specifiers & severity
How to specify, including severity anchors, course specifiers and remission definitions.

## Coding
A table of code → when to use it, including coding notes and recording order.

## Diagnostic features & clinical pearls
What the text emphasises and how it presents.

## Associated features
## Prevalence · Development & course · Risk & prognostic factors
Short bullets with key numbers.
## Culture- & sex/gender-related issues
## Suicide risk
Include it if the text discusses it; otherwise write "Not specifically addressed."
## Functional consequences
## Differential diagnosis
A bullet for each competitor and the discriminating feature.
## Comorbidity

## Documentation cues (for client notes)
- Observable/reportable evidence a clinician should record to support the diagnosis (mapped to criteria)
- Required rule-outs to document
- Phrases/MSE elements that support each criterion (written by you, not quoted)
```

Leave out any section the text doesn't cover, except Documentation cues, which every file needs.
Keep each file thorough but tight: typically 150–400 lines for major disorders and less for minor ones.

## Non-disorder chapters
For Section I, Section III and the Z-code chapters, use the same folder layout, but split
files by section or topic instead of by disorder. Put `name`, `chapter`, `chapter_dir`, `pdf_pages`,
`icd10` (if any) and `key_features` in the front-matter of each file, so the index still works.

## When done
Reply with a short summary of the files you created, one line per file, and anything ambiguous in the source.
Don't paste the notes back.


## Retrieval and review status
- These are source-grounded study drafts, not independently clinically validated material.
- A source-read claim must name the source/range actually read. Existing files do not prove a complete reread.
- `_coverage.md` records chapter coverage and gaps; it is not a diagnosis entry.
- Section III proposed conditions must be labeled research, and the alternative personality model must be identified.
- Codes reflect the supplied 2022 edition; verify applicable current rules before billing.
- Clinical examples are prompts to ask about or document actual evidence, never facts to insert into a client record.
- Rebuild with `python3 scripts/build_index.py references/dsm5tr`; malformed metadata must fail the build.
