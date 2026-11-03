# FlashAttention advanced feature selection

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## Match features to an API
The [official API snapshot](upstream/README.txt) documents standard, packed, variable-length, and KV-cache interfaces. Their supported features are not interchangeable.

- **MQA/GQA:** Check the required relationship between query-head and KV-head counts.
- **Causal masks:** Validate the documented alignment when query and key sequence lengths differ.
- **Sliding windows:** Check `window_size` semantics for the chosen interface and backend.
- **ALiBi:** Supply slopes with the documented shape and dtype.
- **Rotary embeddings:** The KV-cache interface documents rotary inputs and their position indexing; do not assume every entry point applies rotary embeddings for you.
- **Paged KV cache:** Use the documented cache layout and block table for that API.
- **Custom masks:** Do not assume an arbitrary dense mask is accepted by every fused kernel. Select a supported implementation or a documented fallback.

## Integration check
Add one feature at a time. Compare a small deterministic case against an unfused reference, then test variable lengths, padding, and cache updates. Confirm backward support before using an inference-oriented cache interface for training. Record the backend, GPU architecture, package version, and enabled features with benchmarks.

The upstream README and [license](upstream/LICENSE.txt) are stored locally; no online lookup is required to read the captured API contracts.
