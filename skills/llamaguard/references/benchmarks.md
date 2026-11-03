# Llama Guard benchmark interpretation

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## Start with the model card
The [bundled model card](upstream/model-card.txt) contains the original model's evaluation descriptions and reported results. Preserve the exact model version, dataset, policy taxonomy, and metric when citing a result. A score from a different moderation release is not a substitute.

## Local benchmark plan
Use a held-out set with reference labels and report confusion counts, precision, recall, and per-category results. Include benign requests that resemble prohibited ones, multilingual inputs, long conversations, and attempts to manipulate the classifier. Report the dataset composition and uncertain cases.

For latency, separate tokenization, queuing, model inference, and response parsing. Record accelerator, precision/quantization, prompt length, batch size, concurrency, throughput, and percentile latencies. Compare services under equivalent workloads; do not compare an offline batched run with an end-to-end network request as though they measure the same thing.

No new benchmark numbers were measured for this repository repair. The previous missing document cannot justify the speedup numbers elsewhere in the skill; validate those claims on the target system.

## Local sources
[Model card](upstream/model-card.txt), [usage instructions](upstream/usage.txt), [license](upstream/LICENSE.txt), and [usage policy](upstream/USE_POLICY.txt). Built with Llama; [notice](upstream/NOTICE.txt).
