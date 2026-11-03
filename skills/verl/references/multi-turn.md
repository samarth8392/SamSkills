# Multi-turn tool rollouts in verl

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## Use the matching rollout configuration
The [official multi-turn guide](upstream/multiturn.txt) and [search-tool example](upstream/search-tool-example.txt) are bundled locally. The captured guide uses SGLang and documents its multi-turn settings, tool configuration, and stateful/stateless tool interfaces. Configuration structure has changed across releases: use the schema for the installed revision, not a mixture of snippets from different versions.

## Implement the tool contract
Describe the tool schema and validate model-generated arguments before invocation. For a stateful tool, implement the documented creation, execution, and release lifecycle. Keep each rollout's state isolated and release resources even when a tool fails. The guide also documents a function-tool option for stateless behavior.

Set bounds on turns, tool calls, response length, timeouts, and concurrency. Preserve tool results and turn boundaries in the trajectory. Confirm that the reward is attached to the intended outcome and that environment/tool tokens are handled according to the training implementation rather than blindly treated as policy-generated tokens.

## Smoke test before training
Exercise a successful call, invalid arguments, a timeout, and an empty result with one rollout. Inspect the recorded trajectory and reward, then test concurrent rollouts for state leakage. Only then increase rollout concurrency or launch policy training.

## Offline sources
[Multi-turn documentation](upstream/multiturn.txt), [worked search example](upstream/search-tool-example.txt), and [license](upstream/LICENSE.txt).
