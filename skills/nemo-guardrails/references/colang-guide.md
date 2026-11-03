# Colang 2 flows and actions

> SamSkills replacement reference, written during repository maintenance on 2026-11-03. The original skill linked to this filename, but the document was absent from the checked local collections and upstream skill repository. This is a new guide, not a recovered Orchestra Research document. Official sources retain their own authorship and licenses.

## Use one language version consistently
Colang 2 represents interaction patterns through flows, events, and actions. Do not combine a Colang 1 configuration example with Colang 2 syntax without following a migration path.

The bundled [introduction](upstream/colang-introduction.txt), [flow reference](upstream/colang-flows.txt), and [Python action guide](upstream/python-actions.txt) contain official syntax and examples captured at the revision recorded in this skill's source manifest.

## Reading a flow
A flow has a name, optional input/output parameters, and an interaction pattern. Variables use a `$` prefix. Starting an action or flow and waiting for it to finish are distinct operations; use the documented `start`, `await`, and event matching behavior for the intended sequencing.

## Build incrementally
Start with one deterministic interaction. Add a parameter, then one Python action, and test both successful completion and failure. Record which events are emitted and which flow is waiting for them. Introduce model-generated behavior only after this basic execution path works.

Keep external service calls behind actions with validated inputs and explicit failures. Do not assume that a flow description alone implements an action or installs its dependencies.

## Local sources
Read the three source snapshots above for the complete captured examples. Their MDX formatting is retained as plain text; repository-relative links inside them refer to upstream. [License](upstream/LICENSE.txt) and [Apache terms](upstream/LICENSE-Apache-2.0.txt).
