# NeMo Guardrails integration checklist

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## Bundled integrations
The official [Llama Guard integration](upstream/llama-guard.txt) and [Presidio integration](upstream/presidio.txt) are available locally. Use their configuration for the matching library version. Model access, endpoint credentials, and integration packages remain runtime prerequisites.

Llama Guard classifies content under a model-specific taxonomy. Presidio detects or transforms configured kinds of sensitive entities. They are different checks and do not replace each other.

## Integration sequence
1. Identify whether the check belongs before generation, after generation, or around a tool/action.
2. Verify the dependency independently using a small deterministic input.
3. Configure its input/output mapping and timeout behavior.
4. Test safe, rejected, empty, malformed, and unavailable-service cases through the entire application.
5. Check logs for unintended retention of user content or credentials.
6. Pin dependency and model versions with the application's configuration.

For a custom model, define the provider interface and test its actual response schema. The source skill mentioned ActiveFence but did not include its promised guide. Do not infer a working ActiveFence configuration from another provider's keys; obtain and pin its integration contract before enabling it.

## Local source material
[Llama Guard](upstream/llama-guard.txt), [Presidio](upstream/presidio.txt), [Python actions](upstream/python-actions.txt), [license](upstream/LICENSE.txt), and [Apache terms](upstream/LICENSE-Apache-2.0.txt).
