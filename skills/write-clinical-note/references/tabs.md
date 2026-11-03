# EHR tab map

These **46 content-tab labels** follow [tabs.png](source/tabs.png) in screenshot order.
The screenshot also shows a final `Review` entry with a folder icon; its underlying
fields are not visible. Treat it as a review container until the user supplies its fields,
not an invented narrative tab or evidence of signature/completion. Ignore trash/folder
icons, “empty” markers and example dates. Use the exact content labels below.

Default: draft all supported fields and omit unavailable fields. A partially supported
tab may contain its supported facts; it need not list every missing subfield. Preserve
units and dates. Related fields can share brief facts where the EHR requires them, but
do not manufacture redundant encounters or duplicate entire narratives.

## Encounter and measures

| Tab label | Content and evidence needed |
|---|---|
| Header | Supplied encounter date, client identifiers and visit metadata. Never use an example identifier or assume today's date. |
| Places of Service - TCN | Supplied service setting, modality/location and any supplied TCN value. Do not infer a place-of-service code or the meaning of TCN. |
| Persons Present | Actual attendees, relationships/roles and history sources; an absent attendee is not an informant. |
| Chief Complaint | Client's supplied concern, quoted only when verbatim, otherwise concise paraphrase. |
| HPI | Chronological narrative using `style.md`: onset/course, symptoms, function, relevant safety/treatment and attributed observations. HOPI is the source filename; HPI is this tab's label. |
| Adult Symptom Screener | Actual instrument/version, date and supplied responses/results. No inferred completion or reconstructed responses. |
| PHQ-9 | Supplied dated score or complete responses scored using a verified method. Identify calculated versus supplied total. An omitted item prevents a complete calculated total; do not invent item 9 or use a partial sum as a total. |
| GAD-7 | Supplied dated score/responses, or calculated total from complete responses using a verified method. No inferred diagnostic conclusion or reconstructed items. |
| MoodQ | Supplied named instrument/version, responses and results. Do not assume a specific bipolar questionnaire or scoring scheme from this label alone. |
| ASRS-V1.1 | Supplied version, date, responses and scores. Do not conflate the screener with a clinical ADHD diagnosis. |
| Suicide Ideation Intensity | Supplied instrument/version, item responses, time frame and score. Do not guess the scale from the label, equate another measure's item with this scale or infer a risk level. |
| Review of Measures | Synthesis of actual measures and comparable changes; note incomplete results when relevant. Preserve differing measure dates; no trend from incomparable versions/informants. |

Screening calculations require all needed responses and a verified scoring method
available from provided material or an authoritative reference. Without it, preserve
responses/supplied total and ask, rather than inventing anchors or scoring thresholds.

## Stressors, histories and current clinical information

| Tab label | Content and evidence needed |
|---|---|
| Stressors | Supplied precipitants/current stressors, timing and connection to symptoms/function. Do not assume a stressor establishes adjustment disorder. |
| Review of Systems | Actual system-specific symptoms and explicit negatives asked/reported. Do not generate “all other systems negative.” Keep patient report distinct from examination. |
| Substance Use Hx | Substances, amount/frequency/route, onset/last use, prescribed exposure and abstinent intervals actually provided. No blanket denial from missing history. |
| Substance Use Consequences | Actual functional, medical, legal, interpersonal, intoxication/withdrawal effects or supplied explicit negatives. Exposure alone does not establish SUD criteria. |
| Inpatient Hx | Reported admissions, dates/reasons, course and outcomes, or actual denial. Do not infer from lack of records. |
| Outpatient Hx | Actual prior/current clinicians, therapy/programs, dates and response; separate treatment history from today's care. |
| Suicide/Self-Harm Hx | Reported past/current ideation, intent, attempts, nonsuicidal injury and dates. Distinguish historical behavior from current assessment. Avoid unnecessary procedural detail. |
| Violence Hx | Actual violent behavior, threats, homicidal thoughts, dates/context and supplied current findings. Irritability is not violence history. |
| Past Medical Hx | Supplied illnesses, procedures, neurological/developmental or relevant reproductive history. Do not write “unremarkable” or “none” from silence. |
| Psychiatric Med Hx | Historical trials, doses/duration, adherence, response, adverse effects and reasons stopped. Do not treat consideration of a drug as a past trial. |
| Patient Allergies | Actual allergen, reaction and certainty, or explicitly confirmed no-known-allergy status. An adverse effect is not automatically an allergy. |
| Meds & Allergies | Current medication reconciliation: name/dose/route/frequency when supplied, adherence/adverse effects and known allergy status. Preserve conflicting medication-list and client reports; do not choose a dose. |
| Family Hx | Supplied biological/other family psychiatric, substance, suicide and medical history with relationship/source. No assumptions about relatives. |
| Developmental and Educational Hx | Actual milestones, developmental concerns, learning/attention history, education, supports and functioning; preserve informant/source. |
| General Social Hx | Supplied household, relationships/supports, work, activities, legal/social circumstances and relevant identity/context. No inferred demographics. |
| Menstruation and Pregnancy Hx | Supplied clinically relevant menstrual, pregnancy/postpartum and reproductive information. Do not infer pregnancy status, anatomy, contraception or sexual history. |
| Vital Signs | Actual values, units, date/source. Self-reported weight change belongs in HPI unless an actual measurement is supplied. |
| Exam | Actual observed MSE and physical findings, with modality limits. A clinician's observation of linear thought process supports only that domain; no complete normal MSE expansion. |
| Lab Results | Actual test results, units/reference intervals if supplied, date and source. Separate ordered/pending tests from results; no invented normal labs. |

## Assessment and risk

| Tab label | Content and evidence needed |
|---|---|
| Assessment - Sources of Risk | Supplied sources/evidence used in risk formulation: client, collateral, records, observed findings, dated measures and discrepancies. This label does not establish a named risk scale. Distinguish evidence sources from risk factors in the next field. |
| Suicide Risk Factors | Supported individual factors and their current/historical context. Diagnosis alone does not establish an individual's risk level; do not invent access, intent or behavior. |
| Suicide Protective Factors | Actually elicited supports, reasons for living, engagement and other protective factors; employment, attendance or accompanying family alone does not prove protection. |
| Suicide Prevention Plan | Only actual reviewed/created safety-plan elements, participants, documented means-safety actions, contacts and follow-up. A proposed plan is not a completed intervention. An old plan is historical until current review is confirmed. |
| Assessment - Diagnoses | Clinician-established diagnoses and supported clinician-approved updates, with supplied specifiers/severity/code. New candidates without clinician confirmation belong in Alternatives or clinician review. Verify source-code meaning and mark current-billing uncertainty outside chart prose. |
| Assessment - Impression | Concise integrated formulation following `style.md`: syndrome/course/context/function, supplied observations and treatment response, supported status and clinical uncertainty. Include risk, safety actions and disposition only when supplied. |
| Assessment - Alternatives Considered | Actually considered or clearly proposed differentials, discriminating evidence and missing criteria. Distinguish the clinician's documented reasoning from candidate alternatives generated for review. Keep proposed research conditions clearly labeled. |
| Assessment - Informed Consent | Actual discussion, capacity/understanding, material risks/benefits/alternatives and decision/participants to the extent supplied. Medication use or attendance does not demonstrate consent. |

The precise field schema behind `Assessment - Sources of Risk` is not shown in the
screenshot. Use the source/evidence narrative above unless the user supplies its actual
form options. Likewise, do not invent checkbox states for any tab from its label alone.

## Care delivered and plan

| Tab label | Content and evidence needed |
|---|---|
| Counseling and Coordination of Care | Actual counseling topics, contacts, referrals, communication and response; distinguish discussion, planned contact and completed coordination. |
| Psychotherapy | Actual modality, targets, interventions, client response, progress and time when supplied. A supportive conversation or medication visit alone does not establish psychotherapy or billable time. |
| Plan | Clinician's actual management decisions, rationale and next steps. Keep planned actions prospective and completed actions past tense. Do not treat a recommendation as an executed order. |
| Valant Treatment Plan | Supplied goals, measurable objectives, interventions, responsible parties, frequency and review dates. If asked to develop new goals, label them proposed for clinician/client review. Do not assert treatment-plan agreement/signature. |
| Plan - Med Changes | Actual prescribed changes, starts/stops/tapers, dose/route/frequency and monitoring instructions. Continuation can remain in Plan; use this field for explicit changes or an expressly stated no-change decision. Clearly prospective future options belong in Plan. |
| Plan - Labs Ordered | Actual orders with test, indication and timing when supplied; distinguish planned from placed orders. Explicit “no orders placed” may be documented. An unspecified future lab discussion cannot become an order. |
| Plan - Next Appointment | Supplied date/interval, clinician/service and purpose. Follow-up intent is not a confirmed scheduled appointment unless supplied. |

End-of-draft review: names/dates/doses agree across tabs; current safety statements have
current sources; partial scales remain partial; considered, planned, ordered and completed
actions retain their status; the supplied material supports each populated heading.
For `Review`, report unresolved completion issues outside chart prose. Do not mark the
record reviewed, signed or submitted, or claim its unseen fields are complete.
