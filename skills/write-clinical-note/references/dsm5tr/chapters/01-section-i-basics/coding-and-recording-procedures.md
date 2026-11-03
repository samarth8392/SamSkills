---
name: Coding and Recording Procedures
aliases: [ICD-10-CM coding, recording procedures, diagnostic codes, coding notes, billing codes]
chapter: "Section I: DSM-5 Basics"
chapter_dir: 01-section-i-basics
pdf_pages: 103-104, 114, 116
icd10: ["F02.80", "F02.81"]
key_features: [ICD-10-CM official US system since Oct 1 2015, code precedes disorder name, coding notes for NCD and substance/medication-induced, Recording Procedures text section, alternative names in parentheses, ICD-11 not adopted in US, nonaxial recording]
---

# Coding and Recording Procedures

> **Spark note:** The **2022 source** describes the U.S. system at publication: the **only** permissible diagnostic codes for clinical use are **ICD-10-CM** (in effect since **October 1, 2015**). ICD-11 came into effect January 1, 2022 with country-specific adoption; the source reports **no** U.S. adoption timeline at publication. Most disorders have a code shown **before** the name. Some (neurocognitive, substance/medication-induced) need further specification and have **coding notes** and **Recording Procedures** you must follow. Diagnoses are recorded **nonaxially**, in order of clinical importance (pp. 103–104, 106, 116).

## Official system (pp. 103–104, 116)
- **ICD-10-CM** is the CDC/NCHS clinical modification of WHO ICD-10. It has been the U.S. standard since **10/1/2015** and gives the only permissible codes for mental disorders in U.S. clinical use.
- **At publication**, **ICD-11** was endorsed in May 2019 and took effect Jan 1, 2022. Each country picks its own adoption date, and the **U.S. has none proposed**, so ICD-10-CM stays the standard for the foreseeable future.
- Codes support record keeping, data retrieval and statistics, and reporting to third parties (government, insurers, WHO). Medicare reimbursement requires ICD-10-CM codes (the text cites the Health Care Financing Administration).

## Where codes appear (p. 116)
- The alphanumeric code comes **before** the disorder name (or before a coded subtype/specifier) in the Classification and in each criteria set.
- **Code depends on further specification** for some diagnoses (e.g., neurocognitive disorders, substance/medication-induced disorders). The criteria set gives a **coding note**, and the disorder's **"Recording Procedures"** text section sometimes adds detail.
- Some disorder names have **alternative terms in parentheses** (e.g., intellectual developmental disorder (intellectual disability)).
- Fifth-character coding of subtypes/specifiers happens only sometimes (F02.80 vs F02.81 example); most specifiers are written out after the name. See [subtypes-and-specifiers.md](subtypes-and-specifiers.md).

## Nonaxial recording (p. 106)
- DSM-IV Axes I, II and III are **gone**. Clinical disorders, personality disorders, intellectual developmental disorders and other medical conditions are **listed together**, without axis labels, **typically in order of clinical importance**.
- The old **Axis IV** (psychosocial/contextual) is replaced by **Z codes** (and some T/other codes) from "Other Conditions That May Be a Focus of Clinical Attention", listed with the diagnoses.
- The old **Axis V (GAF)** is replaced by the **WHODAS** (Section III); see [categorical-dimensional-and-assessment-tools.md](categorical-dimensional-and-assessment-tools.md).

## The "Recording Procedures" text section (p. 119)
- Present in many disorder texts. It explains how to **report the name**, choose the **ICD-10-CM code**, and apply **subtypes/specifiers**. Always check it for disorders with combination codes (substance-induced, NCD, due-to-AMC).

## Ordering rules (summary; details in linked files)
- **Principal diagnosis / reason for visit first**, then the rest in order of focus of attention and treatment ([principal-diagnosis-and-reason-for-visit.md](principal-diagnosis-and-reason-for-visit.md)).
- **Due to another medical condition (AMC):** the **medical condition code goes first**, then the mental disorder due to it, which is still the principal diagnosis even though it is listed second (p. 117).
- **"(provisional)"** goes after the diagnosis when applicable ([provisional-diagnosis.md](provisional-diagnosis.md)).

## Pitfalls
- Using DSM-IV axes or a GAF score in new documentation.
- Using ICD-11 codes in U.S. billing.
- Picking a code from the Classification list without reading the **coding note** (neurocognitive and substance-induced codes vary with comorbid use disorder, severity, etiology, etc.).
- Listing the mental disorder due to AMC **before** its etiological medical condition.
- Example codes in the text (F02.80/F02.81) reflect the 2022 edition. Disorder files in this library also summarize that edition; confirm current billing codes against official coding materials.

## Documentation cues (for client notes)
- **One diagnosis per line:** `ICD-10-CM code · full DSM name · subtype · specifiers · severity · qualifiers`.
- **No axes and no GAF.** If a function rating is wanted, cite the WHODAS 2.0 total/domain scores or describe function in words.
- **Psychosocial factors as Z codes** on their own lines after the mental disorders (e.g., housing instability, relationship distress), when they meet one of the four listing reasons (see [terminology-and-section-ii-conventions.md](terminology-and-section-ii-conventions.md)).
- **AMC example layout:**
  ```
  1. G30.9 Alzheimer's disease
  2. F02.__ Major neurocognitive disorder due to Alzheimer's disease, <specifiers> (principal diagnosis)
  ```
- **Substance/medication-induced:** record the **single combined code** that reflects comorbid use disorder status, per the coding note. Do not code the use disorder separately when the combined code already covers it (see the substance chapter files).
- **Recheck codes against the applicable current official code set** before billing; this library does not track later updates.
