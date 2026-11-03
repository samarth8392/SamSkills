# Structured critique and revision

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## A reproducible critique loop
The Constitutional AI paper investigates using critiques and revisions to create supervised training examples, and reasoning during AI preference judgments. Use the paper for the experiment design; the following is a compact local evaluation workflow.

1. Preserve the initial prompt and candidate response.
2. Select a principle from the versioned constitution.
3. Request a concise assessment: applicable principle, problematic passage if any, and the required change. Ask for an evidence-based summary, not access to a model's private reasoning.
4. Generate a revised response that addresses the identified problem while retaining useful information.
5. Evaluate the revision separately. A convincing critique does not establish that the revision is correct.
6. Save prompt, original response, principle ID, assessment, revision, model versions, and evaluation outcome as distinct fields.

Test benign requests, genuinely prohibited requests, ambiguous cases, and attempts to manipulate the judge through quoted text. Separate trusted judging instructions from untrusted candidate content. Compare critique-assisted revisions with a direct-revision baseline and report whether helpfulness changes.

Do not publish invented benchmark gains or treat a model-written explanation as evidence of its internal decision process.

## Offline source
[Bai et al., Constitutional AI (2022)](upstream/constitutional-ai-bai-2022.pdf), with [attribution](upstream/NOTICE.txt).
