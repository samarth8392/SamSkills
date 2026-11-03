# Adapting Llama Guard categories

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## Keep the taxonomy explicit
The [local model card](upstream/model-card.txt) defines the categories and intended use of Llama Guard 3-8B. Category IDs belong to that model's taxonomy; do not reuse a category number from another Llama Guard release without checking its meaning.

A custom rubric in a prompt and a fine-tuned classifier are different interventions. Changing a label name does not establish reliable classification of a new domain. Start by documenting the domain rule, examples, counterexamples, and desired handling of uncertain outputs.

## Validation workflow
Create a held-out, human-reviewed set before changing prompts or weights. Measure false positives and false negatives by category, language, input length, and whether the model is judging a user request or an assistant response. Keep ambiguous cases separate.

For fine-tuning, record the base checkpoint, tokenizer/chat template, training examples, taxonomy version, and evaluation protocol. Compare the adapted model with the unmodified baseline. Treat generated category output as structured data: validate the allowed labels and handle malformed output explicitly.

The original skill's promise of a domain-specific fine-tuning recipe was not accompanied by that recipe upstream. This guide provides a validation plan rather than claiming a recovered training implementation.

## Local sources
[Overview](upstream/overview.txt), [model card](upstream/model-card.txt), [license](upstream/LICENSE.txt), and [usage policy](upstream/USE_POLICY.txt). Built with Llama; see [notice](upstream/NOTICE.txt).
