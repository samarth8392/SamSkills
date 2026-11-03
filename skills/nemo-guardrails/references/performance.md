# NeMo Guardrails latency and caching

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## Measure the full path
Break latency into queueing, input rails, model generation, output rails, and external actions. Count model calls per request. Benchmark representative accepted and rejected requests, since they may take different paths.

The [official caching overview](upstream/caching.txt) distinguishes caching complete model responses from reusing prompt KV state at the model-serving layer. These are different optimizations and can have different configuration and invalidation requirements.

## Optimization workflow
Establish correctness and latency baselines before enabling a cache. Include model version, prompts, policy/configuration version, and any relevant tenant context in the cache design. Invalidate entries after policy changes; do not reuse an answer under a different context merely because the user text matches.

Tune concurrency and batching only where the selected provider supports them. Independent checks may permit concurrency, but preserve required ordering between checks and actions. Record tail latency, cache hit rate, queue growth, and failure rate under load. Verify that cached and uncached paths produce the same intended decision on the test set.

This guide does not assert a fixed speedup or a universal batching switch. Use the bundled documentation and the selected provider's measured behavior.

## Offline sources
[Caching overview](upstream/caching.txt), [model response caching](upstream/model-memory-cache.txt), [KV-cache reuse](upstream/kv-cache-reuse.txt), [license](upstream/LICENSE.txt), and [Apache terms](upstream/LICENSE-Apache-2.0.txt).
