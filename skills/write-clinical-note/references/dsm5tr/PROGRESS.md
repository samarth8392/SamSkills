# DSM-5-TR study-library progress

Session completed: **2026-10-15** (America/New_York). This is the restart point.

## Current result

The resumed draft library and navigation are complete at the chapter/section level. Full clinical source chapters were read across the assigned work, missing disorder/topic entries were authored, and existing notes received targeted source comparisons and corrections. The classification and both code appendices were also read and compared with the inventory. No substantive missing named diagnosis category remains identified; some closely related categories share a note. This is not independent clinical validation of every sentence.

- **291 disorder/topic notes**, **28 overview files** (including the retained substance Part 1 companion), and **27 chapter coverage records**: **346 chapter Markdown files** total.
- **27 chapter groups**, with Section I introduction/manual/forensic topics consolidated into one group.
- **319 indexed entries**, **687 distinct code references**, and **1,421 symptom/feature tags**.
- **All 1,377 PDF pages** have unique extraction markers across 40 source files; no missing or duplicated page markers.
- **8 regression tests passed**; final metadata, documentation-heading and relative-link checks found **0 structural issues**.

## Start here

- [Main study index](INDEX.md): chapter, A–Z, alias, code-reference and symptom lookup.
- [Agent guidance](AGENT_GUIDE.md): evidence rules and retrieval workflow for client-note drafts.
- [Classification navigation](reference/classification-navigation.md): grouped diagnoses, appendix routes and source discrepancies.
- [Source audit](SOURCE_AUDIT.md): omitted-page repair, image forms, source checks and limits.
- [Machine index](index.json) and [verification manifest](verification.json): metadata, counts, source SHA-256, chapter inventory and unlinked differential labels.

```bash
python3 scripts/lookup.py "PTSD"
python3 scripts/lookup.py "F90.0" --json
python3 scripts/build_index.py references/dsm5tr
```

Run commands from the skill root. `SKILL.md` directs agents to the included library.

## Where the interrupted work stood

The workspace had **199 chapter files**, three empty Section III folders, no generated main index and no durable progress ledger. Its 33 extracted files covered 1,256 PDF pages, leaving 121 omitted. The first build indexed 176 non-overview notes across 24 populated groups while skipping four malformed YAML headers. That count was incomplete and was not a count of DSM diagnoses. Source paths still pointed to another computer.

This session added **120 study/overview files plus 27 coverage records**, preserved and corrected earlier work, restored seven missing-page supplements, inspected the two image-only WHODAS forms, fixed metadata and discoverability issues, and built the indexes and lookup tool. Source extraction now runs with the available pypdf package into an empty destination; an actual full-PDF rerun independently reproduced complete page-marker coverage.

## Chapter coverage inventory

Every row has a `_coverage.md` recording actual source reading, corrections, ambiguities and limits. Source reading and targeted comparison do not amount to sentence-level clinical recertification.

| Chapter group | Disorder/topic notes | Overviews | Reading/coverage record |
|---|---:|---:|---|
| Section I: DSM-5 Basics | 16 | 1 | [Coverage](chapters/01-section-i-basics/_coverage.md) |
| Neurodevelopmental Disorders | 15 | 1 | [Coverage](chapters/04-neurodevelopmental-disorders/_coverage.md) |
| Schizophrenia Spectrum and Other Psychotic Disorders | 12 | 1 | [Coverage](chapters/05-schizophrenia-spectrum-and-other-psychotic-disorders/_coverage.md) |
| Bipolar and Related Disorders | 8 | 1 | [Coverage](chapters/06-bipolar-and-related-disorders/_coverage.md) |
| Depressive Disorders | 9 | 1 | [Coverage](chapters/07-depressive-disorders/_coverage.md) |
| Anxiety Disorders | 11 | 1 | [Coverage](chapters/08-anxiety-disorders/_coverage.md) |
| Obsessive-Compulsive and Related Disorders | 8 | 1 | [Coverage](chapters/09-obsessive-compulsive-and-related-disorders/_coverage.md) |
| Trauma- and Stressor-Related Disorders | 7 | 1 | [Coverage](chapters/10-trauma-and-stressor-related-disorders/_coverage.md) |
| Dissociative Disorders | 4 | 1 | [Coverage](chapters/11-dissociative-disorders/_coverage.md) |
| Somatic Symptom and Related Disorders | 7 | 1 | [Coverage](chapters/12-somatic-symptom-and-related-disorders/_coverage.md) |
| Feeding and Eating Disorders | 7 | 1 | [Coverage](chapters/13-feeding-and-eating-disorders/_coverage.md) |
| Elimination Disorders | 3 | 1 | [Coverage](chapters/14-elimination-disorders/_coverage.md) |
| Sleep-Wake Disorders | 13 | 1 | [Coverage](chapters/15-sleep-wake-disorders/_coverage.md) |
| Sexual Dysfunctions | 9 | 1 | [Coverage](chapters/16-sexual-dysfunctions/_coverage.md) |
| Gender Dysphoria | 3 | 1 | [Coverage](chapters/17-gender-dysphoria/_coverage.md) |
| Disruptive, Impulse-Control, and Conduct Disorders | 6 | 1 | [Coverage](chapters/18-disruptive-impulse-control-and-conduct-disorders/_coverage.md) |
| Substance-Related and Addictive Disorders | 52 | 2 | [Coverage](chapters/19-substance-related-and-addictive-disorders/_coverage.md) |
| Neurocognitive Disorders | 17 | 1 | [Coverage](chapters/20-neurocognitive-disorders/_coverage.md) |
| Personality Disorders | 13 | 1 | [Coverage](chapters/21-personality-disorders/_coverage.md) |
| Paraphilic Disorders | 9 | 1 | [Coverage](chapters/22-paraphilic-disorders/_coverage.md) |
| Other Mental Disorders and Additional Codes | 3 | 1 | [Coverage](chapters/23-other-mental-disorders-and-additional-codes/_coverage.md) |
| Medication-Induced Movement Disorders and Other Adverse Effects of Medication | 10 | 1 | [Coverage](chapters/24-medication-induced-movement-disorders-and-other-adverse-effe/_coverage.md) |
| Other Conditions That May Be a Focus of Clinical Attention | 25 | 1 | [Coverage](chapters/25-other-conditions-that-may-be-a-focus-of-clinical-attention/_coverage.md) |
| Assessment Measures | 4 | 1 | [Coverage](chapters/26-assessment-measures/_coverage.md) |
| Culture and Psychiatric Diagnosis | 3 | 1 | [Coverage](chapters/27-culture-and-psychiatric-diagnosis/_coverage.md) |
| Alternative DSM-5 Model for Personality Disorders | 10 | 1 | [Coverage](chapters/28-alternative-dsm-5-model-for-personality-disorders/_coverage.md) |
| Conditions for Further Study | 7 | 1 | [Coverage](chapters/29-conditions-for-further-study/_coverage.md) |

## Remaining boundaries and maintenance

- The 2022 edition is the source. Current official coding updates were not researched; metadata codes include associated conditions and differential references, so read the Coding section before selecting a code.
- Section III research proposals and the alternative personality model retain distinct reference kinds.
- Administrative contributor names and the book subject index are preserved as raw reference material rather than converted into disease notes. Printed index pagination is distinct from PDF positions.
- Source ambiguities are retained explicitly, including duration boundary wording, WHODAS work/school applicability and some classification/appendix code discrepancies. Consult the cited pages before resolving a consequential ambiguity.
- **346 differential labels remain plain text rather than linked** because labels can be broad groups, combined formulations, medical conditions outside DSM or unmatched wording. They are listed in verification.json; this is not a tally of missing DSM disorders.
- Clinical diagnosis and final client documentation require the responsible clinician. Never infer client findings from sample documentation prompts.

For later edits, read the relevant coverage record, use the source, rebuild the index, rerun tests and check local links. Record any new source gap here rather than silently marking it complete.
