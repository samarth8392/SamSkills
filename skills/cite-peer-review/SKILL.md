---
name: cite-peer-review
version: 1.1.0
description: >
  Use when asked to add literature support to an existing peer review document.
  Reads a peer review .md file, extracts all CRITICAL and MAJOR comments,
  dispatches parallel subagents to search PubMed/OpenAlex/Semantic Scholar
  for supporting literature, then annotates the review inline with numbered
  citations and appends a verified bibliography.
  Trigger: "add citations to peer review", "literature-back the review",
  "find papers supporting the review", "$cite-peer-review".
skills_used:
  - superpowers:dispatching-parallel-agents
  - superpowers:subagent-driven-development
  - scientific-agent-skills:paper-lookup
  - scientific-agent-skills:pubmed-database
  - scientific-agent-skills:literature-review
  - scientific-agent-skills:citation-management
author: user
---

# cite-peer-review

## Purpose

Take an existing peer review markdown file produced by `$multi-reviewer-peer-review`
(or any structured review with labeled CRITICAL/MAJOR/MINOR sections) and
make every substantive recommendation evidence-backed.

For each CRITICAL and MAJOR comment, find 2–5 primary literature papers that:
  (a) establish the methodological standard being recommended, OR
  (b) demonstrate the problem being flagged in analogous systems, OR
  (c) provide the best available benchmark, method, or case study.

Output: annotated review with inline `[N]` citations + a numbered BibTeX-style
bibliography that authors can paste directly into their reference manager.

---

## ORCHESTRATOR WORKFLOW

### STEP 0 — Inputs

Collect if not provided:
  - `REVIEW_FILE`: path to existing peer review .md
  - `OUTPUT_FILE`: default `<stem>_cited.md`
  - `NCBI_EMAIL`: for PubMed E-utilities (required by NCBI ToS; ask if not set)
  - `MAX_PAPERS_PER_COMMENT`: default 5 (range 3–8)

Fail fast if `REVIEW_FILE` does not exist or is empty.

---

### STEP 1 — Parse review, extract comment blocks

Read `REVIEW_FILE`. Parse and extract every block labeled:
  - CRITICAL / FATAL FLAW
  - MAJOR COMMENT (MC1–MCN)
  - OVERARCHING LIMITATIONS (treat as one block)

For each block store:
```json
{
  "id": "MC1",
  "severity": "CRITICAL|MAJOR|OVERARCHING",
  "title": "<short title>",
  "body": "<full text of comment>",
  "search_strategy": null
}
```

Write parsed blocks to `_cite_tmp/comments.json`.

Do NOT extract MINOR or SPECIFIC comments for literature search
unless the user explicitly requests it.

---

### STEP 2 — Build search strategies

For each comment block, generate 3 PubMed/OpenAlex search strings:
  - One broad (topic + method, 3–5 terms)
  - One specific (exact technique or metric being flagged)
  - One MeSH-anchored (use MeSH terms from pubmed-database skill)

Store all strategies in `_cite_tmp/comments.json` under `search_strategy`.

Use the SEARCH STRATEGY REFERENCE section below as the starting point.
Adapt dynamically if the comment body contains domain-specific terms not
covered by the reference. When the comment body mentions a specific taxon
(e.g. vulture, macaque, raptor, island population), add those taxon terms
to every search string for that comment.

---

### STEP 3 — Dispatch parallel subagents

Use `superpowers:dispatching-parallel-agents`.
Dispatch ONE subagent per comment block simultaneously.

Each subagent:
  - Receives its comment block text + all 3 search strings (injected inline)
  - Uses `scientific-agent-skills:paper-lookup` for multi-database search
  - Uses `scientific-agent-skills:pubmed-database` for MeSH-precision fallback
  - Uses `scientific-agent-skills:citation-management` to verify DOI and
    extract: authors, year, title, journal, volume, pages/article-id, DOI
  - Returns: `_cite_tmp/refs_<ID>.json`

Context isolation: each subagent receives ONLY its comment + search strings.
No session history. No other comment context.

Wait for ALL subagents to complete before Step 4.

---

### STEP 4 — Validate and deduplicate references

Read all `_cite_tmp/refs_*.json`.

For each returned paper:
  1. Verify DOI resolves (HEAD request to https://doi.org/<doi>)
  2. Confirm abstract/title matches the flagged topic (semantic check)
  3. Reject if: DOI 404s, title is unrelated, year < 2000 unless foundational
  4. Flag as UNVERIFIED if DOI check fails but paper appears valid — include
     but mark `[unverified DOI]` in bibliography

Deduplicate: if the same DOI appears for multiple comments, assign one
reference number but cite it in all relevant comment sections.

Assign sequential reference numbers [1], [2], [3]... across all comments
in order of first appearance.

Write final reference list to `_cite_tmp/bibliography.json`:
```json
[
  {
    "ref_id": 1,
    "doi": "10.xxxx/...",
    "citation": "Author A, Author B (Year). Title. Journal Volume:Pages.",
    "bibtex": "@article{...}",
    "comment_ids": ["MC1", "MC3"],
    "verified": true
  }
]
```

---

### STEP 5 — Annotate the review

Read the original `REVIEW_FILE`.

For each CRITICAL/MAJOR/OVERARCHING comment block:
  - Insert inline `[N, M, ...]` citation markers at the END of the
    specific sentence that makes the claim or recommendation.
  - Do NOT restructure, rephrase, or add new text to comments.
  - Only add citation markers. Preserve all original formatting exactly.

Append at the end of the document:

```markdown
---

## References

[1] Author A, Author B (Year). Title. *Journal* Volume(Issue):Pages.
    DOI: https://doi.org/10.xxxx/...

[2] ...
```

Write annotated document to `OUTPUT_FILE`.

---

### STEP 6 — Write citation report

Write `_cite_tmp/citation_report.md`:

```markdown
# Citation coverage report

| Comment | Severity | Papers found | Verified DOIs | Taxon-specific? | Coverage |
|---------|----------|-------------|---------------|-----------------|----------|
| MC1     | CRITICAL | 5           | 5             | Yes (vulture)   | ✓ full   |
| MC2     | CRITICAL | 4           | 3             | No (generic)    | ~ partial|
...

## Comments with weak coverage (< 2 verified papers)
List here with suggested manual search terms.

## Foundational papers cited
List papers cited in 3+ comment sections.

## Taxon-specific coverage note
For each comment: whether a study in the same or closely related taxon
(same order/family) was found, or whether coverage relies on generic
genomics methods papers only.
```

Report to user: output file path, total references, any weak-coverage comments.

---

### STEP 7 — Cleanup

Remove `_cite_tmp/`. Keep only `OUTPUT_FILE` and `citation_report.md`
(write report to same directory as output file).

---

## SEARCH STRATEGY REFERENCE

Pre-built search strings per comment type. Orchestrator uses these as starting
point and extends with terms from the specific comment body.
When the review concerns a specific taxon, append taxon terms to every query.

---

### MC1-type / MC-RELATEDNESS: Relatedness / kinship filtering

**Broad:** `population genomics kinship relatedness filtering bias`
**Specific:** `identity-by-descent close kin pseudoreplication population structure`
**MeSH:** `("Genetics, Population"[MH]) AND ("Pedigree"[MH] OR "Inbreeding"[MH]) AND "Bias"[MH]`
**Key concepts:** KING estimator, IBD pruning, ROH-based kinship, genomic relatedness matrix

---

### MC2-type / MC-SPECIESDEL: Species delimitation / BPP / taxonomy

**Broad:** `species delimitation BPP Bayesian population structure genomics`
**Specific:** `BPP A10 species tree prior sensitivity guide tree`
**MeSH:** `("Species Specificity"[MH]) AND ("Genome"[MH]) AND ("Bayes Theorem"[MH])`
**Key concepts:** BPP priors sensitivity, integrative taxonomy, morphological diagnosis

---

### MC3-type / MC-DRIFTSEL: Drift vs. selection / genetic load / purging

**Broad:** `genetic drift selection genetic load purging small populations`
**Specific:** `realized masked genetic load deleterious alleles bottleneck demographic history`
**MeSH:** `("Selection, Genetic"[MH]) AND ("Genetic Drift"[MH]) AND ("Mutation Rate"[MH])`
**Key concepts:** drift-load paradox, purging efficacy, inbreeding depression, LoF enrichment null models

---

### MC4-type / MC-FST: Fst inflation / small Ne

**Broad:** `Fst inflation small effective population size diversity bias`
**Specific:** `Fst species threshold population differentiation bottleneck isolation`
**MeSH:** `("Gene Frequency"[MH]) AND ("Genetics, Population"[MH]) AND ("Genetic Drift"[MH])`
**Key concepts:** Nei's Gst, Hedrick's G'st, Jost's D, Fst as species criterion critique

---

### MC5-type / MC-GENEFLOW: Gene flow tests / D-statistic / f3

**Broad:** `D-statistic ABBA BABA admixture f3 gene flow test`
**Specific:** `outgroup f3 admixture f3 distinction introgression detection power`
**MeSH:** `("Gene Flow"[MH]) AND ("Genome"[MH]) AND ("Evolution, Molecular"[MH])`
**Key concepts:** f3/f4/D-statistic theory, admixtools2, detection limits, block jackknife

---

### MC6-type / MC-DEMOG: Demographic modeling / fastsimcoal2 / dadi / AIC

**Broad:** `fastsimcoal2 dadi demographic inference SFS AIC model selection`
**Specific:** `site frequency spectrum composite likelihood model comparison population history`
**MeSH:** `("Models, Genetic"[MH]) AND ("Population Dynamics"[MH]) AND ("Computer Simulation"[MH])`
**Key concepts:** fastsimcoal2, dadi, PSMC, SMC++, StairwayPlot, AIC model selection SFS,
  folded SFS ascertainment bias, bootstrap uncertainty dadi, two-population model

---

### MC7-type / MC-CONSERVE: Genetic rescue / conservation / small populations

**Broad:** `genetic rescue conservation genomics small population island`
**Specific:** `genetic rescue outbreeding depression inbreeding depression management`
**MeSH:** `("Conservation of Natural Resources"[MH]) AND ("Inbreeding"[MH]) AND ("Genomics"[MH])`
**Key concepts:** genetic rescue theory, 50/500 rule, minimum viable population, island conservation genomics

---

### MC8-type / MC-LOF: LoF annotation / SnpEff / variant consequence

**Broad:** `loss of function variant annotation SnpEff VEP consequence filtering`
**Specific:** `frameshift stop-gain splice site annotation false positive filtering genome`
**MeSH:** `("Loss of Function Mutation"[MH]) AND ("Genome"[MH]) AND ("Software"[MH])`
**Key concepts:** LOFTEE, VEP vs SnpEff, LoF false positive rate, ancestral state assignment,
  derived allele burden normalization, mutation load conservation

---

### MC-SPECIES: Molecular species assignment from non-invasive samples

**Broad:** `molecular species identification non-invasive feather DNA conservation genomics`
**Specific:** `mitochondrial barcoding raptor vulture feather DNA species assignment ddRAD`
**MeSH:** `("DNA Barcoding, Taxonomic"[MH]) AND ("Specimen Handling"[MH] OR "Feathers"[MH]) AND ("Conservation of Natural Resources"[MH])`
**Key concepts:** COI barcoding, diagnostic nuclear markers, non-invasive DNA quality,
  species misassignment bias, mixed-species sample confounding, integrative taxonomy raptor

---

### MC-ROH-RADSPARSE: ROH and inbreeding from sparse / ddRAD markers

**Broad:** `runs of homozygosity sparse SNP panel reduced representation sequencing`
**Specific:** `ROH ddRAD RADseq PLINK homozyg marker density sensitivity inbreeding`
**MeSH:** `("Homozygote"[MH]) AND ("Polymorphism, Single Nucleotide"[MH]) AND ("High-Throughput Nucleotide Sequencing"[MH])`
**Key concepts:** FROH vs PLINK F, marker spacing ROH bias, callable genome denominator,
  ROH false-positive rate low SNP density, feather ddRAD genotyping error, non-invasive ROH

---

### MC-DDRADLIMIT: ddRAD data limitations for population-genomic inference

**Broad:** `ddRAD-seq population genomics accuracy limitation ascertainment bias`
**Specific:** `RADseq ascertainment bias SFS demographic inference genotyping error missingness`
**MeSH:** `("Genetic Variation"[MH]) AND ("Sequence Analysis, DNA"[MH]) AND ("Population Dynamics"[MH])`
**Key concepts:** ascertainment bias ddRAD, missing data patterns, locus dropout,
  paralog contamination, reference divergence RADseq, ddRAD vs whole-genome power comparison,
  marker density population structure inference

---

### OVERARCHING: Statistical non-independence / multiple testing / pseudoreplication

**Broad:** `multiple testing correction genomics genome-wide association false discovery`
**Specific:** `linkage disequilibrium non-independence block jackknife bootstrap genomics individual-level`
**MeSH:** `("Multiple Testing"[MH]) AND ("Genomics"[MH])`
**Key concepts:** BH-FDR, block jackknife, GWAS inflation, permutation testing,
  window-level vs individual-level inference, biological replication unit

---

## SUBAGENT PROMPT TEMPLATE

Inject per subagent. Replace `{{COMMENT_ID}}`, `{{SEVERITY}}`, `{{COMMENT_TITLE}}`,
`{{COMMENT_BODY}}`, `{{SEARCH_BROAD}}`, `{{SEARCH_SPECIFIC}}`, `{{SEARCH_MESH}}`,
`{{NCBI_EMAIL}}`, `{{MAX_PAPERS}}`, `{{OUTPUT_PATH}}`.

```xml
<task>
Your task is to find primary literature supporting a specific peer review comment.
You are a literature specialist with expertise in population genomics, evolutionary
biology, conservation genetics, and computational biology.

<comment>
ID: {{COMMENT_ID}}
Severity: {{SEVERITY}}
Title: {{COMMENT_TITLE}}
Body:
{{COMMENT_BODY}}
</comment>

<search_instructions>
Use the following skills in order:

1. scientific-agent-skills:paper-lookup
   Run searches across PubMed, OpenAlex, Semantic Scholar, bioRxiv:
   - Broad query: {{SEARCH_BROAD}}
   - Specific query: {{SEARCH_SPECIFIC}}

2. scientific-agent-skills:pubmed-database (E-utilities, email: {{NCBI_EMAIL}})
   Run MeSH-anchored query: {{SEARCH_MESH}}
   Retrieve abstracts for top 10 results. Read abstracts before selecting papers.

3. scientific-agent-skills:citation-management
   For each selected paper: resolve DOI, extract full metadata, generate BibTeX.
</search_instructions>

<selection_criteria>
Select {{MAX_PAPERS}} papers maximum. Prefer papers that:
  - Directly demonstrate the methodological problem being flagged, OR
  - Establish the standard/best-practice being recommended, OR
  - Provide a benchmark, simulation, or empirical case study in a closely
    related system (vultures, raptors, island populations, birds, conservation genomics,
    population genomics methods papers) — taxon-matched papers are preferred
    over generic human/crop studies when both are available
  - Are published in peer-reviewed journals (bioRxiv acceptable if highly cited
    and no published version found)
  - Year >= 2000, except foundational theory papers (e.g. Wright 1931, Nei 1973)
  - Are NOT preprints if a published version exists

Reject papers if:
  - Abstract does not mention the specific method or problem flagged
  - DOI cannot be resolved
  - Title/abstract is clearly off-topic

Priority order when multiple papers are found:
  1. Same or closely related taxon (raptor, vulture, bird conservation)
  2. Conservation genomics empirical study (any taxon)
  3. Methods paper demonstrating the specific problem or fix
  4. Foundational theory paper
</selection_criteria>

<output_format>
Write ONLY valid JSON to {{OUTPUT_PATH}}. No prose, no preamble.

{
  "comment_id": "{{COMMENT_ID}}",
  "papers": [
    {
      "doi": "10.xxxx/...",
      "authors": "Last1 AB, Last2 CD",
      "year": 2021,
      "title": "Full paper title",
      "journal": "Journal Name",
      "volume": "12",
      "issue": "3",
      "pages_or_id": "e1234567",
      "citation": "Last1 AB, Last2 CD (2021). Full paper title. Journal Name 12(3):e1234567.",
      "bibtex": "@article{Last12021, author={...}, title={...}, journal={...}, year={2021}, doi={10.xxxx/...}}",
      "relevance": "One sentence: why this paper supports the comment.",
      "taxon_matched": true,
      "verified_doi": true
    }
  ],
  "search_queries_used": ["...", "..."],
  "coverage_note": "Brief note if coverage is weak, if no taxon-matched paper was found, or if foundational papers dominate."
}
</output_format>
</task>
```

---

## ERROR HANDLING

- If a subagent returns malformed JSON: re-dispatch once with explicit
  "Output ONLY valid JSON" directive.
- If fewer than 2 papers found for a CRITICAL comment: escalate to orchestrator
  to run a second-pass search with broader terms before accepting weak coverage.
- If DOI verification fails at Step 4: mark `[unverified DOI]`, include anyway.
- Do not hallucinate citations. If search returns nothing relevant, write
  `"papers": []` and note "no relevant literature found" in citation_report.md.
- Never fabricate DOIs, page numbers, volume numbers, or author names.
- If the comment body contains a specific tool name (dadi, PLINK, SnpEff,
  ADMIXTURE, PLINK --homozyg, fastsimcoal2), always include at least one
  citation for the tool itself from the original publication.
