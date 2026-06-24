---
name: hybrid-genomics-project-audit
version: 1.0.0
description: >
  Use when asked to audit, verify, fact-check, or harden an entire genomics
  research project (manuscript + supplementary + codebase + source literature +
  data), NOT just peer-review a manuscript. Performs (a) code-logic verification,
  (b) manuscript<->code consistency checking, (c) executable testing against real
  or synthetic VCFs, (d) cross-validation against cited source PDFs, (e) re-derivation
  of reported numbers/tables, and (f) ingestion of an existing peer-review .md to
  produce a single consolidated, evidence-backed audit, corrected code patches, and
  a test suite. Dispatches parallel domain-expert subagents (implementation/Buerkle,
  population genomics, biostatistics, computational reproducibility, evolutionary/
  conservation interpretation, and a manuscript<->code reconciler).
  Trigger phrases: "audit this project", "verify the code and manuscript",
  "make this foolproof", "project-level review", "check code against the paper",
  "$hybrid-genomics-project-audit".
skills_used:
  - superpowers:dispatching-parallel-agents
  - superpowers:subagent-driven-development
  - superpowers:requesting-code-review
  - scientific-agent-skills:peer-review
  - scientific-agent-skills:markitdown
  - scientific-agent-skills:pdf
  - scientific-agent-skills:literature-review
  - scientific-agent-skills:citation-management
  - scientific-agent-skills:scientific-writing
author: user
---

# hybrid-genomics-project-audit

## What this skill is (and is NOT)

This is a **project-level correctness-and-reproducibility audit**, not a journal
peer review. The companion skill `multi-reviewer-peer-review` answers "is this paper
publishable?". THIS skill answers "is every number in the paper actually produced by
this code, is the code a faithful implementation of the cited methods, does it run,
and do the conclusions survive a line-by-line trace?"

It is designed to **ingest** the output of `multi-reviewer-peer-review` and reconcile
it against ground-truth code behavior — promoting referee opinions that the code
confirms, and DEMOTING referee claims the code/data refute.

Do not write the audit yourself. You are the orchestrator. Dispatch subagents,
then synthesize.

---

## STEP 0 — Collect inputs

Confirm with the user (do not proceed without the manuscript + codebase paths):

1. Manuscript path(s) (e.g. `writing/Hybrid_genomics_MS_v0.1.docx`)
2. Supplementary path(s) (e.g. `writing/Hybrid_genomics_SI_v0.1.docx`)
3. Codebase root (e.g. `codebase/scripts/hybrid_index/`)
4. Source-literature PDFs (the cited papers the methods derive from)
5. Existing peer-review `.md` (from `multi-reviewer-peer-review`) — optional but expected
6. Example VCF(s) + sample lists for executable testing — optional; if absent, the
   skill SYNTHESIZES VCFs with known ground-truth ancestry (see STEP 3)
7. Output directory (default: `audit_<manuscript_basename>/`)

Record which inputs are present; missing inputs degrade specific checks, and the
degradation must be stated in the final report header.

---

## STEP 0.5 — Dependency + environment check

Two layers:

**(a) Skill dependencies.** Confirm every skill in `skills_used` resolves under the
standard Agent Skills roots (`.claude/skills/`, `~/.claude/skills/`, etc.; honor
`SKILLS_EXTRA_PATHS`). If any is missing, STOP and ask the user for a path, an
install, or explicit authorization to proceed with a noted-degraded fallback.

**(b) Runtime tools for executable testing.** Probe for: `python3` (+ `pandas`,
`numpy`, `pyyaml`, `matplotlib`), `vcftools`, `bgzip`/`tabix`, `awk`, `bash`.
Record versions. If `vcftools` is absent, the AIM/FST stages cannot be executed
end-to-end; the skill falls back to unit-testing the Python core
(`calculate_hybrid_index_ml.py`, `find_introgression_deserts.py`,
`summarize_admixed_regions.py`, `plot_hybrid_index.py`) directly on synthetic
inputs, and flags the bash-pipeline stages as logic-traced-only.

Write `audit_tmp/environment.json` capturing tool presence + versions. Do not
proceed to STEP 3 execution claims for any stage whose tools are missing — mark
those stages `LOGIC_TRACED_ONLY`.

---

## STEP 1 — Ingest everything

Use `markitdown`/`pdf` to convert to plaintext under `audit_tmp/`:
- `manuscript.txt`, `supplementary.txt`
- `lit/<short_name>.txt` for each source PDF (e.g. `buerkle2005`, `sovic2016`,
  `harrison_larson2016`, `ravinet2021`, `forsythe2020_DIP`)
- `peer_review.txt` (if provided)

Read every code file verbatim (do not summarize before the subagents see it):
`run_hybrid_script.sh`, `hybrid_index_sliding_window.sh`,
`calculate_hybrid_index_ml.py`, `find_introgression_deserts.py`,
`summarize_admixed_regions.py`, `plot_hybrid_index.py`, plus
`annotate_desert_genes.py`, `conda_envs.sh`, `vcf_parse.sh` and all
`metadata/*` (sample lists, vcf_files.txt, scaffold_manifest).

Build `audit_tmp/claim_inventory.tsv` — every quantitative or methodological
claim in the manuscript/SI, with its location and the code path (if any) that
should produce it. Minimum columns:
`claim_id, source(MS/SI/fig/table), location, claim_text, expected_producer,
param_values_stated, status(unchecked)`.

Seed it with the high-risk claims already known to need checking (the orchestrator
MUST include at least these, because they are documented drift/ambiguity points):

- Iowa sample N: abstract/proposal say 12; Methods say 11; figures say 11 — reconcile
  against `metadata/iowa_samples.txt`.
- Parental N: N=241 (*S. catenatus*), N=20 (*S. tergeminus*) — reconcile against
  `scat_samples.txt`, `ster_samples.txt`.
- Desert min-length: MS prose says ">500 kb"; `run_hybrid_script.sh` passes
  `--min-length 200000`; Table 2 lists 200 kb regions. CONTRADICTION — resolve.
- Desert min-support: MS says ">0.8 (80%)"; `find_introgression_deserts.py`
  default `--min-support 0.8`; run script passes `--min-support 0.8` but also
  `--min-samples 7` while 11 samples exist — check the support fraction math.
- Diagnostic threshold: MS says parent freq >=0.95 / <=0.05; code default
  `diagnostic-threshold 0.05`; run script does NOT pass it — verify default applies.
- Global MAF: MS says global MAF off to retain parent2-fixed alleles; verify
  `hybrid_index_sliding_window.sh` GLOBAL_MIN_MAF=0.0 path actually skips `--maf`.
- Desert totals: 77 regions / 95.4 Mb / "~6%" (MS) vs "~5%" (SI Table S1);
  SI Table S2 per-chromosome sums — re-derive from a deterministic windows TSV.
- Generation time / dates: MS uses 5 yr generation, 11 ka introgression, ~2000–4000
  gens; Sovic 2016 reports 5.03 yr and ~11 ka (CI 2429–29602 ybp) — check consistency.
- Hybrid index orientation: h=0 => parent1 (*S. catenatus*), h=1 => parent2
  (*S. tergeminus*); verify `parse_gt_to_n_alt` + `p2_is_alt` polarity in code.

---

## STEP 2 — Dispatch parallel auditor subagents

Dispatch A1–A5 as a single parallel batch via dispatching-parallel-agents. Wait for all five to complete. THEN dispatch A6 alone as a second wave — A6 reconciles the other five and must not run until audit_A1.md…audit_A5.md exist. Each agent gets:
full `manuscript.txt`, `supplementary.txt`, ALL code files inline, the relevant
`lit/*.txt`, `claim_inventory.tsv`, `environment.json`, and (if present)
`peer_review.txt`. Context-isolated; no session history. Each writes
`audit_tmp/audit_<id>.md` AND appends verdicts to `claim_inventory.tsv` rows it owns.

| ID | Persona | Primary lens |
|----|---------|-------------|
| A1 | Method-Implementation Auditor (Buerkle 2005 ML) | Does `calculate_hybrid_index_ml.py` correctly implement the fixed-difference binomial likelihood, the 2-logL support interval, the permutation CI, polarity, and partial-genotype skipping? |
| A2 | Population Genomicist | AIM definition (FST>=0.5 -> fixed differences), parental imbalance subsampling (20/241), MAF/missingness filtering, window/AIM thresholds, ascertainment bias |
| A3 | Biostatistician | CI semantics (support vs percentile), the 80% / min-samples / min-length desert criteria, independence assumption, multiple testing for GO, re-derivation of table totals |
| A4 | Computational Reproducibility / SWE | Determinism (seed), bash robustness, path/arg wiring run-script->pipeline->python, prose-vs-CLI param drift, file-format assumptions, end-to-end runnability |
| A5 | Evolutionary / Conservation Interpreter | Desert-vs-island logic (Harrison & Larson), selection-vs-ILS/recombination caveats (Ravinet, Forsythe DIP), adaptationist over-claiming, conservation conclusions vs Sovic demographic support |
| A6 | Manuscript<->Code Reconciler + Peer-Review Integrator | Walk `claim_inventory.tsv`: for each claim mark CONFIRMED / CONTRADICTED / UNVERIFIABLE against code+data; then ingest `peer_review.txt` and tag each referee point UPHELD / OVERTURNED / REFINED by ground truth |

Each subagent flags severity `[CRITICAL] [MAJOR] [MINOR] [SUGGESTION]` and MUST cite
exact file + line / section + the literature passage when asserting a method is
mis-implemented. No vague findings; every claim of incorrectness needs a concrete
location and the expected-vs-actual behavior.

Reviewer-prompt templates are in `assets/auditor_prompts/` (one per agent). They
embed the relevant `lit/*` excerpts so each agent checks code against the actual
cited method, not from memory.

---

## STEP 3 — Executable verification (the part peer review can't do)

Run by `scripts/run_tests.sh`. Two tiers; run both when tools allow.

**Tier 1 — Unit tests on the Python core (always runnable; no vcftools needed).**
`scripts/make_synthetic_vcf.py` emits small VCFs with KNOWN ground-truth ancestry so
outputs are checkable against closed-form expectations:
- A window of pure-parent1 diagnostic genotypes => h must == 0.0 (and ancestry=parent1).
- Pure-parent2 => h == 1.0. A 50/50 het block => h == 0.5.
- `support_interval_binomial(k, n)` edge cases: k=0 and k=n match the analytic
  `1-exp(-2/n)` / `exp(-2/n)` bounds; interval brackets k/n; monotone in n.
- Polarity test: swap which parent is ALT-fixed; confirm `p2_is_alt`/`diag_ref`
  branches keep h oriented to parent2.
- Partial/haploid genotypes (`0/.`, `./1`, `1`) return None and are excluded.
- `min-aims` gating: a window with < min-aims called diagnostic loci is dropped.
- Desert merging: hand-built windows TSV with a known gap == merge-distance boundary
  -> verify off-by-one (`s <= cur_end + merge_distance`) merges vs splits correctly.
- Re-derivation: feed the deterministic windows TSV through
  `find_introgression_deserts.py` and assert region count, total bp, and per-chrom
  sums; compare against the manuscript's 77 / 95.4 Mb / per-chrom Table S2. Any
  mismatch is a CRITICAL claim-inventory contradiction.

**Tier 2 — End-to-end pipeline test (requires vcftools; else LOGIC_TRACED_ONLY).**
When the user supplies a real example VCF (or on a synthetic multi-contig VCF):
run `hybrid_index_sliding_window.sh` on a tiny region with a handful of input +
parent samples, confirm it produces `hybrid_index_windows.tsv` with the documented
10-column header, that `ancestry_summary.tsv` column-9 logic matches `classify_ancestry`,
and that the FST->AIM->subset stages don't silently drop all loci. Capture stdout/stderr
to `audit_tmp/e2e_log.txt`.

All tests live in `tests/` and are emitted as part of the deliverable so the user
can re-run them. Tests must be deterministic (fixed `--seed`).

---

## STEP 4 — Synthesize

Read all six `audit_<id>.md`, the completed `claim_inventory.tsv`, and the test
results (`audit_tmp/test_report.json`). Build a master issue list. Classification:

- Flagged by >=3 auditors OR a failed Tier-1 test => **CRITICAL**
- Flagged by 2 auditors, or a confirmed prose<->code contradiction => **MAJOR**
- Single-auditor substantive => **MINOR**; style/wording => **SUGGESTION**

Reconcile with peer review explicitly: produce a table of referee points x
{code/data verdict}. A referee "over-claim" concern that the code CONFIRMS becomes a
hardened CRITICAL; a referee concern the data OVERTURN is recorded as resolved with
the evidence. This is the "make it foolproof" payload — opinions converted to
verified facts.

Write `audit_tmp/synthesis.md` (raw inventory) before STEP 5.

---

## STEP 5 — Deliverables

Write to the output directory:

1. **`AUDIT_REPORT.md`** — prose (scientific-writing style; minimal bullets), with:
   - Header: inputs present, tool versions, which stages were executed vs logic-traced,
     skill-omission notes.
   - Overview: soundness verdict; the single most important correctness issue.
   - Critical Findings; Major Findings; Minor; Suggestions — each with file+line /
     section refs, expected-vs-actual, and the source-literature citation when method
     fidelity is at stake.
   - **Claim Verification Table**: every reported number/method -> CONFIRMED /
     CONTRADICTED / UNVERIFIABLE + evidence (test id or line ref).
   - **Peer-Review Reconciliation**: each referee point -> UPHELD / OVERTURNED /
     REFINED + ground-truth evidence.
   - Prioritized Next Steps (what to fix, in what order, with the proposed analyses
     from the planning doc mapped to readiness).
2. **`patches/`** — minimal corrected code (unified diffs or full files) for every
   CRITICAL/MAJOR code finding, each paired with the test that now passes.
3. **`tests/`** — the synthetic-VCF generator + unit + e2e tests, runnable via
   `run_tests.sh`, with a README listing expected results.
4. **`claim_inventory.tsv`** — the machine-readable ledger.

Then remove `audit_tmp/` and report the output paths.

---

## NOTES FOR ORCHESTRATOR

- Ground truth beats opinion: when an auditor and the code disagree, the test result
  decides; never let a subagent's recollection of Buerkle/Ravinet override the actual
  cited PDF text in `lit/`.
- Do NOT let A6 invent line numbers; cite section headings if lines are ambiguous.
- A patch is only emitted with a failing-then-passing test. No test, no patch.
- Synthesis is done by YOU, not a 7th subagent, to avoid hallucinated consensus.
- Distinguish prose-vs-code *drift* (fixable by editing text or default) from genuine
  *logic errors* (fixable only by code change) — they go in different report sections.
- Re-derive, don't trust: the 77/95.4 Mb/per-chromosome figures must come from running
  the code on a deterministic input, not from restating the tables.
- Tone: collegial, specific, constructive — this is the author's own QC pass.
