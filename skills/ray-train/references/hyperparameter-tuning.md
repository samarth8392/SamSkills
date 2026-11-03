# Ray Train with Ray Tune

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## Match the API generation
The [official tuning guide](upstream/hyperparameter-optimization.txt) documents Ray Train V2 integration. It describes a Tune trial running a driver function that constructs a trainer, while the trainer launches its own workers. Do not assume an older trainer-as-trainable example has the same interface.

## Define a bounded experiment
Choose the metric, optimization direction, search space, stopping rule, and trial budget before starting. Calculate resources per training run from its workers, then bound concurrent trials so their combined resource demands fit the cluster. The Tune driver and training workers occupy different roles.

Report metrics consistently and save resumable checkpoints. Early-stopping schedulers need comparable progress measurements. Search algorithms and schedulers serve different purposes: choosing configurations is not the same as deciding when to stop a trial. Check that any population-based training design can restore and mutate the intended state.

First run two small trials, inspect their resource allocation and metric records, and exercise a resume path. Add an optional search integration such as Optuna only after the base loop works and its dependency is installed.

## Offline source
[Complete official Train/Tune integration guide](upstream/hyperparameter-optimization.txt) and [Ray license](upstream/LICENSE.txt). The [complete example code](upstream/train_tune_interop.py.txt) is also bundled as plain text; it supplies the source guide's literal-include examples without requiring an upstream checkout.
