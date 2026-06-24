---
name: liberty-combine
version: 1.0.0
description: >
  Use when asked to combine results from two or more completed LIBERTY run
  output directories into a single merged report set + gateway. Discovers each
  run's final config and sample sheet, validates the relative-path layout is
  consistent, unions the samples, stages combinable artifacts to scratch,
  merges them (QC, ichorCNA, somatic MAF, RELOAD HLA), re-renders each Quarto
  report from the combined inputs, and builds a combined final-report gateway
  that names the source directories.
  Trigger phrases: "liberty combine", "combine LIBERTY runs",
  "combine these output directories", "merge run reports", "$liberty-combine".
skills_used:
  - parallel-execution-optimizer        # fan out discovery/combine subagents
  - team-agent-orchestration            # orchestrator <-> subagent contract
  - recursive-decision-ledger           # record path/merge/collision decisions
  - agent-introspection-debugging       # diagnose failed renders / staging
  - error-handling                      # fail-fast on missing/invalid configs
  - verification-loop                   # post-build consistency checks
  - eval-harness                        # smoke-test combined outputs
  - production-audit                    # final go/no-go on the gateway
  - documentation-lookup                # confirm quarto/Snakemake param contracts
agents_used:
  - agents/code-explorer.md             # locate configs, sheets, report files
  - .codex/agents/explorer.toml         # parallel filesystem discovery
  - agents/python-reviewer.md           # review combine.py changes
  - agents/silent-failure-hunter.md     # catch swallowed render/copy failures
  - .codex/agents/reviewer.toml         # final diff review
author: user
---

# liberty-combine

## Trigger
Activate when the user provides ≥2 LIBERTY run output directories and asks to
combine / merge them, or names `$liberty-combine`. Example:

  Combine
  /vf/users/AS_SN_shared/dbGAP/LIBERTY_analysis/phs001417/c1_crpc and
  /vf/users/AS_SN_shared/dbGAP/LIBERTY_analysis/phs001417/c2_mbc

---

## ORCHESTRATOR WORKFLOW
You are the orchestrating agent. Do not hand-merge files yourself; drive the
`liberty combine` command and use subagents for discovery, validation, and
verification. Follow these steps exactly.

### STEP 0 — Collect inputs
Confirm (ask only if missing — do not infer destructive defaults):
1. Two or more run directories (`--input`).
2. Output directory (`--output`).
3. Optional cohort name (`--name`), scratch dir (`--scratch`), and whether to
   rebuild MultiQC (`--multiqc`).
Do not proceed until at least two input dirs and one output dir are confirmed.

### STEP 1 — Parallel discovery  [parallel-execution-optimizer, explorer]
Dispatch ONE discovery subagent per run directory, in a single batch. Each
returns a JSON record for its run (see DISCOVERY SUBAGENT PROMPT). It must NOT
modify anything — read-only.

Each record:
```json
{
  "dir": "<abs path>", "label": "<basename>",
  "config": "<final_config.json|config.json>",
  "samplesheet": "<path|null>",
  "platforms": ["wes","wgs","avida"],
  "qc_metrics": "<path|null>",
  "reload_tsv": "<path|null>",
  "multiqc": "<path|null>",
  "maf_wes": ["<path>", ...], "maf_avida": ["<path>", ...],
  "ichor_params": ["<path>", ...],
  "n_samples": <int>
}
```

### STEP 2 — Validate consistency  [verification-loop, error-handling]
Orchestrator (not a subagent) checks:
- Every run has a readable config + sample sheet. Missing → STOP with the run named.
- Relative layout is consistent: each run exposes at least one combinable domain.
- Record every decision (chosen config name, resolved merge dir, sample-name
  collisions, skipped domains) in a recursive-decision-ledger note.
If a run is missing a whole domain (e.g. no ichorCNA), that domain is combined
from the runs that have it — never fail the whole job for one absent domain.

### STEP 3 — Run the combine engine
Invoke the command (or `python -m liberty.combine` equivalently):
```bash
liberty combine \
  --input <run1> <run2> [<run3> ...] \
  --output <combined_dir> \
  --name <cohort> \
  --scratch /lscratch/$SLURM_JOBID \
  [--merge-outdir merged] [--multiqc]
```
The engine: stages combinable artifacts to scratch, merges QC / MAF / ichorCNA /
RELOAD / sample sheet, renders each `.qmd` from the merged inputs, writes a
combined `config.json` + `combined_runs.json`, calls
`build_final_report_gateway.py`, and injects the provenance banner.

### STEP 4 — Verify  [verification-loop, silent-failure-hunter, eval-harness]
Dispatch a verification subagent (see VERIFY SUBAGENT PROMPT) to confirm:
- `<combined_dir>/final_report/index.html` exists and lists every source run.
- Each rendered report HTML exists and is non-trivial (> a few KB, no Quarto
  error banner).
- Combined sample count == union of per-run sample counts (allowing flagged
  duplicates).
- No render/copy step failed silently (scan `<scratch>/logs/*.render.log`).
Report any discrepancy; do not declare success if a domain present in inputs is
missing from the combined output without a logged reason.

### STEP 5 — Report
Print the gateway path, the source directories combined, per-domain status
(rendered / skipped-no-input / failed), and the location of render logs.

---

## ENGINEERING / MAINTENANCE MODE
When asked to change `liberty combine` itself (new domain, new path), drive:
1. `code-explorer` / `explorer.toml` → map the new artifact's relative path and
   its `.qmd` params.
2. `tdd-workflow` → add a discovery/combine unit test under `tests/` first.
3. Implement in `src/liberty/combine.py` only; keep `RUN_LAYOUT` the single
   source of truth for relative paths.
4. `python-reviewer` + `silent-failure-hunter` → review for swallowed failures.
5. `verification-loop` + `production-audit` → forward-test on two real runs.

---

## DISCOVERY SUBAGENT PROMPT (verbatim, one per run)
```xml
<task>
Read-only discovery for a single LIBERTY run directory: {{RUN_DIR}}.
Do NOT write, copy, or modify anything.

<instructions>
1. Locate the run config: final_config.json, else config.json. If neither
   exists, return {"error":"no config","dir":"{{RUN_DIR}}"} and stop.
2. From input_params.SAMPLE_SHEET resolve the sample sheet (absolute, or
   relative to the run dir). Count unique samples.
3. Resolve these relative paths if present (else null/empty list):
   QC/combined_qc_metrics.csv ; QC/combined_reload_results.tsv ;
   QC/finalQC/MultiQC_Report.html ;
   ichorCNA/*/*.params.txt (exclude ichorCNA/wigs) ;
   somatic_paired/SNP_Indels/*/cohort_summary/all_somatic_variants.wes.maf ;
   somatic_paired/SNP_Indels/*/cohort_summary/all_somatic_variants.avida.maf .
4. Read input_params.PLATFORM keys for the platform list.
Return ONLY the JSON record described in STEP 1. No prose.
</instructions>
</task>
```

## VERIFY SUBAGENT PROMPT (verbatim)
```xml
<task>
Verify a combined LIBERTY report at {{COMBINED_DIR}} against the source runs in
{{COMBINED_RUNS_JSON}} and render logs in {{LOG_DIR}}. Read-only.

<instructions>
1. Confirm final_report/index.html exists and its text names every source run dir.
2. For each expected report (QC, MAF, ichorCNA, RELOAD) that had combined input,
   confirm the HTML exists, is > 10 KB, and contains no Quarto error block.
3. Confirm combined sample count >= max per-run count and == union (note any
   flagged cross-run duplicate sample names).
4. Grep {{LOG_DIR}}/*.render.log for nonzero exits or "ERROR".
Return a short PASS/FAIL table per check with the offending path on FAIL. No prose.
</instructions>
</task>
```

## NOTES FOR ORCHESTRATOR
- Discovery is read-only and parallel; combination/rendering is done by the
  engine, not by a 6th subagent (avoids hallucinated merges).
- Never drop samples to resolve a name collision — keep both rows, tag
  `Source_Run`, and surface the collision.
- A domain absent from one run is combined from the runs that have it.
- If a render fails, the gateway should still build for the domains that
  succeeded; report the failure, do not abort the whole combine.
