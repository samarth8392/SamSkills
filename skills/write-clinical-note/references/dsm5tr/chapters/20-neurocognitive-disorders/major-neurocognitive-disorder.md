---
name: Major Neurocognitive Disorder
aliases: ["major NCD", "dementia"]
chapter: Neurocognitive Disorders
chapter_dir: 20-neurocognitive-disorders
pdf_pages: 915-928
icd10: ["F02.80", "F02.81", "F01.50", "F01.51", "R41.9", "G30.9", "G31.09", "G31.83", "S06.2X9S", "B20", "A81.9", "G20", "G10"]
key_features: [significant decline in ≥1 cognitive domain, concern from individual/informant/clinician, substantial objective impairment (~≥2 SD below norms / ≤3rd percentile), interferes with independence (needs help with IADLs at minimum), not exclusively during delirium, not better explained by another mental disorder]
min_duration: "None specified; must represent decline from prior level (acquired, not lifelong)"
age_notes: "Prevalence ~1–2% at 65 rising to ~30% by 85; childhood-onset NCD may warrant co-diagnosis of intellectual developmental disorder/other neurodevelopmental disorder"
differentials: [Mild Neurocognitive Disorder, Delirium, Major Depressive Disorder, Specific Learning Disorder, Intellectual Developmental Disorder, Schizophrenia, Malingering, Factitious Disorder, normal aging]
specifiers: [due to Alzheimer's disease, due to frontotemporal degeneration, due to Lewy body disease, due to vascular disease, due to traumatic brain injury, substance/medication-induced, due to HIV infection, due to prion disease, due to Parkinson's disease, due to Huntington's disease, due to another medical condition, due to multiple etiologies, unspecified etiology, without behavioral disturbance, with behavioral disturbance, mild, moderate, severe]
---

# Major Neurocognitive Disorder

> **Spark note:** Major NCD is DSM-5's name for dementia, but it is **broader**: decline in **a single domain** is enough, so amnestic disorder is now major NCD. It takes **both** a subjective concern and objective impairment, plus **loss of independence** (at minimum, needs help with complex IADLs such as bills or medications). The diagnosis is always given **with an etiology**, and the etiological medical condition is usually **coded first**. The usual errors are skipping the etiology code, or trying to code severity, which **cannot** be coded (record it in words). (pp. 915–917)

## Criteria at a glance (p. 916)
- **A. Significant decline** from a previous level in **≥1 domain** (complex attention, executive function, learning and memory, language, perceptual-motor, social cognition; see `neurocognitive-domains.md`). Both of the following are required:
  1. **Concern** from the individual, a knowledgeable informant **or** the clinician that cognition has declined significantly, **and**
  2. **Substantial objective impairment**, preferably on standardized neuropsychological testing. If testing is unavailable, use another quantified clinical assessment.
- **B. Function:** the deficits interfere with **independence** in everyday activities. At a **minimum**, the person needs **assistance with complex IADLs** (paying bills, managing medications).
- **C.** Not **exclusively** during a delirium.
- **D.** Not better explained by another mental disorder (e.g., MDD, schizophrenia).

## Specifiers & severity (pp. 916–917)
**Specify whether due to** one of 13 options, each with its own criteria set:
- Alzheimer's disease
- Frontotemporal degeneration
- Lewy body disease
- Vascular disease
- Traumatic brain injury
- Substance/medication use
- HIV infection
- Prion disease
- Parkinson's disease
- Huntington's disease
- Another medical condition
- Multiple etiologies
- Unspecified etiology

**Behavioral disturbance** (this specifier **is coded** for major NCD via the 5th character):
- **Without behavioral disturbance:** no clinically significant behavioural disturbance.
- **With behavioral disturbance (specify disturbance):** clinically significant psychotic symptoms, mood disturbance, agitation, apathy or other behavioural symptoms. **If more than one disturbance is present, name each one in writing** (p. 922).

**Current severity** (recorded, **not coded**):
- **Mild:** difficulty with **IADLs** (housework, managing money).
- **Moderate:** difficulty with **basic ADLs** (feeding, dressing).
- **Severe:** **fully dependent**.

**Associated psychiatric syndromes:** add separate code(s) for clinically significant psychiatric symptoms due to the **same** medical condition. Examples:
- F06.2 psychotic disorder due to Alzheimer's disease, with delusions
- F06.32 depressive disorder due to Parkinson's disease, with major depressive–like episode
- F06.34 bipolar and related disorder due to TBI, with mixed features

These "due to AMC" disorders sit in the chapters that share their phenomenology (e.g., depressive disorder due to AMC is in Depressive Disorders).

## Coding (pp. 916–920): TR coding rules
**Core rule:** code by **medical or substance etiology**. For most major NCDs, the **etiological medical condition code goes immediately BEFORE** the major NCD code.

**5th character (.x0 / .x1)** = behavioural disturbance:
- **x0** = without behavioral disturbance
- **x1** = with behavioral disturbance (psychotic, mood, agitation, apathy, other)

**Severity** (mild/moderate/severe) **cannot be coded** for major NCD but **must still be recorded**.

| Etiological subtype | Etiological medical code (code FIRST) | Major NCD code | Mild NCD code |
|---|---|---|---|
| Alzheimer's disease | G30.9 | F02.80 / F02.81 | G31.84 (no extra code) |
| Frontotemporal degeneration | G31.09 | F02.80 / F02.81 | G31.84 |
| Lewy body disease | G31.83 | F02.80 / F02.81 | G31.84 |
| Vascular disease | **None** (do not add a vascular code) | **F01.50 / F01.51** | G31.84 |
| Traumatic brain injury | S06.2X9S | F02.80 / F02.81 | G31.84 |
| Substance/medication-induced | None | Code by substance (see `substance-medication-induced-neurocognitive-disorder.md`) | Code by substance |
| HIV infection | B20 | F02.80 / F02.81 | G31.84 |
| Prion disease | A81.9 | F02.80 / F02.81 | G31.84 |
| Parkinson's disease | G20 | F02.80 / F02.81 | G31.84 |
| Huntington's disease | G10 | F02.80 / F02.81 | G31.84 |
| Another medical condition | Code the condition first (e.g., G35 multiple sclerosis) | F02.80 / F02.81 | G31.84 |
| Multiple etiologies | Code **all** etiological medical conditions first (**except** vascular disease) | F02.8x **once**, covering all etiologies that apply. **Code also** F01.5x if vascular is present, and the relevant substance/medication-induced major NCD if substances play a role | G31.84. Code also any relevant substance/medication-induced mild NCD |
| Unspecified NCD | None | **R41.9** | **R41.9** |

- **Mild NCD:** G31.84 for any medical etiology. The behavioural disturbance specifier **cannot be coded** but should be recorded. Do **not** add the etiological medical code.
- **Substance/medication-induced:** severity and behavioural disturbance specifiers cannot be coded but are recorded.

**Recording examples (p. 917):**
- *G30.9 Alzheimer's disease; F02.80 major neurocognitive disorder due to probable Alzheimer's disease, without behavioral disturbance, mild.*
- *S06.2X9S diffuse traumatic brain injury with loss of consciousness of unspecified duration, sequela; F02.81 major neurocognitive disorder due to traumatic brain injury, with behavioral disturbance, moderate; F06.34 bipolar and related disorder due to traumatic brain injury, with mixed features.*

**Recording template:** [etiological medical code + name]; F02.8x major neurocognitive disorder due to [probable/possible] [etiology], [with (specify)/without] behavioral disturbance, [mild/moderate/severe]; [any F06.x due-to-AMC psychiatric syndrome].

> Edition scope: these study notes reproduce this DSM-5-TR source’s coding conventions. Verify the applicable code set separately before billing.

## Behavioral specifier detail (pp. 921–922)
- **Psychosis:** common at the mild-to-moderate stage of major NCD due to AD, Lewy body disease and FTD.
  - If due to that disease, an additional diagnosis of psychotic disorder due to [AD / Lewy body disease / FTD] may be given.
  - Delusions are often **persecutory** (paranoia).
  - Unlike earlier-onset psychosis, **disorganized speech and behaviour are not characteristic**.
  - Hallucinations can be in any modality, but **visual hallucinations are more common** in NCDs than in mood or psychotic disorders.
- **Mood:** depression, anxiety, elation.
  - Depression is common **early** (even at the mild NCD level) in AD and Parkinson's. **Elation** is more common in FTD.
  - Can add depressive disorder due to AD/PD, or bipolar and related disorder due to FTD.
  - Mood symptoms are increasingly seen as a feature of the earliest mild-NCD stages.
- **Agitation:** disruptive motor or vocal activity, especially in moderate–severe major NCD. Often arises from confusion or frustration, or as **combative resistance to care** (bathing, dressing).
- **Sleep disturbance:** insomnia, hypersomnia, circadian disruption.
- **Apathy:** less motivation and goal-directed behaviour, with blunted emotional responsiveness. Common in AD and prominent in FTD. Can show early as lost interest in hobbies and daily activities.
- **Others:** wandering, disinhibition, hyperphagia, hoarding.

## Diagnostic features & clinical pearls (pp. 922–923)
- **Why both concern and testing are required:**
  - Tests alone miss high-functioning people whose "normal" score is a real decline, and wrongly flag people whose "low" score is their baseline or reflects test conditions or a passing illness.
  - Subjective report alone misses people with poor insight or informants who deny symptoms, and over-calls the "worried well".
- **Concern ≠ complaint.** It may need to be **elicited** with specific questions (e.g., can't remember a short grocery list or follow a TV plot; can't resume a task after an interruption, organize tax records or plan a holiday meal).
  - **Mild NCD:** tasks take more effort, time or compensation.
  - **Major NCD:** tasks need help or have been abandoned.
- The problem must be a **change, not a lifelong pattern**, and must be due to **cognitive** loss, not motor or sensory limits.
- **Neuropsych thresholds:**
  - **Major:** typically **≥2 SD below norms (≤3rd percentile)**.
  - **Mild:** typically **1–2 SD below norms (3rd–16th percentile)**.
  - Use norms for age, sex, education and culture, and prefer culturally validated instruments.
  - Thresholds depend on the test, norms, test conditions, sensory limits and intercurrent illness.
  - Bedside tools (Table 1) can supply objective data.
  - Interpret against **prior performance**. Norms are harder to apply at the extremes of education and outside the person's language or culture.
- **Criterion B:** in major NCD, **others must take over tasks** the person used to manage. The major/mild boundary is **arbitrary** (a continuum). Weigh what the diagnosis will mean for the person at the boundary.
- **Associated features** are subtype-specific (e.g., neuroleptic sensitivity and visual hallucinations in Lewy body disease).

## Prevalence · Development & course · Risk & prognostic factors (pp. 923–925)
**Prevalence:**
- Dementia is ~**1–2% at age 65** and up to **~30% by 85**.
- Mild cognitive impairment: **2–10% at 65**, **5–25% by 85**.
- Prevalence rises steeply after 60, so narrow age bands give better estimates.
- For life-span subtypes (TBI, HIV), prevalence is the fraction of people with that condition who develop NCD.
- Higher prevalence in **females** is largely, if not wholly, explained by longer life.
- **US incidence** (some studies), highest to lowest: African American > American Indian/Alaska Native > Latinx > Pacific Islander > non-Latinx White > Asian American.
  - Among Asian Americans: Filipino > Japanese > Chinese > Asian-Indian.
  - Caribbean Hispanic rates are much higher than Mexican American rates.

**Course** varies by subtype and helps with the differential:
- TBI and stroke: onset at a specific time, then static.
- Fluctuating: consider **superimposed delirium**.
- Neurodegenerative: insidious onset with gradual progression.
- Childhood-onset NCD may need a co-diagnosis of intellectual developmental disorder or another neurodevelopmental disorder.
- In late life, NCD is complicated by medical illness, frailty and sensory loss.
- Easiest to identify at younger ages, though malingering/factitious disorder may be a concern there. Very late in life, symptoms may go unnoticed.
- Mild NCD must be separated from **normal aging**, although much of what is called "normal aging" may be prodromal NCD.

**Risk:**
- **Age is the strongest risk factor**, through neurodegenerative and cerebrovascular disease.
- AD is uncommon before 60. FTD starts earlier and becomes a smaller share of NCD with age.
- Risk varies by ethnoracial group through hypertension, diabetes, head injury and environment (food access, safe places to exercise). African Americans and Latinx have higher vascular dementia risk than Whites.
- **Lower education and literacy** are risk factors, linked to social determinants of health.

## Culture- & sex/gender-related issues (pp. 925–926)
**Culture:**
- "Normalization" of decline as part of aging, and dementia **stigma**, delay recognition and help seeking. For example, stigma is linked to service underuse among Chinese American and Korean American groups.
- Decline is noticed sooner in people with complex jobs, households or hobbies.
- Norms may not fit people with less than high school education or those tested outside their primary language.
- Watch for **stereotype threat** in the test taker and **clinician implicit bias** in interpretation. Choose the testing language carefully for bilingual individuals.
- Bilingual people with dementia may **lose their acquired nonnative language**, which affects communication with caregivers.
- Under **filial piety** norms, adult children may take over tasks, which can mask the functional limitation.

**Sex/gender:**
- More women develop major NCD because they live longer, so a woman of a given age has a higher cumulative lifetime risk than a man. Incidence differences are less clear.
- Dementia incidence has **declined over 30 years** in several high-income countries, differently in men and women.
- Women show a broader range of symptoms, with more **depression, anxiety and delusions**. Men show more **aggression, apathy and vegetative symptoms**.
- Older women are more likely to live alone and to have more medical comorbidity.

## Diagnostic markers (p. 926)
- Neuropsychological assessment is the key measure, especially for mild NCD. It also guides support and gives a benchmark for later decline or treatment response.
- Global brief mental status tests are **insensitive** to modest single-domain change and in people with high premorbid ability, and **overly sensitive** in people with low premorbid ability.
- MRI/PET and subtype-specific markers help separate etiologies.

## Suicide risk (p. 927)
- Large studies show **elevated suicidal behaviour** in NCD across many etiologies.
- A Taiwanese nationwide study linked late-life suicide attempts with later dementia.

## Functional consequences (p. 927)
- Function is part of the definition and sets the major/mild threshold.
- Severity specifiers capture the range of impairment within major NCD.
- The specific functions lost can point to the domains affected when testing is unavailable.

## Differential diagnosis (p. 927)
- **Normal cognition / mild NCD:** the boundary is arbitrary. Use history, objective assessment and **longitudinal quantified testing**.
- **Delirium (persistent):** can co-occur. Assess **attention and arousal**. NCD alone has preserved arousal and stable attention early on, except in Lewy body disease.
- **Major depressive disorder:** AD shows **consistent** memory and executive deficits. Depression shows **nonspecific or variable** performance. Treating the depression and re-observing over time may be needed.
- **Specific learning disorder / neurodevelopmental disorders:** clarify baseline. NCD is a **decline**.
- **Other mental disorders** (schizophrenia, etc.): Criterion D. Cognitive deficits are present but are not the core feature.
- Subtype-specific differentials are covered in each etiology file.

## Comorbidity (pp. 927–928)
- Co-occurs with many age-related diseases.
- **Delirium** is the most notable: NCD increases risk, and an inpatient delirium is often when an NCD is **first noticed**, though history usually shows earlier decline.
- **Mixed NCD** is common in older adults.
- In younger people, NCD co-occurs with neurodevelopmental disorders (e.g., head injury in a preschool child).

## Documentation cues (for client notes)
- **A1 (concern):** quote the source (self/informant/clinician) and give **specific examples tied to a domain**, e.g., "daughter reports she repeats questions within the same conversation and lost track of medications (learning/memory)."
- **A2 (objective):** name the instrument and score (e.g., MoCA, MMSE, SLUMS or a neuropsych battery). Give percentile/SD versus age- and education-adjusted norms where available (≤3rd percentile / ≥2 SD supports major). Note education, primary language, sensory limits and test conditions.
- **Decline from baseline:** prior occupation, education and premorbid functioning, and the onset and tempo of change.
- **B (independence):** list the specific IADLs/ADLs taken over by others (finances, medications, driving, cooking → mild severity; dressing, feeding, toileting → moderate; total care → severe).
- **C:** record that attention and arousal are intact or stable, or that a delirium was ruled out (no acute medical cause, no fluctuation).
- **D:** screen for depression (PHQ-9/GDS) and psychosis, and explain why they do not account for the deficits.
- **Etiology:** state the etiology, its level of certainty (probable/possible) and the supporting evidence (imaging, genetics, course, neurological signs).
- **Behavioral disturbance:** name each disturbance, e.g., "with behavioral disturbance: persecutory delusions (stolen items), nighttime agitation, apathy."
- **Coding order:** etiological medical code → F02.8x/F01.5x → any F06.x due-to-AMC syndrome. Record severity in words.
- **Safety:** driving, firearms, wandering, financial exploitation, medication management, capacity concerns, caregiver burden, suicide screen.
