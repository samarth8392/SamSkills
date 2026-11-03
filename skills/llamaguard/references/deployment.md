# Deploying a Llama Guard classifier

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## Prepare the classifier
Select a specific model and revision, obtain its weights through the documented access process, and use the matching tokenizer and conversation template. The [local usage guide](upstream/usage.txt) and [model card](upstream/model-card.txt) document the captured model; weights are not part of this skill bundle.

## Service contract
Accept a validated conversation and an explicit input/output-moderation mode. Bound input length, validate role ordering, parse only the expected classification/category vocabulary, and return an explicit failure state for invalid output or timeouts. A service error must not silently become a successful classification.

## Deployment sequence
1. Establish a single-device correctness and latency baseline.
2. Add bounded batching and concurrency, then load-test representative lengths.
3. Test startup, readiness, timeout, and restart behavior.
4. For Kubernetes or SageMaker, size accelerator resources from measurements and pin the serving image and model revision. Choose the platform's supported serving integration; the source skill did not ship a verified platform-specific deployment template.
5. Monitor queue time, model time, parsing failures, and category distributions. Recheck accuracy after quantization or template changes.

## Local sources
[Overview](upstream/overview.txt), [model card](upstream/model-card.txt), [license](upstream/LICENSE.txt), and [usage policy](upstream/USE_POLICY.txt). Built with Llama; [notice](upstream/NOTICE.txt).
