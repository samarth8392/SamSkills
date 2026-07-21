---
name: write-cover-letter
description: Use when writing, revising, or tailoring a cover letter for a specific AI/ML engineering job application using a CV/resume, job posting, portfolio site, and optional draft. Produces a print-ready HTML cover letter that is specific, technically credible, concise, and does not sound copied from the job ad.
skills_used:
  - docx
  - md-to-html
  - writing-skills
  - verification-before-completion
  - brainstorming
author: user
---

# Write Cover Letter (AI/ML Engineering)

## Purpose

Create or improve a job-specific cover letter that aligns the candidate's real
ML/AI engineering experience with an employer's stated needs. The result must
be concise, specific, technically accurate, persuasive, and grounded in
evidence from the CV, portfolio site, and project history — not a paraphrase
of the job ad.

## Project Paths (fixed)

All paths are relative to the project root:
`/Users/mathurs2/Documents/GitHub/cover_letters/ai_ml_eng`

| Purpose | Path |
|---|---|
| CV / resume | `./cv/` (or wherever the candidate's resume file lives — ask if not found) |
| Portfolio / project history (cloned GitHub site) | `./portfolio-site/` |
| Technical reference material (e.g. mlsysbook.ai, ML systems books) | `./reference/` |
| Cover letter CSS (print-ready HTML style) | `./cover-letter.css` |
| Job ad (pasted or file) | provided per-request |
| Output letters | `./output/` |

If any path is missing or empty, say so explicitly and ask before inventing
content to fill the gap. Never fabricate projects, metrics, tools, titles, or
dates that aren't in the CV or portfolio site.

If the CV or job ad arrives as a `.docx` file, use `docx` to extract text
before parsing — do not attempt to read the binary directly.

## Inputs

Use the available inputs in this order:

1. Candidate CV or resume (`./cv/`).
2. Job posting / job description (provided per-request).
3. Portfolio site content — read project READMEs, descriptions, tech stacks,
   and any written blurbs (`./portfolio-site/`).
4. Existing cover letter or draft, if provided.
5. Technical reference material for vocabulary and correctness checking
   (`./reference/`, e.g. mlsysbook.ai chapters on ML systems, deployment,
   RAG, LLM serving, etc.).
6. Target output format: print-ready HTML using `./cover-letter.css` unless
   the user asks for plain text or Markdown instead.
7. Any user preferences about tone, emphasis, word count, or file naming.

If a required input is missing, infer only what is safe from local context.
Do not invent credentials, degrees, certifications, tools, frameworks,
metrics, production claims, or dates not present in the CV or portfolio site.

## Core Workflow

### 1. Parse the job ad

Identify the top 5–7 requirements. Prioritize:
- Years of experience and seniority signals (e.g. "7+ years leading
  end-to-end ML/DL initiatives").
- Core technical stack: frameworks (PyTorch, TensorFlow), languages (Python),
  libraries (Pandas, NumPy, Scikit-learn).
- Systems/architecture requirements: LLMs, RAG, agent-based systems,
  production deployment, MLOps, cloud platforms (AWS/GCP/Azure).
- The employer's mission/values language and tone (mission-driven, healthcare,
  fintech, startup, enterprise, etc.) — note it, but do not mirror it back
  as flattery.
- Required vs. preferred qualifications — treat "preferred" items as
  differentiators, not blockers.

### 2. Map each requirement to evidence

Pull concrete evidence from the CV and portfolio site:
- Specific projects (name them), what was built, what stack, what scale,
  what outcome.
- Production/deployment experience: what was shipped, to how many users,
  what latency/reliability/cost result if documented.
- Model types and techniques actually used (e.g. fine-tuning, RAG pipeline,
  agent orchestration, feature engineering, evaluation harnesses).
- Cross-functional or leadership evidence (mentoring, cross-team
  collaboration, technical writing, open source).

Mark gaps as `[INSUFFICIENT EVIDENCE]`. Do not paper over a gap with vague
language — either find real evidence in the portfolio site or leave it out.

### 3. Sanity-check technical claims against reference material

Before finalizing any technical sentence in the letter (e.g. how RAG works,
what a model-serving pipeline involves, what "agentic system" implies),
cross-check terminology and framing against `./reference/` (mlsysbook.ai and
any other ML systems books present). The goal is correctness and fluency, not
padding the letter with book content:
- Use reference material to verify the candidate is using precise, current
  terminology (e.g. distinguishing retrieval-augmented generation from
  fine-tuning, or correctly describing training vs. inference infra).
- Do not cite or quote the reference books in the letter itself — they are
  for the agent's internal accuracy check only.
- If a claim in the draft is technically imprecise or outdated relative to
  the reference material, flag it and revise rather than leaving it be.

### 4. Decide the angle of the letter

Use `brainstorming` to generate 2–3 candidate professional theses before
committing to one, e.g.:
- "production ML systems generalist who takes models from prototype to
  deployment"
- "LLM/RAG systems builder with hands-on agent-based architecture experience"
- "ML engineer who bridges experimentation and reliable production
  infrastructure"

Evaluate each candidate against the job ad's top requirements (Step 1) and
the strength of available evidence (Step 2). Pick the one with the most
direct, well-evidenced fit — do not default to the first idea. State briefly
why the chosen angle beat the alternatives.

The angle should be justified by 2–3 pieces of hard evidence, not asserted.

### 5. Draft or revise the letter

Keep the final letter under 400 words unless the user asks otherwise.
Structure:
- **Opening**: role-specific motivation and fit — one sentence establishing
  who the candidate is technically, not "I am writing to express interest."
- **Body (2–3 paragraphs)**: evidence-based. Each paragraph should map to a
  cluster of related job requirements, backed by named projects, stack, and
  outcomes.
- **Closing**: concise interest and next step.

Preserve the candidate's authentic voice: technically confident, direct,
substantive — engineers write cover letters differently than they write
marketing copy. Avoid oversell.

Apply `writing-skills` to the draft before moving on: cut filler words, tighten
sentence structure, remove hedging language, and keep voice consistent
paragraph to paragraph. This is a prose-craft pass, separate from the
content/evidence work in Steps 1–4.

### 6. Remove generic phrasing and job-ad copyback

Avoid restating the employer's posting as praise. Replace anything that
sounds like a repackaged bullet list from the job ad with lived technical
reasoning grounded in the candidate's own projects.

Avoid empty enthusiasm and cliches, including:
- "I am writing to express my interest"
- "perfect fit"
- "passionate about AI"
- "exactly the kind of role"
- "cutting-edge technology"
- "your commitment to innovation"

### 7. Add quantified evidence where the CV/portfolio supports it

Include model performance numbers, latency/throughput figures, dataset
sizes, user/traffic scale, team size, or project timelines only when
documented in the CV or portfolio site. Qualify accurately — do not round up
scope or imply production ownership the candidate didn't have.

### 8. Match tone to the employer without imitating their language

- If the posting is mission-driven / healthcare-adjacent (e.g. "Caring.
  Connecting. Growing together."), keep the letter grounded in technical
  substance — do not adopt the company's mission language as if it were the
  candidate's own voice. One sentence acknowledging domain relevance (e.g.
  applying ML to health outcomes) is enough; do not mirror slogans.
- If the posting is heavy on MLOps/production language, foreground
  deployment and reliability evidence over research/experimentation.
- If the posting emphasizes research or novel methods, foreground modeling
  depth and experimentation rigor instead.

## AI/ML Engineering Letter Guidance

Emphasize only evidence the CV/portfolio supports:

- Years of hands-on ML/DL experience and what "end-to-end" actually covered
  (data → training → evaluation → deployment → monitoring).
- Specific frameworks and libraries actually used (PyTorch, TensorFlow,
  Scikit-learn, Pandas, NumPy, etc.) — never list a tool from the job ad that
  isn't in the CV.
- LLM/RAG/agent experience: describe the actual architecture built, not
  buzzwords. E.g. "built a retrieval pipeline over [X] using [Y] for
  chunking/embedding, serving via [Z]" rather than "experience with RAG."
  Verify this description is technically accurate per reference material.
- Production deployment experience: model serving, scaling, monitoring,
  CI/CD for ML, containerization, cloud platform specifics.
  - Cloud platform experience should be named accurately (AWS/GCP/Azure) and
    tied to a specific project.
- Data engineering: feature engineering, preprocessing pipelines,
  evaluation methodology, handling of data quality/drift.
- Cross-functional collaboration: translating business/product needs into
  ML systems, working with data/product/eng teams.
- Any open-source contributions, publications, or portfolio projects with a
  live link — reference these directly and specifically.

Do not invent: cloud certifications, specific production scale (users/QPS)
not documented, years of experience beyond the CV, degrees, or research
publications not listed.

## Avoid The "Job Description Costume"

A paragraph is wearing a job-description costume when it sounds like the
posting was paraphrased back to the employer.

Weak:

"I am especially drawn to your use of LLMs, RAG architectures, and agent-based
systems to build scalable ML solutions."

Stronger:

"Most of the LLM systems I've shipped needed a retrieval layer before the
model was trustworthy enough to put in front of users — that's the part of
RAG work I find most interesting: not the model call itself, but the
engineering around it that makes the output reliable."

Use the second style: grounded in the candidate's own technical perspective
and real project experience, not a list of the employer's selling points.

## Personal Touch

Add personal touch through technical judgment and engineering perspective,
not sentimentality.

Good personal lines:

- "I like ML systems work because the interesting failures are almost never
  in the model — they're in the data pipeline, the serving layer, or the
  monitoring gap nobody built yet."
- "I'm drawn to teams that treat production ML as a systems problem, not
  just a modeling problem."
- "The parts of this work I find most satisfying are the ones that don't
  show up in a demo: reproducibility, evaluation rigor, and graceful
  failure."

Use italics sparingly for a short belief line if it is a designed HTML
letter. Do not put the line in quotation marks unless it is a direct
quotation from someone else.

## HTML Cover Letter Workflow

When creating print-ready HTML cover letters:

1. Draft the letter body in Markdown first if it's easier to iterate on
   prose without fighting HTML structure. Use `md-to-html` to convert the
   final draft into HTML, then apply `./cover-letter.css`.
2. Use `./cover-letter.css` for styling. Preserve the existing design unless
   the user asks for layout changes.
3. Create a new suffix file per company, e.g.:
   - `output/FirstName_LastName_Cover_Letter_Print_optum.html`
   - `output/FirstName_LastName_Cover_Letter_Print_[company].html`
4. Edit content carefully within the existing HTML structure; link to
   `./cover-letter.css` rather than inlining styles unless the existing
   template already inlines them.
5. Keep dates, contact details, and formatting consistent with the
   candidate's existing materials unless instructed otherwise.
6. Validate the HTML after editing:

```bash
xmllint --html --noout path/to/letter.html
```

7. Check word count for the main letter body when the user requests a limit:

```bash
textutil -convert txt -stdout path/to/letter.html | wc -w
```

Use the repo's available tools if these commands are unavailable.

## Useful Searches

Find generic or copied-sounding language across letter files:

```bash
rg -n "role calls for|responsibilities align|exactly the kind|What attracts me most|I am especially drawn|commitment to|passionate|perfect fit|cutting-edge" *.html
```

Search the portfolio site for relevant project evidence before drafting:

```bash
rg -n "RAG|LLM|PyTorch|TensorFlow|deploy|pipeline|agent" ./portfolio-site/
```

Search reference material to verify technical terminology before finalizing:

```bash
rg -n "retrieval-augmented|fine-tun|inference|model serving" ./reference/
```

## Output Format

When the user asks for a full cover-letter creation or improvement, provide:

1. Requirement-to-evidence table (job requirement → CV/portfolio evidence →
   gap flag if any).
2. Revised/new cover letter (HTML, using `./cover-letter.css`).
3. Three brief notes explaining the strongest technical matches used and any
   `[INSUFFICIENT EVIDENCE]` gaps the candidate may want to address.

When the user asks to edit files directly, update the files and summarize:

- Files changed.
- Main content improvements.
- Technical claims verified against reference material.
- Validation performed (HTML lint, word count).

## Verification Before Completion

Before declaring the letter done, run `verification-before-completion` against
these checks — do not self-certify without going through them explicitly:

- The letter is specific to this employer and role.
- Every technical claim is supported by the CV or portfolio site — nothing
  invented.
- Every technical claim reads as precise and current, cross-checked against
  reference material where relevant (Step 3).
- The strongest, most specific project evidence is used (named projects,
  real stack, real outcomes) over generic ML buzzwords.
- The tone is confident, technically grounded, and human — not a resume
  restated in paragraph form, not a paraphrase of the job ad.
- The final version is concise and usually under 400 words.
- HTML output validates (`xmllint`) and uses `./cover-letter.css`.
- The chosen angle (Step 4) was selected over alternatives for a stated
  reason, not just the first idea.

If any check fails, fix it and re-run verification rather than shipping with
a known gap.