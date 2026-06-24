---
name: interview-debrief
version: 1.0.0
description: >
  Use when given an interview transcript (or pre-interview prep request) plus
  a job ad, cover letter, candidate background docs, and optional company
  research materials. Dispatches parallel subagents across four lenses:
  job-fit alignment, clinical/technical accuracy, narrative & missed opportunities,
  and strategic question analysis. Synthesizes into a structured debrief .md with
  inline annotations, scored gaps, and a prep sheet for the next round.
  Trigger phrases: "debrief this interview", "interview prep", "annotate my interview",
  "what should I have said", "$interview-debrief".
skills_used:
  - superpowers:dispatching-parallel-agents
  - superpowers:subagent-driven-development
  - scientific-agent-skills:document-skills
  - scientific-agent-skills:markitdown
  - scientific-agent-skills:literature-review
  - scientific-agent-skills:scientific-writing
author: user
---

# interview-debrief

## Trigger

Activate when the user provides an interview transcript (or asks to prepare
for an upcoming interview) alongside a job ad and any subset of: cover letter,
resume/CV, company website, background PDFs, field-context documents.
Accepts both POST-interview debrief mode and PRE-interview prep mode.

---

## ORCHESTRATOR WORKFLOW

### STEP 0 — Collect inputs

Ask if not already provided:
1. `TRANSCRIPT` — interview transcript file (.txt / .md) or paste. Required for debrief mode.
   If absent, run in PRE-interview prep mode (skip annotation pass).
2. `JOB_AD` — full job posting text or file. Required.
3. `COVER_LETTER` — candidate's cover letter. Optional but improves alignment scoring.
4. `RESUME` — CV / resume file. Optional.
5. `COMPANY_DOCS` — website text, About page, any scraped or provided company materials.
6. `CONTEXT_DOCS` — field-relevant PDFs, articles, DSM excerpts, licensing body guidelines, etc.
7. `OUTPUT_PATH` — default: `interview_debrief_<YYYY-MM-DD>.md`
8. `MODE` — `debrief` (post-interview) | `prep` (pre-interview). Infer from inputs if possible.

Do not proceed until JOB_AD is confirmed.

---

### STEP 1 — Ingest and normalize

Convert all inputs to plaintext via `scientific-agent-skills:markitdown`.
Store:
- `_itmp/transcript.txt`
- `_itmp/job_ad.txt`
- `_itmp/cover_letter.txt`
- `_itmp/resume.txt`
- `_itmp/company.txt`      (concatenate all company docs)
- `_itmp/context.txt`      (concatenate all field-context docs)

Extract and store `_itmp/meta.json`:
```json
{
  "candidate_name": "<extracted or Unknown>",
  "role_title": "<from job ad>",
  "organization": "<from job ad>",
  "interview_date": "<from transcript or Unknown>",
  "interviewer": "<from transcript or Unknown>",
  "mode": "debrief | prep",
  "license_level": "<extracted from resume/transcript>",
  "modalities_mentioned": ["CBT", "..."],
  "populations_mentioned": ["adolescents", "..."],
  "key_requirements": ["<bullet-parsed from job ad>"]
}
```

---

### STEP 2 — Dispatch parallel subagents

Dispatch ALL 4 subagents simultaneously. Each receives only its own inputs
(no shared session context). Wait for all before Step 3.

**Subagent roster:**

| ID | Lens | Focus |
|----|------|-------|
| A1 | Job-Fit Analyst | Maps every stated requirement to transcript evidence; flags gaps |
| A2 | Clinical Accuracy Reviewer | Audits clinical/technical claims against field standards and context docs |
| A3 | Narrative & Missed Opportunity Analyst | Finds undertold stories, stronger framings, unsaid experiences |
| A4 | Strategic Questions Analyst | Evaluates questions asked/not asked; generates optimal question bank |

Output paths: `_itmp/analysis_A<N>.md`

---

### STEP 3 — Synthesize

Read all four `_itmp/analysis_A*.md` files.

Build a unified finding inventory:
- For each gap, annotation, or suggestion: record which subagent(s) raised it
- Classify by type: `[GAP]` `[STRONGER_FRAMING]` `[MISSED_STORY]` `[CLINICAL_NOTE]` `[QUESTION]`
- Score each finding: CRITICAL (affects hire decision) | NOTABLE | POLISH

Write raw inventory to `_itmp/synthesis.md` before Step 4.

---

### STEP 4 — Write final debrief

Write to `OUTPUT_PATH`. Use direct, collegial prose. No bullet clutter in
narrative sections. Be specific — cite transcript line/exchange, not vague sections.

#### Output structure

```
# Interview Debrief: <Role> at <Organization>
**Candidate:** <name>
**Date:** <date>
**Mode:** Debrief | Prep
**Reviewed by:** Multi-lens agentic panel (job-fit, clinical accuracy,
narrative, strategic questions)

---

## Executive Summary

<3 paragraphs: overall impression, single strongest moment, single most
critical gap. If CRITICAL gaps exist, name them here.>

---

## Job Requirements × Evidence Map

<Table: each stated requirement → evidence from transcript → gap rating>

| Requirement | Transcript Evidence | Gap |
|-------------|-------------------|-----|
| ... | ... | None / Partial / Missing |

---

## What Landed Well

<Prose. Specific exchanges that were effective. What made them work.
Quote the candidate's exact words (short) and explain why they were strong.>

---

## Annotation Pass — What Could Have Been Said

<This is the core section. For each notable exchange in the transcript:>

### Exchange: "<short label>"
**What was said:** <paraphrase of candidate's actual response>
**What was working:** <what was good about it>
**Gap / missed angle:** <what was left unsaid or underdeveloped>
**Stronger version (drawing from candidate's actual background):**
> <Draft of a stronger response using only the candidate's real experiences,
> modalities, populations, and documented achievements. Do not invent.>
**Type:** [GAP | STRONGER_FRAMING | MISSED_STORY | CLINICAL_NOTE]
**Severity:** CRITICAL | NOTABLE | POLISH

<Repeat for every significant exchange. Skip small talk.>

---

## Missed Stories — Experiences Not Surfaced

<Prose. Experiences visible in the resume/cover letter/context docs that
were not raised and would have been relevant. For each:
- What the experience is
- Where in the interview it fit naturally
- A one-paragraph bridge the candidate could have used>

---

## Clinical & Technical Accuracy Notes

<From A2. Any claims that need tightening, reframing, or additional precision
against field standards, licensing body requirements, or evidence-based practice
norms. Collegial — not adversarial.>

---

## Questions Asked — Assessment

<Evaluate each question the candidate asked the interviewer:
- What it signals about the candidate
- What it missed
- Stronger alternative if applicable>

---

## Questions You Should Have Asked

<Ranked list of 8–12 strategic questions the candidate should ask in the
next round. Each with: the question text, what it signals, what intel it returns.>

---

## Next Round Prep Sheet

<A single-page-equivalent cheat sheet:>

### Key messages to land (not yet landed)
<3–5 bullet points — specific claims to make, with the evidence to back them>

### Stories to prepare (STAR format cues)
<Each story: Situation cue | Task | what to emphasize in Action | Result to highlight>

### Terminology to use naturally
<Field terms, org-specific language from company docs, that signal fit>

### Red flags to address proactively
<Any gaps or ambiguities an interviewer might probe — with a suggested honest framing>

### Logistics and culture questions to resolve
<Open practical questions from this interview that need clarification>
```

---

### STEP 5 — Cleanup

Remove `_itmp/`. Report `OUTPUT_PATH` to user.

---

## SUBAGENT PROMPTS

Replace `{{TRANSCRIPT}}`, `{{JOB_AD}}`, `{{RESUME}}`, `{{COVER_LETTER}}`,
`{{COMPANY}}`, `{{CONTEXT}}`, `{{META}}`, `{{OUTPUT_PATH}}` with actual content.

---

### A1 — Job-Fit Analyst

```xml
<task>
You are a senior hiring consultant and career coach specializing in behavioral
health and clinical social work roles. Your task is to map every stated
requirement in a job ad against evidence in an interview transcript, then
identify gaps, mismatches, and unlevereaged strengths.

<job_ad>{{JOB_AD}}</job_ad>
<transcript>{{TRANSCRIPT}}</transcript>
<resume>{{RESUME}}</resume>
<cover_letter>{{COVER_LETTER}}</cover_letter>
<meta>{{META}}</meta>

<instructions>
Write your analysis to {{OUTPUT_PATH}} in Markdown.

Structure:
1. Requirements inventory (table: requirement → evidence → gap rating)
2. Unstated but implied requirements (read between the lines of the job ad)
3. Candidate strengths not surfaced in the transcript but visible in resume/cover letter
4. Alignment score per requirement: STRONG / PARTIAL / MISSING
5. Top 3 CRITICAL gaps that could cost the offer

Flag each finding: [CRITICAL] [NOTABLE] [POLISH]
Cite specific transcript exchanges by paraphrasing — do not quote at length.
Output ONLY the structured analysis. No preamble.
</instructions>
</task>
```

---

### A2 — Clinical Accuracy Reviewer

```xml
<task>
You are a licensed clinical supervisor and behavioral health educator with
deep knowledge of evidence-based modalities (CBT, DBT, ACT, TF-CBT,
MI, psychodynamic approaches), outpatient practice standards, US licensure
pathways (LMSW → LCSW-C / LCPC), and ethical practice guidelines.

<transcript>{{TRANSCRIPT}}</transcript>
<job_ad>{{JOB_AD}}</job_ad>
<context_docs>{{CONTEXT}}</context_docs>
<meta>{{META}}</meta>

<instructions>
Write your analysis to {{OUTPUT_PATH}} in Markdown.

Structure:
1. Clinical claims audit — for each clinical statement in the transcript:
   - What was said
   - Whether it is accurate, imprecise, or would benefit from elaboration
   - Suggested tighter or more clinically precise framing
2. Modality coverage — what was mentioned vs. what the job ad asks for
3. Population coverage — populations mentioned vs. required
4. Licensure pathway accuracy — did the candidate describe their supervision
   and licensure pathway correctly and compellingly?
5. Missed clinical vocabulary — terms or frameworks from the job ad or
   field context that the candidate did not use but should have

Flag each finding: [CRITICAL] [NOTABLE] [POLISH]
Do not invent clinical claims. Work only from transcript and context docs.
Output ONLY the structured analysis. No preamble.
</instructions>
</task>
```

---

### A3 — Narrative & Missed Opportunity Analyst

```xml
<task>
You are an expert interview coach and narrative strategist specializing in
helping candidates in clinical and nonprofit sectors tell compelling,
evidence-grounded stories. Your job is not to invent — it is to surface
real experiences the candidate has but failed to deploy effectively.

<transcript>{{TRANSCRIPT}}</transcript>
<resume>{{RESUME}}</resume>
<cover_letter>{{COVER_LETTER}}</cover_letter>
<company_docs>{{COMPANY}}</company_docs>
<job_ad>{{JOB_AD}}</job_ad>
<meta>{{META}}</meta>

<instructions>
Write your analysis to {{OUTPUT_PATH}} in Markdown.

Structure:
1. Exchange-by-exchange annotation:
   For each substantive exchange in the transcript:
   - Label the exchange
   - What the candidate said (paraphrase)
   - What was working
   - The missed angle or underdeveloped thread
   - A stronger version of the response using ONLY the candidate's
     documented real experiences (resume, cover letter, transcript)
   - Type tag: [STRONGER_FRAMING | MISSED_STORY | UNDERSOLD | OFF_TARGET]

2. Missed stories inventory:
   Experiences in the resume/cover letter that were never raised and
   would have been directly relevant. For each: where it fit naturally
   in the conversation, and a brief bridge paragraph the candidate could use.

3. Organizational mirroring gaps:
   Language, values, or themes from the company docs and job ad that the
   candidate did not reflect back, but should have.

Flag each finding: [CRITICAL] [NOTABLE] [POLISH]
Never fabricate experience. Build only from provided documents.
Output ONLY the structured analysis. No preamble.
</instructions>
</task>
```

---

### A4 — Strategic Questions Analyst

```xml
<task>
You are a senior executive recruiter and interview strategist. Your task is
to evaluate the questions a candidate asked during an interview, assess what
they signal and what they missed, and produce an optimal question bank for
the next round.

<transcript>{{TRANSCRIPT}}</transcript>
<job_ad>{{JOB_AD}}</job_ad>
<company_docs>{{COMPANY}}</company_docs>
<meta>{{META}}</meta>

<instructions>
Write your analysis to {{OUTPUT_PATH}} in Markdown.

Structure:
1. Questions asked — assessment:
   For each question the candidate asked:
   - The question
   - What it signals to the interviewer
   - What it missed or how it could be stronger
   - Revised version if applicable

2. Questions not asked but should have been:
   Rank 10–14 questions the candidate should prioritize in the next round.
   For each:
   - The question (ready to say verbatim)
   - Strategic purpose (what it signals about the candidate)
   - Intel value (what the answer reveals about the org)
   - Best moment to ask it (early / mid / closing)

3. Red flag topics to probe:
   Any ambiguities from this interview (caseload building clarity,
   supervision availability, compensation ceiling, growth timeline, etc.)
   that the candidate left unresolved and must address.

Flag each finding: [CRITICAL] [NOTABLE] [POLISH]
Output ONLY the structured analysis. No preamble.
</instructions>
</task>
```

---

## NOTES FOR ORCHESTRATOR

- Never carry subagent context into the synthesis step.
- Stronger-version responses in the Annotation Pass must draw exclusively
  from the candidate's documented real experiences. No invention.
- If transcript is absent (prep mode): skip Exchange annotation pass;
  expand Next Round Prep Sheet and Questions Bank into the primary output.
- If company website was not provided: web-search the organization name
  and role location before dispatching subagents; inject findings into
  `_itmp/company.txt`.
- Clinical accuracy notes should be collegial and constructive — frame as
  "here is a more precise way to say this" not "this was wrong."
- Do not fabricate transcript quotes. Paraphrase only.
- Score severity consistently: CRITICAL = affects hire decision;
  NOTABLE = meaningfully improves candidacy; POLISH = minor refinement.
