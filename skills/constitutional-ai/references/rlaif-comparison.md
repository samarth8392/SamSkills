# Choosing AI or human preference feedback

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## What changes
RLHF obtains preference labels from human reviewers. RLAIF obtains labels from a model, usually under an explicit rubric. Both need evaluation: automated labels can be inconsistent, biased, or sensitive to response ordering.

Lee et al. report comparable RLAIF and RLHF results on the tasks they studied. That is evidence about those experiments, not a guarantee for a new application. Their direct-RLAIF variant obtains rewards directly from a model rather than training a separate reward model.

## A practical comparison
Keep the initial policy, prompts, evaluation set, and compute budget comparable. Randomize the ordering of candidate responses. Track judge agreement with a held-out human-reviewed set and report results by task or failure category. Record abstentions and ties rather than forcing every example into a preference pair.

Estimate costs from actual labeling, adjudication, inference, reward-model training, and policy-training usage. Do not infer a fixed saving from the label source alone. Use human review for ambiguous or novel cases, and recheck agreement after changing the judge or constitution.

## Offline sources
- [Lee et al., RLAIF vs. RLHF (2024 revision)](upstream/rlaif-lee-2024.pdf)
- [Bai et al., Constitutional AI (2022)](upstream/constitutional-ai-bai-2022.pdf)
- [Attribution and license](upstream/NOTICE.txt)
