# Using the DSM-5-TR study library for client notes

This library summarizes the supplied **APA DSM-5-TR, 2022** PDF. It supports study,
retrieval and clinician review. Reading these files does not establish clinical expertise
or validate an individual diagnosis. Source and coverage limitations are recorded in
[PROGRESS.md](PROGRESS.md) and [SOURCE_AUDIT.md](SOURCE_AUDIT.md).

## Retrieval workflow

1. Start with [INDEX.md](INDEX.md) or search locally:

   ```bash
   python3 scripts/lookup.py "PTSD"
   python3 scripts/lookup.py "F43.10"
   python3 scripts/lookup.py "sleep impairment" --json --limit 20
   ```

   Run commands from the skill root. JSON output returns metadata and paths; it
   does not replace reading the note. A failed lookup is not evidence that a condition
   does not exist. Try alternative spellings or the source chapter.
2. Open the chapter overview, the candidate note, and its principal differential notes.
   Inspect the entire Criteria, Specifiers, Coding and Documentation cues sections.
   Ambiguous acronyms can return several conditions. Symptom-match order is retrieval
   relevance, not diagnostic probability; prevalence and exclusion logic are not scored.
3. Check the cited PDF pages for threshold, duration, developmental, causal or coding
   decisions. PDF page numbers are **1-based positions in the file**, not the printed
   page numbers. The original PDF is `references/source/DSM 5 TR-APA (2022).pdf` at the skill root.
   Use the PDF page markers in the extracted chapter to locate the source.
4. Review other specified/unspecified categories and the chapter's coding conventions.
   A code appearing in metadata may describe an associated condition, differential or
   exclusion. It is not necessarily the code for the title diagnosis.
5. Keep Section III **conditions for further study** separate from established Section II
   diagnoses. The alternative personality model is a Section III framework. Behavior,
   contextual and adverse-effect codes do not all represent mental disorders.
6. For present-day billing or a question about later revisions, verify current official
   APA/ICD-10-CM materials. This library is intentionally bound to the 2022 source.

## Evidence rules for documentation

Use only client information actually provided for this encounter or identified records.
Separate client report, collateral report, direct observation and clinician inference.
Record dates and source when they matter. Do not convert a sample phrase in a study note
into an observed MSE finding, risk assessment, negative finding or historical fact.

For each candidate diagnosis, organize the assessment as:

| Item | Record from the encounter |
|---|---|
| Required features | Which symptoms are supported; source and examples |
| Count and timing | Number supported, onset, duration, frequency, episodic versus persistent course |
| Distress/function | Specific effects and setting; do not infer impairment from a label |
| Development/context | Age at onset, developmental baseline, cultural/language context where relevant |
| Exclusions | Substance/medication timing, medical explanations, competing disorders; what was actually assessed |
| Specifiers | Evidence for each proposed specifier and severity level |
| Uncertainty | Missing criterion evidence, contradictions, pending collateral or assessment |
| Diagnostic status | Clinician-established diagnosis versus differential or insufficient information |

Use **supported / contradicted / not assessed / unclear** for criterion evidence. Silence
is not a negative finding. Never fill gaps to reach a symptom count, infer a causal
medical relationship, or turn screening scores into diagnoses. A provisional diagnosis
has a specific meaning; lack of information alone does not justify assigning it.

Risk content in DSM study notes is background information, not a client-specific risk
formulation. Document only the assessment performed, findings, clinician judgment and
actual actions. Do not invent denial of ideation, absence of intent, protective factors
or a safety plan. Do not infer an individual's risk level from a diagnosis alone.

## Suggested assessment draft

> **Candidate / clinician diagnosis:** [name, status]. **Supporting evidence:** [reported
> or observed findings, timing, impairment]. **Differential:** [competing explanations
> and discriminating evidence]. **Information still needed:** [unassessed criteria and
> rule-outs]. **Specifiers/code for review:** [only those supported]. **Source checked:**
> [study note and PDF pages].

This is an internal drafting structure. Keep study references and unresolved prompts out
of finalized client prose unless the clinician wants them included. Final diagnostic and
coding decisions require the responsible clinician's review.

## Maintenance

```bash
python3 scripts/build_index.py references/dsm5tr
```

`index.json` includes names, aliases, chapter, source pages, code references, feature tags,
differentials, specifiers, duration, age notes, source edition and reference kind. `_coverage.md`
files describe chapter work and do not enter the lookup index. The index is a navigation
aid, not an automatic diagnostic engine or a claim of exhaustive clinical review.
