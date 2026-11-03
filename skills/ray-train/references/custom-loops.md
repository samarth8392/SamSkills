# Custom Ray Train worker loops

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## Keep driver and worker responsibilities distinct
The driver creates the trainer and specifies resources. The per-worker training function loads or receives its data, constructs the model and optimizer, runs the training loop, and participates in reporting/checkpointing.

The local [PyTorch getting-started guide](upstream/pytorch-training.txt) and [training-loop API reference](upstream/train-loop.txt) describe the captured API. Use model and data-loader preparation helpers where required by that integration rather than assuming Ray automatically distributes every object.

## A reliable loop
1. Initialize deterministic seeds and record world size/rank.
2. Distribute or shard input data appropriately.
3. Train and validate with metrics whose aggregation is explicit.
4. Ensure participating workers reach required reporting calls consistently; a rank-specific early exit can leave other workers waiting.
5. Save model, optimizer, scheduler, and progress state needed to resume.
6. Test interrupted-run recovery on a tiny experiment before using a large cluster.

Do not sum an already averaged metric again or treat one worker's local score as a global result. For custom backends, use the installed Ray version's documented extension points and test lifecycle/cleanup behavior; a PyTorch loop is not a generic backend implementation.

## Offline sources
[PyTorch guide](upstream/pytorch-training.txt), [loop API](upstream/train-loop.txt), and [license](upstream/LICENSE.txt).
