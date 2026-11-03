---
name: Subtypes and Specifiers
aliases: [subtype, specifier, "Specify whether", "Specify if", course specifiers, severity specifiers]
chapter: "Section I: DSM-5 Basics"
chapter_dir: 01-section-i-basics
pdf_pages: 113-114
icd10: ["F02.80", "F02.81"]
key_features: [subtypes mutually exclusive and jointly exhaustive, specifiers not mutually exclusive, Specify whether, Specify if, fifth-character coding, recorded after disorder name, current vs lifetime specifiers]
---

# Subtypes and Specifiers

> **Spark note:** **Subtypes** are mutually exclusive, jointly exhaustive subgroups ("**Specify whether**"), so you pick exactly one. **Specifiers** are neither ("**Specify**" / "**Specify if**"), so you may give none, one or several. Only a few subtypes and specifiers change the ICD-10-CM code. Most are written out after the disorder name. Most specifiers describe the current presentation and need full criteria to be **currently** met (pp. 113–114).

## Subtype vs specifier (p. 114)
| | Subtype | Specifier |
|---|---|---|
| Criteria-set instruction | "Specify whether" | "Specify" or "Specify if" |
| Logic | Mutually exclusive **and** jointly exhaustive: choose exactly one | Not mutually exclusive or exhaustive: may apply several or none |
| Example | Anorexia nervosa: restricting type vs binge-eating/purging type | Social anxiety disorder: performance only; MDD: with mixed features |

- **Purpose of both:** more diagnostic specificity, more homogeneous subgroups, and management-relevant information (e.g., the sleep-wake specifier *with other medical comorbidity*).

## Current vs lifetime specifiers (p. 113)
- **Current-presentation specifiers** (the majority) may change over time and **may be given only if full criteria are currently met**. Examples: insight level (*with good or fair insight*), ADHD *predominantly inattentive presentation*, *in a controlled environment*.
- **Lifetime-course specifiers** may be given **regardless of current status**. Examples: *with seasonal pattern*, schizoaffective disorder *bipolar type*.

## Effect on coding (p. 114)
- **Sometimes** the code's **fifth character** carries the subtype/specifier. The text's example is major neurocognitive disorder due to Alzheimer's disease: **F02.80** = without behavioural disturbance (5th char "0"), **F02.81** = with behavioural disturbance (5th char "1").
  - These are the source edition's example codes. The [neurocognitive chapter](../20-neurocognitive-disorders/_overview.md) also summarizes the 2022 edition; neither file verifies current billing codes. Check the applicable official code set before billing.
- **Usually** the subtype/specifier is **not** in the code and is **written after the disorder name**, e.g., "social anxiety disorder, performance only".

## Pitfalls
- Choosing two subtypes, or none, when the criteria set says "Specify whether".
- Assuming a specifier changes the billing code when it does not, or leaving out a code-changing specifier (check each disorder's coding note).
- Giving current-state specifiers to someone in partial or full remission when the criteria set does not allow it.

## Documentation cues (for client notes)
- **Recording format:** `<code> <Disorder name>, <subtype>, <specifier 1>, <specifier 2>, <severity>`. Write the subtype first, then the specifiers, in the order the disorder's Recording Procedures give (some disorders, such as MDD and the bipolar disorders, have a set order).
- **Justify each specifier** with one line of evidence mapped to its definition (e.g., record the person's actual degree of conviction and compare it with the disorder's insight definitions).
- **Use lifetime specifiers in maintenance notes.** A lifetime-course specifier stays in the diagnosis line even when the person is well.
- When full criteria are no longer met, **switch to the course/remission specifier** the criteria set provides. Do not keep using current-severity specifiers.
- Keep specifier wording **exact** (use the DSM specifier name) so coders and the next clinician can match it to the criteria set.
