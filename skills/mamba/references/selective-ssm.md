# Selective state-space models

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## State update
A discrete state-space layer updates a recurrent state and projects it to an output. In Mamba, input-dependent selection changes how information is retained and exposed. Use the discrete recurrence

```text
h_t = A_bar_t h_(t-1) + B_bar_t x_t
y_t = C_t h_t
```

Here the barred quantities denote discretized parameters. This is conceptual notation, not drop-in implementation code; do not replace the actual discretization with an arbitrary multiplication by a timestep.

## Why implementation matters
The selective scan and hardware-aware computation support efficient processing without materializing a dense pairwise attention matrix. Complexity statements assume a fixed model/state size. Constant recurrent state with respect to context length does not mean zero memory use.

Start from the packaged module and verify output shape and gradients on a small batch. Check whether the CUDA extension is actually installed and selected. Separate prefill measurements from token-by-token generation when comparing with attention-based models.

## Offline sources
The [official project README](upstream/README.txt) identifies the selective scan, model modules, installation modes, and original papers. The existing [architecture reference](architecture-details.md) supplies additional background, but treat illustrative equations and performance claims there as examples to validate. [Upstream license](upstream/LICENSE.txt).
