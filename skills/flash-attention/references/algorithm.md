# FlashAttention algorithm and validation

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## Core idea
FlashAttention computes exact softmax attention using a tiled computation that reduces movement between GPU high-bandwidth memory and on-chip memory. It avoids storing the full attention matrix in high-bandwidth memory. Exact refers to the attention operation, not bit-for-bit equality across floating-point implementations.

Tiles maintain running softmax normalization statistics and accumulated outputs. During backward computation, recomputing intermediates trades additional arithmetic for lower memory traffic. This does not make dense attention linear in sequence length: the pairwise arithmetic remains quadratic even though its memory behavior improves.

## Before changing a model
Record tensor layout, dtype, head dimensions, query and key lengths, causal alignment, dropout, and the selected backend. Compare outputs and gradients against a reference implementation on small cases, including unequal query/key lengths. Use dtype-appropriate tolerances; a single universal error threshold is not reliable.

Benchmark after warm-up and synchronize GPU timing. Measure peak memory as well as latency, keeping the workload and precision identical. An installed package is not evidence that a particular kernel was selected.

## Offline source
The [official README snapshot](upstream/README.txt) includes API contracts, implementation families, validation notes, and citations to the algorithm papers. Its [license](upstream/LICENSE.txt) is bundled. The snapshot covers multiple generations; select documentation matching the installed package.
