# Mamba-2 architecture and practical setup

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## Identify the model generation
Mamba-2 builds on structured state-space duality. Its implementation, configuration, and checkpoints must match the intended architecture; Mamba-1, Mamba-2, and later model generations are not interchangeable names for the same module.

The [official README snapshot](upstream/README.txt) gives a Mamba-2 module example, model variants, references to the minimal SSD implementation, and the corresponding research paper. Use its version-specific installation information rather than assuming that installing the core package also installed a CUDA scan extension.

## Bring-up checklist
1. Record the checkpoint, package revision, PyTorch build, accelerator, and extension availability.
2. Instantiate a small model with supported dimensions and confirm input/output shapes.
3. Check a forward/backward pass before attempting a distributed run.
4. Establish a one-device baseline, including precision and peak memory.
5. For tensor parallelism or distributed training, use the selected training framework's explicit integration. A module-level example alone does not establish support for a distributed topology.
6. Validate checkpoint save/reload and resumed loss before scaling the experiment.

Avoid translating head or state dimensions directly from an unrelated architecture. Inspect the installed module's configuration and checkpoint metadata.

## Local material
[Official README](upstream/README.txt), [existing training guide](training-guide.md), and [upstream license](upstream/LICENSE.txt).
