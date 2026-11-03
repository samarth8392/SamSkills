# Measuring Mamba performance

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## Compare equivalent workloads
Measure prompt processing and incremental decoding separately. Hold the batch size, sequence length, precision, model size, tokenizer, and generation settings constant. Include warm-up, synchronize device timing, and report multiple measurements rather than one run.

Mamba's recurrent decoding state does not grow with context length in the same manner as a conventional attention KV cache. It still consumes memory for parameters, state, intermediate tensors, and the runtime. Training and decoding have different memory profiles.

## Diagnose before optimizing
Confirm the expected kernels and extensions are available. Profile data loading, host/device transfers, kernel time, and synchronization. Compare throughput, latency, and peak allocated memory; a favorable result in one metric may not improve the application's bottleneck.

The [official README](upstream/README.txt) describes the project's evaluation and generation benchmark entry points. The existing [benchmark reference](benchmarks.md) contains illustrative tables, not measurements performed on your hardware. Reproduce results before using those numbers as an engineering target.

For every result, save the exact command, model/checkpoint, package revision, GPU, driver, precision, batch size, context length, and warm-up/timing procedure. Do not report an out-of-memory case as an infinite measured speedup.

[Upstream license](upstream/LICENSE.txt).
