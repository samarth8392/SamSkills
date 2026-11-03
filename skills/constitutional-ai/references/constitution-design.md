# Designing a constitution

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## Purpose
A constitution is an explicit set of principles used to critique responses and generate preference judgments. It is a training input, not proof that a resulting model will follow every principle.

## Local design workflow
1. Define the application and the people affected by its responses.
2. Write a short, versioned principle list. Give each principle an identifier and explain what happens when two principles conflict.
3. For every principle, collect a permitted example, a prohibited example, and an ambiguous example. Keep an evaluation set separate from training.
4. Ask a judge to identify the applicable principle and whether a response needs revision. Review disagreements before generating labels at scale.
5. Measure both harmful assistance and unnecessary refusal. A system that refuses everything has not solved the task.
6. Record the constitution version with the judge, policy checkpoint, examples, and evaluation results.

These are proposed maintenance practices, not a reproduction of a production Claude constitution. The paper describes critique/revision during supervised training followed by AI preference feedback during reinforcement learning.

## Offline source
[Bai et al., Constitutional AI (2022), unchanged paper](upstream/constitutional-ai-bai-2022.pdf). See [source attribution](upstream/NOTICE.txt).
