---
name: write-clinical-note
description: Use when the user asks to write, complete, revise, or organize a behavioral-health client note or psychiatric EHR section, including "write a note," "help me complete this note," HPI/HOPI, Assessment/Impression, and Valant tabs. Applies in clinical-documentation context, not to unrelated personal notes.
---

# Write clinical notes

Turn supplied encounter information into tab-specific drafts in the user's HOPI and
Assessment/Impression style. Use the bundled DSM library as a clinical reference, with
diagnostic and final documentation decisions reserved for the responsible clinician.

## Load the right resources

- Read [workspace.md](references/workspace.md) for the included DSM indexes, notes and sources.
- Read [style.md](references/style.md) for narrative structure and the output example.
- Use [tabs.md](references/tabs.md) for the requested or supported EHR fields.

All reference paths are relative to this skill folder. Any model with file access can
use the Markdown library; Python lookup is optional. `agents/openai.yaml` supplies only
optional Codex metadata.

## Draft, then clarify

1. Identify new encounter versus prior-note update. Respect named tabs; otherwise draft
   **every supported tab**. Separate current reports, current observations, collateral,
   historical records, clinician conclusions, and intended versus completed actions.
2. For relevant diagnoses or diagnostic alternatives, retrieve the chapter overview,
   disorder note and key differentials. Read criteria, specifiers, coding and documentation
   cues; consult source pages for consequential ambiguities. Preserve an established
   clinician diagnosis without requiring a full diagnostic reassessment every follow-up.
3. Write paste-ready content under **exact tab labels**, in screenshot order. Each tab
   gets its own heading; do not merge `Plan` and `Plan - Med Changes`. Omit unsupported
   tabs by default. Keep reference citations, diagnostic checks and drafting instructions
   outside chart prose. Use supplied scores and clinical plans faithfully.
4. Follow drafts with **Questions to complete the note**, grouped by clinical priority.
   Ask only consequential unanswered questions; do not re-ask supplied facts or demand
   every optional field. For conflicting information, preserve both sources and ask for
   reconciliation. An explicit statement that an action did not occur can support a brief
   negative entry; silence cannot.
5. On reply, revise affected tabs and reconcile dependent sections. Keep unrelated
   completed content intact. Default to chat output; saving client content or entering
   it in an EHR requires the user's request for that action.

## Evidence boundaries

Use the examples' **structure and voice**, never their hypothetical facts. Do not add
normal MSE findings, denials, scores, risk levels, consent, safety-plan review,
psychotherapy, time, orders, doses or follow-up that were not supplied. Distinguish
“not provided” from a documented “not assessed” or explicit negative. Do not assume the
encounter date is today or carry forward old safety findings as current.

Support candidate diagnoses with actual duration, symptom count, function and exclusions;
keep unsupported diagnoses as considerations for clinician review outside the established
diagnosis list. Research conditions remain research conditions. A screener is not a
diagnosis, and an incomplete instrument is not a complete score. Keep proposed treatment
options distinct from recorded decisions and completed actions.

**Current safety concern:** briefly flag unresolved acute safety information before
routine drafting when it could affect immediate care; prioritize clarification and
clinician assessment. Do not manufacture a risk category, safety plan or disposition.
Complete supported sections without presenting the note as ready to sign while material
safety information remains unresolved.
