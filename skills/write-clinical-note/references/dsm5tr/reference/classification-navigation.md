---
name: DSM-5-TR Classification and Appendix Navigation
aliases: [DSM-5-TR Classification, classification, alphabetical diagnosis listing, numerical diagnosis listing, coding appendix navigation]
chapter: Classification and Code Appendices
chapter_dir: reference
pdf_pages: "41-91; 1198-1250"
icd10: []
key_features: [chapter and diagnostic-family navigation, alphabetical name lookup, reverse code lookup, source coding discrepancies, printed versus PDF pagination]
---

# Classification and code appendix navigation

This reference connects the classification and both code appendices to the study library. These are navigation and coding aids, not additional disease chapters. A listed name or code does not establish criteria, a current billing code, or a diagnosis in a particular client.

## Source sections and local routes

| Source section | PDF positions read | Local lookup |
|---|---|---|
| DSM-5-TR Classification | 41–91 | [Extracted classification](../../source/dsm5tr_text/00-dsm-5-tr-classification.md); chapter routes below |
| Alphabetical listing | 1198–1226; listing begins 1199 | [Alphabetical code table](icd10-codes-alphabetical.md); [extracted source](../../source/dsm5tr_text/30-alphabetical-listing-of-dsm-5-tr-diagnoses-and-icd-10-cm-cod.md) |
| Numerical listing | 1227–1250; listing begins 1228 | [Numerical code table](icd10-codes-numerical.md); [extracted source](../../source/dsm5tr_text/31-numerical-listing-of-dsm-5-tr-diagnoses-and-icd-10-cm-codes.md) |
| Generated library navigation | Note-specific ranges | [Study index](../INDEX.md), [machine index](../index.json), [retrieval/evidence guidance](../AGENT_GUIDE.md) |
| Original subject index | Printed pagination | [Extracted book index](../../source/dsm5tr_text/supplement-book-index.md) |

The classification's parenthesized references are **printed book pages**, not PDF positions. For example, its somatic chapter entry says printed 349 on PDF p. 49; the chapter begins at PDF p. 515. Main-text offsets change across the book, so do not apply one global printed-to-PDF conversion. Use markers in the corresponding extracted chapter. Appendix running numbers such as 929/957 are also printed pages, not file positions (pp. 41, 49, 1198, 1227).

## How to find a named diagnosis or section

1. Search the [study index](../INDEX.md) or use `python3 scripts/lookup.py "full diagnosis name"` from the skill root. Codes and aliases are also searchable. Read the note after finding it.
2. If the source names a subtype, severity, induced cause or residual category, inspect its parent diagnosis/family note. One clinical entity can legitimately have many appendix rows; a separate note is not needed for every code/specifier.
3. If exact-name search fails, use shorter distinctive terms or the code. The lookup normalizes Unicode apostrophes/dashes; legacy names and combined-note titles may still require aliases or shorter queries. A failed search does not demonstrate absent content.
4. Use the alphabetical appendix for a name and numerical appendix for **all** associated labels. Cross-check the full disorder's coding/recording procedure, including sequencing and use-disorder status.
5. Keep proposed Section III research conditions and the alternative personality model separate from established Section II disorders. Contextual problems, adverse effects, specifiers and code-only entries are not automatically mental disorders.

## Chapter and section routes

The classification orders established diagnoses from neurodevelopmental through paraphilic disorders, followed by additional codes, medication effects and other clinical-attention conditions (pp. 41–91). Section I and Section III materials are routed here too, but do not become Section II diagnoses by being indexed.

| Library section | Overview / section navigation | Source chapter |
|---|---|---|
| Section I: DSM-5 Basics | [Overview](../chapters/01-section-i-basics/_overview.md) | [Extracted source](../../source/dsm5tr_text/01-introduction.md) |
| Neurodevelopmental Disorders | [Overview](../chapters/04-neurodevelopmental-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/04-neurodevelopmental-disorders.md) |
| Schizophrenia Spectrum and Other Psychotic Disorders | [Overview](../chapters/05-schizophrenia-spectrum-and-other-psychotic-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/05-schizophrenia-spectrum-and-other-psychotic-disorders.md) |
| Bipolar and Related Disorders | [Overview](../chapters/06-bipolar-and-related-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/06-bipolar-and-related-disorders.md) |
| Depressive Disorders | [Overview](../chapters/07-depressive-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/07-depressive-disorders.md) |
| Anxiety Disorders | [Overview](../chapters/08-anxiety-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/08-anxiety-disorders.md) |
| Obsessive-Compulsive and Related Disorders | [Overview](../chapters/09-obsessive-compulsive-and-related-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/09-obsessive-compulsive-and-related-disorders.md) |
| Trauma- and Stressor-Related Disorders | [Overview](../chapters/10-trauma-and-stressor-related-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/10-trauma-and-stressor-related-disorders.md) |
| Dissociative Disorders | [Overview](../chapters/11-dissociative-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/11-dissociative-disorders.md) |
| Somatic Symptom and Related Disorders | [Overview](../chapters/12-somatic-symptom-and-related-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/12-somatic-symptom-and-related-disorders.md) |
| Feeding and Eating Disorders | [Overview](../chapters/13-feeding-and-eating-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/13-feeding-and-eating-disorders.md) |
| Elimination Disorders | [Overview](../chapters/14-elimination-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/14-elimination-disorders.md) |
| Sleep-Wake Disorders | [Overview](../chapters/15-sleep-wake-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/15-sleep-wake-disorders.md) |
| Sexual Dysfunctions | [Overview](../chapters/16-sexual-dysfunctions/_overview.md) | [Extracted source](../../source/dsm5tr_text/16-sexual-dysfunctions.md) |
| Gender Dysphoria | [Overview](../chapters/17-gender-dysphoria/_overview.md) | [Extracted source](../../source/dsm5tr_text/17-gender-dysphoria.md) |
| Disruptive, Impulse-Control, and Conduct Disorders | [Overview](../chapters/18-disruptive-impulse-control-and-conduct-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/18-disruptive-impulse-control-and-conduct-disorders.md) |
| Substance-Related and Addictive Disorders | [Overview](../chapters/19-substance-related-and-addictive-disorders/_overview-part1.md) | [Extracted source](../../source/dsm5tr_text/19-substance-related-and-addictive-disorders.md) |
| Neurocognitive Disorders | [Overview](../chapters/20-neurocognitive-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/20-neurocognitive-disorders.md) |
| Personality Disorders | [Overview](../chapters/21-personality-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/21-personality-disorders.md) |
| Paraphilic Disorders | [Overview](../chapters/22-paraphilic-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/22-paraphilic-disorders.md) |
| Other Mental Disorders and Additional Codes | [Overview](../chapters/23-other-mental-disorders-and-additional-codes/_overview.md) | [Extracted source](../../source/dsm5tr_text/23-other-mental-disorders-and-additional-codes.md) |
| Medication-Induced Movement Disorders and Other Adverse Effects of Medication | [Overview](../chapters/24-medication-induced-movement-disorders-and-other-adverse-effe/_overview.md) | [Extracted source](../../source/dsm5tr_text/24-medication-induced-movement-disorders-and-other-adverse-effe.md) |
| Other Conditions That May Be a Focus of Clinical Attention | [Overview](../chapters/25-other-conditions-that-may-be-a-focus-of-clinical-attention/_overview.md) | [Extracted source](../../source/dsm5tr_text/25-other-conditions-that-may-be-a-focus-of-clinical-attention.md) |
| Assessment Measures | [Overview](../chapters/26-assessment-measures/_overview.md) | [Extracted source](../../source/dsm5tr_text/26-assessment-measures.md) |
| Culture and Psychiatric Diagnosis | [Overview](../chapters/27-culture-and-psychiatric-diagnosis/_overview.md) | [Extracted source](../../source/dsm5tr_text/27-culture-and-psychiatric-diagnosis.md) |
| Alternative DSM-5 Model for Personality Disorders | [Overview](../chapters/28-alternative-dsm-5-model-for-personality-disorders/_overview.md) | [Extracted source](../../source/dsm5tr_text/28-alternative-dsm-5-model-for-personality-disorders.md) |
| Conditions for Further Study | [Overview](../chapters/29-conditions-for-further-study/_overview.md) | [Extracted source](../../source/dsm5tr_text/29-conditions-for-further-study.md) |

## Diagnostic families that share a note or navigation route

| Source name / variant | Where to look | Distinction for retrieval |
|---|---|---|
| Intellectual disability; unspecified communication, ADHD, neurodevelopmental and tic diagnoses | [Developmental overview](../chapters/04-neurodevelopmental-disorders/_overview.md); [residual note](../chapters/04-neurodevelopmental-disorders/other-specified-and-unspecified.md) | Generic residual title covers multiple separately named categories |
| Schizotypal (personality) disorder | [Psychotic-spectrum overview](../chapters/05-schizophrenia-spectrum-and-other-psychotic-disorders/_overview.md); [personality overview](../chapters/21-personality-disorders/_overview.md) | Listed in both places; one disorder, not two independent diagnoses |
| Unspecified mood disorder (F39) | [Bipolar overview](../chapters/06-bipolar-and-related-disorders/_overview.md); [depressive overview](../chapters/07-depressive-disorders/_overview.md) | Repeated classification placement is intentional |
| PTSD in individuals older than 6; PTSD in children 6 and younger | [PTSD note](../chapters/10-trauma-and-stressor-related-disorders/posttraumatic-stress-disorder.md) | Separate developmental criteria sets share one note |
| Factitious disorder; imposed on self; imposed on another | [Self](../chapters/12-somatic-symptom-and-related-disorders/factitious-disorder-imposed-on-self.md); [another](../chapters/12-somatic-symptom-and-related-disorders/factitious-disorder-imposed-on-another.md) | The imposed-on-another diagnosis belongs to perpetrator, not victim |
| Breathing-related sleep disorders; central apnea; Cheyne-Stokes; hypoventilation | [Sleep overview](../chapters/15-sleep-wake-disorders/_overview.md) | Parent category, three disorders and their coded subtypes are different levels |
| Narcolepsy type 1/type 2 and medical-condition variants | [Narcolepsy](../chapters/15-sleep-wake-disorders/narcolepsy.md) | Four source codes share one disorder note |
| Delayed/advanced/irregular/non-24/shift-work circadian types | [Circadian note](../chapters/15-sleep-wake-disorders/circadian-rhythm-sleep-wake-disorders.md) | All subtype narratives are included in the family note |
| NREM arousals; sleepwalking; sleep terrors; sexsomnia | [NREM note](../chapters/15-sleep-wake-disorders/nrem-sleep-arousal-disorders.md) | Subtypes and specialized behaviors do not require separate disease files |
| Other specified/unspecified insomnia, hypersomnolence and sleep-wake disorders | [Six residual sleep categories](../chapters/15-sleep-wake-disorders/other-specified-and-unspecified.md) | Each named category has an explicit alias in this combined note |
| Alcohol/caffeine/cannabis/opioid/sedative/stimulant/tobacco/other-induced sleep disorder | [Induced sleep note](../chapters/15-sleep-wake-disorders/substance-medication-induced-sleep-disorder.md); [substance chapter](../chapters/19-substance-related-and-addictive-disorders/_overview.md) | Causal-class entries point to phenotype criteria; not all agents support every phenotype/onset |
| Drug-specific induced sexual dysfunction | [Induced sexual note](../chapters/16-sexual-dysfunctions/substance-medication-induced-sexual-dysfunction.md) | Agent/class and use-disorder severity select a combined code |
| Antisocial personality disorder under conduct disorders | [Personality chapter](../chapters/21-personality-disorders/_overview.md) | Classification cross-reference does not require duplicate disorder criteria in conduct chapter |
| Non-substance-related disorders | [Gambling disorder](../chapters/19-substance-related-and-addictive-disorders/gambling-disorder.md) | Parent category in classification p. 77 |
| Alcohol/cannabis/phencyclidine/hallucinogen/inhalant/opioid/sedative/stimulant/other intoxication, withdrawal or medication delirium | [Delirium](../chapters/20-neurocognitive-disorders/delirium.md); [substance overview](../chapters/19-substance-related-and-addictive-disorders/_overview.md) | Prescribed-medication delirium and intoxication/withdrawal variants require correct causal context |
| Substance/medication-induced major or mild neurocognitive disorder | [Induced NCD](../chapters/20-neurocognitive-disorders/substance-medication-induced-ncd.md) | Persistent NCD differs from acute intoxication and delirium; initial inventory gap now has a dedicated note |
| Major/mild and possible/probable Alzheimer’s, frontotemporal, Lewy-body, vascular, TBI, HIV, prion, Parkinson’s, Huntington’s, other/multiple etiologies | [Neurocognitive overview](../chapters/20-neurocognitive-disorders/_overview.md) | Etiological notes combine major/mild pathways and probability variants; shared codes do not establish etiology |
| Other specified/unspecified categories throughout Section II | Each chapter's residual note | Exact individual names may be aliases or headings within a combined note |
| Tardive dystonia and tardive akathisia | [Medication effects overview](../chapters/24-medication-induced-movement-disorders-and-other-adverse-effe/_overview.md) | Combined topic note; akathisia and acute drug-induced akathisia can share code |
| Suicidal behavior, NSSI, abuse/neglect, relational/contextual problems | [Clinical-attention overview](../chapters/25-other-conditions-that-may-be-a-focus-of-clinical-attention/_overview.md) | Confirmed/suspected, current/history, encounter stage and victim/perpetrator context matter |

## Coding lookup caveats and source discrepancies

- Blank classification code positions mean code depends on subtype, specifier or causal class; they do not mean no disorder exists. Due-to-medical-condition entries generally require the named cause first, with chapter-specific exceptions and NCD distinctions (pp. 41, 77–81).
- Multiple diagnoses can share one code, and one diagnosis can use multiple codes. Examples include F06.1 catatonia variants, F39 repeated mood placement, shared substance-induced bipolar/depressive codes, F43.8 prolonged grief versus residual trauma disorders, and G31.84 mild NCD etiologies. Search by code returns candidates, not a unique diagnosis (pp. 44–49, 56–81, 1229–1246).
- Induced-disorder code selection depends on same-class use disorder and severity. A combined induced code can incorporate that use disorder; do not automatically append a duplicate same-class use-disorder diagnosis (classification pp. 43–48, 53–54, 55–77).
- Contextual/adverse-effect code stems and encounter characters must be interpreted using the full entry; a partial T-code example is not a completed universal encounter code (pp. 83–88, 1247–1248).
- **Food insecurity:** extracted alphabetical source p. 1208 lists **F59.41**; classification p. 89 and numerical source p. 1248 list **Z59.41**. This is an internal discrepancy in the supplied extracted material; original-PDF typography was not rechecked here.
- **Opioid-induced anxiety:** extracted alphabetical p. 1212 and numerical p. 1231 list **F11.188 / F11.288 / F11.988**; classification pp. 64–65 uses **F11.180 / F11.280 / F11.980**. The appendix also assigns .188/.288/.988 to opioid-withdrawal delirium. Do not silently assume an appendix row resolves this conflict.
- **Exact words can differ between lists:** classification p. 90 says “Religious of Spiritual Problem”; alphabetical p. 1220 and numerical p. 1249 say “Religious or spiritual problem.” Treat this as a navigation spelling discrepancy, not a new condition.
- The source itself directs readers to periodic APA coding updates (pp. 41, 1199, 1228). These notes remain tied to the supplied 2022 edition. This task did not check later official code releases or billing requirements.

## Coverage and discoverability audit

Full supplied sources were read in sequential chunks: classification lines 1–2977 (1–400, 401–900, 901–1500, 1501–2100, 2101–2600, 2601–2977); alphabetical lines 1–2170 (1–550, 551–1100, 1101–1650, 1651–2170); numerical lines 1–1976 (1–500, 501–1000, 1001–1500, 1501–1976). PDF markers and printed numbering were kept distinct.

Comparison used the current chapter inventory and generated metadata index, plus an in-memory parse when files changed during collaborative work. The initially absent dedicated induced-NCD note was reported and subsequently appeared. Consolidated residuals, circadian types, NCD etiologies, substance-induced causal classes and contextual-code topics were treated as grouped coverage rather than missing diseases.

Added/fixed metadata aliases within chapters 12, 15 and 16 for residual categories, factitious parent naming, NREM typography, full narcolepsy subtype names, drug-induced sleep/sexual variants and comma-containing historical aliases. The maintainer then expanded metadata ownership: added class-specific psychotic, bipolar, depressive, anxiety and obsessive-compulsive induced names to chapters 05–09, both developmental PTSD criterion-set titles to chapter 10, and class-specific delirium titles to chapter 20. Other collaborators added developmental residual aliases and normalized Unicode apostrophes/dashes in lookup. An in-memory search of current metadata found routes for all single-line classification diagnosis headings tested; the remaining two unmatched strings were the non-substance-related parent heading (gambling disorder) and a wrapped parkinsonism-title fragment, not absent disorders. This automated check is not an exhaustive parser of every wrapped subtype or contextual-code phrase. Rebuild the index after alias changes; this navigation file does not itself alter lookup search logic.

Remaining limits: this is a classification/appendix navigation audit, not a fresh full-text clinical audit of every disorder. Completeness of a label-to-file route does not prove clinical completeness, current coding accuracy, or validity of any client diagnosis. The original PDF was not visually compared with every extracted appendix row. Existing transcription tables retain their own row/heading conventions; their differing row counts do not imply missing disorders.
