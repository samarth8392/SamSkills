# Narrative models and output contract

## Output

Use a separate heading for each supported tab, in the order in `tabs.md`, followed by
brief clinical prose or the tab's supplied structured values. Use only requested tabs
when the user narrows scope. Keep the draft easy to paste: no citations, model rationale,
instructional parentheticals or lists of unavailable fields inside otherwise complete
prose. When an uncertainty is clinically substantive, document it plainly with attribution.

End with **Questions to complete the note** for important missing information. If
none remain, omit that block. Group related gaps in a few concise questions, placing
safety, medication discrepancies and diagnostic/plan decisions first. Keep optional
screeners, generic histories and unused tabs from turning into a long intake checklist.
If the user explicitly requests every tab, label unsupported entries “Information not
provided” rather than inventing content; do not label them “not assessed” without evidence.

Use **Clinician review** outside the draft for unresolved candidate diagnoses, requested
new treatment suggestions, source-code caveats or reference citations. If a serious
current safety issue needs prompt attention, put a short clinician-priority flag first
and ask about the unresolved findings before treating the note as complete.

## HPI model

Source: [HOPI.txt](source/HOPI.txt). Write a cohesive chronological narrative, usually in short
paragraphs. Include the following **when supplied**:

1. Age, relevant sex/gender or pronouns, role/household, accompaniment, chief concern
   and history source. Use provided demographics; do not infer them.
2. Onset, precipitating context, evolution, frequency and duration of the symptoms.
3. Mood/anxiety and relevant sleep, appetite/weight, energy, concentration, cognition
   and other reported symptoms. Preserve quantities and temporal qualifiers.
4. Effects on work/school, relationships, home and activities, compared with baseline.
5. Actual safety-related reports and relevant positive/negative findings. Historical
   and present safety findings remain temporally distinct.
6. Relevant treatment/medication exposure, dose, duration, adherence, adverse effects,
   response and substance exposure. Attribute conflicts instead of selecting a dose.
7. Supplied interview observations, clearly separate from client-reported experience.

Do not reproduce the source model's empty field labels. Synthesize supplied material
without adding symptom negatives to make the paragraph look comprehensive. An explicit
verbatim chief concern may be quoted; paraphrases do not become invented quotations.

## Assessment - Impression model

Source: [Assessment Impression.txt](<source/Assessment Impression.txt>). Write a concise synthesis connecting
symptoms, time course, context and functional effect to the clinician's diagnosis or
carefully identified diagnostic uncertainty. Add supplied interview observations, relevant
co-occurring conditions and treatment response. Avoid merely repeating the HPI.

Retain clinician-established diagnoses and explicitly supplied severity/specifiers.
For new diagnostic reasoning, distinguish a supported syndrome from missing criteria
or exclusions. Place unestablished candidate diagnoses in the alternatives/review area;
do not silently turn a screening result or duration-limited presentation into a diagnosis.
Use the relevant DSM note to frame the questions that would discriminate alternatives.

Use evidence-based problem-status wording from the model when supported:

| Status | Anchor in actual encounter evidence |
|---|---|
| Improving | Less worry, better sleep, better attendance, or comparable measures |
| Well controlled | Supplied stable symptoms/function and clinician assessment |
| Resolved | Supplied resolution; do not infer tapering or medication decisions |
| Inadequately controlled | Continuing symptoms or impairment despite supplied treatment |
| Worsening | Specific new or increasing symptoms/impairment |
| Not changing as expected | Supplied expected response, interval and observed lack of change |

Include risk formulation, protective/risk factors, safety interventions, disposition
and follow-up only to the extent actually supplied. Absence of suicidal thoughts alone
does not establish “low risk.” A template's standard safety plan or consent wording is
not evidence those actions occurred. “Outpatient visit” does not prove outpatient
disposition was assessed as appropriate.

## Style across tabs

- Prefer precise clinical sentences with concrete time course and functional examples.
- Attribute client reports, collateral and direct observation where their distinction
  affects interpretation. Do not transform a report of feeling calm into observed affect.
- Put detailed chronology in HPI and histories, synthesis in Impression and decisions in
  Plan. Brief overlap can support independent EHR fields; avoid copying whole paragraphs.
- Preserve current versus past conditions, doses, sources and dates. Confirm carried-forward
  facts when needed; historical denial, consent or safety-plan review is not current.
- Preserve clinician decisions without adding medication adjustments, orders, consent,
  therapy techniques, psychotherapy minutes or disposition. Requested new suggestions
  belong in a clearly labeled clinician-review section.

## Synthetic example: sparse follow-up

Input: Established GAD. Client reports worry easing, sleeping 7 rather than 5 hours after
six weeks of escitalopram 10 mg daily, daily adherence without adverse effects, and better
work attendance. Clinician plan: continue current dose, review in four weeks. No current
safety or exam findings supplied.

### HPI

Client with clinician-established generalized anxiety disorder reports reduced worry
after six weeks of escitalopram 10 mg daily. Sleep has increased from 5 to 7 hours, and
work attendance has improved. Client reports daily adherence and no adverse effects.

### Meds & Allergies

Escitalopram 10 mg daily, per client report; reports daily adherence and no adverse effects.

### Assessment - Diagnoses

Generalized anxiety disorder, clinician-established.

### Assessment - Impression

Generalized anxiety disorder is improving by client report, with reduced worry, longer
sleep and improved work attendance during the current treatment interval.

### Plan

Per clinician plan, continue escitalopram 10 mg daily.

### Plan - Next Appointment

Follow up in four weeks.

### Questions to complete the note

- What were the current safety assessment and interview/MSE findings?
- What was the encounter date?

This example supplies neither a new prescription nor current risk or MSE findings.
Allergy information is absent, so it does not say “no known allergies.”
