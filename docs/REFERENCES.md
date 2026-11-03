# Local reference repairs

The initial audit found **23 broken links covering 17 distinct reference documents** in seven skill families. All those links now resolve to real files in this repository, including each duplicate skill folder.

## What was missing

These documents were not found in the checked local skill collections (`.orchestra`, `.agents`, `.codex/skills`, or the GitHub workspace), nor in the complete current tree of [Orchestra Research's source repository at commit 773a529](https://github.com/Orchestra-Research/AI-Research-SKILLs/tree/773a52944ba4747a18bd4ae9ade53fff041adcbc). This establishes their absence from the checked sources, not that they never existed in any historical version or elsewhere on the internet.

Copying the skill folders faithfully therefore preserved references to files the source collection did not contain. There were no original documents available to recover from those checked sources.

## What is included now

**17 new local guides, replicated into 23 locations.** Every replacement identifies itself as a SamSkills maintenance addition, not an original Orchestra Research document. They summarize the topic, provide a practical workflow, and link to locally bundled sources. They do not claim unmeasured benchmark results or restore an unavailable original implementation.

| Skill family | New local guides | Folders covered |
| --- | --- | --- |
| Constitutional AI | Constitution design, RLAIF comparison, structured critique | `constitutional-ai` |
| FlashAttention | Algorithm, advanced features | `flash-attention`, `optimizing-attention-flash` |
| Llama Guard | Custom categories, benchmarks, deployment | `llamaguard` |
| Mamba | Selective SSM, Mamba-2, performance | `mamba`, `mamba-architecture` |
| NeMo Guardrails | Colang, integrations, performance | `nemo-guardrails` |
| Ray Train | Hyperparameter tuning, custom loops | `ray-train` |
| verl | Multi-turn tool use | `verl`, `verl-rl-training` |

**Pinned official source documentation.** The affected folders contain `references/upstream/` with official README/model-card/documentation snapshots and their licenses. Ray's included training example and NVIDIA's detailed caching instructions are also local. Snapshot files use `.txt` to preserve the original Markdown, MDX, Python, or reStructuredText without pretending that the originating documentation website has been rebuilt here. Internal links and directives inside these unchanged snapshots still describe their upstream repository; the replacement guides provide working links to the bundled material.

**Two unchanged research PDFs.** Constitutional AI includes Bai et al.'s 2022 paper and Lee et al.'s 2024 RLAIF comparison revision, with attribution and their CC BY 4.0 license links. Each paper can be read offline. Model weights, Python environments, datasets, and API credentials are runtime inputs and are not documentation files.

The guides are bounded references, not complete mirrors of every project's website. For example, the Llama Guard deployment guide provides a deployment/validation workflow, not a newly tested SageMaker or Kubernetes template. The NeMo integration guide does not invent the missing ActiveFence configuration. The original skill entry points and their older examples have not been upgraded or runtime-tested against the newer source snapshots.

## Provenance and checks

- [Repair manifest](../catalog/reference-repairs.json): original upstream tree revision, every replacement location, and SHA-256 checksums.
- [Source manifest](../catalog/reference-sources.json): source URL, pinned project commit or paper version, destination paths, and checksums. GitHub downloads were verified against the repository's Git blob hashes.
- [Original vendoring manifest](../catalog/vendored.json): unchanged record of the initial copied files. New supplements are recorded separately.

Run:

```bash
python3 scripts/check_references.py
python3 scripts/build_catalog.py --check
python3 -m unittest discover -s tests -p 'test_*.py'
```

The reference check verifies content hashes and every local link in the replacement guides. Catalog tests reject unresolved relative Markdown links in `SKILL.md` entry points. This does not certify every original script, example path, or external URL in all supporting files.

The two remaining audit findings are `/home/ubuntu/` example paths in the Lambda Labs variants, not missing reference files or links to files on the repository owner's computer.
