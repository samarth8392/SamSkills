---
name: safety-critical-coding-standards
description: Apply a 12-rule safety-critical coding standard (adapted from NASA JPL's "Power of 10") whenever writing, editing, or reviewing code in any language — Bash, Python, R, JS/Node/React, and HTML/CSS are covered explicitly, with a general-principle fallback for any other language. Covers control-flow simplicity, bounded loops, resource cleanup, function size, assertions, error handling, variable scope, input validation, metaprogramming limits, lint/warning cleanliness, indirection limits, and pre-commit review discipline. Use automatically both when the user explicitly asks for code to be written and whenever the assistant independently decides writing or editing code is the right next step in a task. Do not force rules that have no meaningful equivalent in a given language (e.g. bounded loops in HTML) — state that explicitly instead.
---

# Safety-Critical Coding Standards (adapted from NASA JPL's "Power of 10")

## When these rules apply
Apply this entire standard automatically in two cases:
1. **Explicit request** — the user says anything like "write code," "write a script," "write a
   function," or similarly asks for code to be produced.
2. **Implicit/agent-initiated** — you (the assistant) decide on your own, as part of solving a task,
   that writing or editing code is the right next step, even if the user's request didn't explicitly
   ask for code (e.g. they described a problem and code is the natural solution, or you're editing an
   existing file to fix something).

In both cases, apply the rules by default — do not wait for the user to reference this file or repeat
"follow the coding rules." The only exception is trivial, throwaway one-liners in casual conversation
(e.g. a two-line example illustrating a concept in chat) where invoking the full standard would be
disproportionate — use judgment, and lean toward applying the rules rather than skipping them.

---

Apply these rules whenever writing, editing, or reviewing code, in any language. Each rule states a
general principle first — that's the part that should hold regardless of language — followed by
concrete translations for the languages used most here (Bash, Python, R, JS/Node/React, HTML/CSS).

**This list cannot enumerate every language, and it isn't meant to.** If working in a language or
format not listed (Go, Rust, SQL, YAML/config, Dockerfile, etc.), do not skip the rule just because
it isn't named — instead: (1) restate the rule's general principle in one sentence, (2) identify that
language's closest idiomatic mechanism for satisfying it, (3) apply it, and (4) briefly say what you
chose and why. If a rule has no meaningful equivalent in that language/format at all (e.g. "bounded
loops" in a language with no loops), say so explicitly rather than forcing or fabricating an
application of it — but check that conclusion carefully, since most rules apply more often than they
first appear to (e.g. "assertions" in a markup or config language still translates to schema/lint
validation).

If a rule genuinely doesn't apply to a given task, say so explicitly rather than forcing it or
silently ignoring it.

---

## 1. Linear control flow, shallow nesting (≤2 levels)
**Principle:** code should read top-to-bottom without the reader having to hold more than two levels
of conditional/loop context in their head at once. No recursion unless it's clearly the right tool
(e.g. tree/directory traversal), and even then cap the depth explicitly.
- **Bash:** avoid nested `if`/`case` beyond 2 levels; extract into functions, or use `case` instead of
  chained `if/elif`.
- **Python:** use guard clauses / early `return`/`continue` instead of nesting `if` inside `if` inside
  `for`. Flatten with comprehensions or extracted helper functions.
- **R:** avoid nested `for`/`if` pyramids; prefer vectorized operations (`apply`/`sapply`/`purrr::map`,
  dplyr chains), which sidestep nesting almost entirely.
- **JS/React:** use early returns, optional chaining, and small extracted functions/hooks instead of
  nested `if`/callback pyramids. Nested ternaries in JSX are a common violation — extract to a
  variable or small component instead.
- **HTML/CSS:** translates to nesting depth in markup and selectors — avoid deeply nested `div` soup
  (prefer semantic elements and flat, composable structure) and avoid CSS selectors nested more than
  ~2-3 levels deep (e.g. `.card .header .title span`); use classes/BEM-style naming instead of relying
  on deep descendant selectors.

## 2. Bounded loops — explicit ceiling, no "it'll never exceed N"
**Principle:** every loop needs a real, checked upper bound in code — not an assumption about how big
the input will realistically be. If a bound can't be determined, that's a design problem to flag, not
paper over.
- **Bash:** avoid unbounded `while read` loops over external/untrusted input without a max-iteration
  guard.
- **Python/JS:** if size isn't guaranteed upstream (user input, file contents, API response), enforce
  a real cap (`MAX_ITEMS` constant + check) or chunk/paginate explicitly rather than trusting "this is
  always small."
- **R:** same principle applies to loops over file lists, API results, or user-supplied vectors —
  don't assume length is bounded just because it usually is.
- **HTML/CSS:** not applicable — markup/CSS has no loops. Note this rather than forcing it. (If
  generating HTML *from* a templating loop in another language, the loop's bound is that language's
  responsibility, covered above.)

## 3. Close everything you open — including on the error path
**Principle:** every resource acquired (file handle, socket, DB connection, lock, subprocess, temp
file) must be released on every exit path — success, early return, and error alike. Never rely on the
process ending or garbage collection to clean up.
- **Bash:** `trap 'cleanup' EXIT` for temp files, background jobs, and file descriptors, so cleanup
  fires regardless of how the script exits.
- **Python:** always use `with open(...)` and context managers for DB connections/locks/subprocesses;
  never rely on GC to close a file.
- **R:** pair every `file()`, `connection()`, or DB connection with `on.exit(close(...))` immediately
  after opening it.
- **JS/Node:** close DB pools, file handles, and streams in `finally`. In React, always clean up
  subscriptions/timers/listeners in a `useEffect` cleanup function.
- **HTML/CSS:** not applicable in the raw markup/stylesheet itself (no resources are "opened"). If the
  HTML embeds a `<script>` that opens connections (WebSocket, EventSource), that script's cleanup
  falls under the JS guidance above.

## 4. One function does one job, fits on a page (~60 lines)
**Principle:** length and single-responsibility are both checked. A function under 60 lines that
still does three unrelated things ("parse, validate, and write") still violates this — split it by
responsibility, not just by line count.
- Applies uniformly across languages. In React specifically: a component that fetches, transforms,
  *and* renders complex conditional UI is three responsibilities — split into a hook + a
  presentational component.
- **HTML/CSS:** translates to component/partial size — a single HTML file or stylesheet trying to
  define an entire page's layout, theme, and one-off overrides in one block should be split into
  reusable partials/includes and a shared stylesheet with scoped overrides, rather than one sprawling
  file.

## 5. At least two real assertions per function — fail loudly
**Principle:** guard against conditions that should never happen in correct operation (distinct from
routine input validation — see rule 8). Fail fast and visibly at the source of a problem rather than
limping on with bad state. Assertions must be side-effect-free, boolean, and paired with an explicit
recovery action on failure (raise, log-and-return-error) — never silently continue.
- **Bash:** `set -euo pipefail` at the top of every script, plus explicit checks for critical
  preconditions (`[[ -f "$file" ]] || { echo "missing $file" >&2; exit 1; }`).
- **Python:** `assert` for internal invariants, or raise a typed exception. Schema/validation
  libraries (Pydantic) count as assertions at data boundaries.
- **R:** `stopifnot()`, or the `assertthat`/`checkmate` packages.
- **JS/Node/React:** runtime schema validation at boundaries (Zod, Yup) for anything crossing an
  API/user-input boundary. TypeScript types help statically but don't survive to runtime — validate
  at the actual boundary too.
- **HTML/CSS:** translates to validation, not runtime assertion — valid, standards-compliant markup
  (an HTML validator), required attributes present (`alt` text, form labels, ARIA where needed), and
  CSS that doesn't rely on silent fallback behavior for missing values. Accessibility checks
  (contrast, semantic structure) are the closest equivalent to "catching a condition that should
  never happen."
- Don't pad the count with trivially-true checks just to hit "two" — each one should encode a real
  invariant. Where the language's type system can make an invalid state unrepresentable, that
  satisfies the spirit of this rule even without a runtime check.

## 6. Never swallow an error
**Principle:** every caught error must be handled meaningfully or explicitly re-raised/propagated. An
empty catch block is a bug hiding as a feature, not error handling.
- **Bash:** `command || true` that silently discards a real failure is the bash version of this; with
  `set -e` active, know exactly which commands you're intentionally letting fail, and comment why.
- **Python:** never bare `except:` or `except Exception: pass`. Catch specific exceptions; log or
  re-raise. Watch for `subprocess.run` calls missing `check=True`.
- **R:** avoid `tryCatch(..., error = function(e) NULL)` with no logging — log the condition message
  at minimum.
- **JS/Node:** no empty `catch {}`; always handle or log Promise rejections. In React, an error
  boundary that fails silently without logging defeats its own purpose.
- **HTML/CSS:** not directly applicable (no exceptions in markup/CSS). Closest analogue: don't rely on
  silent graceful-degradation as a substitute for fixing the underlying issue — e.g. an `<img>` with
  no `alt` and no `onerror` handling silently fails for the user with no signal that anything's wrong.

## 7. Minimal variable scope
**Principle:** declare every variable at the smallest scope that works. Avoid reaching for
outer-scope or global mutable state when a local will do.
- **Bash:** use `local` inside every function.
- **Python/JS:** avoid module-level mutable globals; prefer `const` over `let` in JS by default.
- **R:** write functions that take explicit arguments rather than reaching into the global
  environment for objects defined elsewhere in the script.
- **React:** keep state as local (component-level) as possible; lift to context/global store only
  when genuinely shared across distant components.
- **HTML/CSS:** translates to selector/style scope — avoid global CSS rules and overly broad selectors
  (e.g. bare `div { }` or `!important` overrides) that leak style beyond the component/section they're
  meant for; prefer scoped classes, CSS modules, or component-scoped styles.

## 8. Check all return values and inputs
**Principle:** every non-void call's return value must be checked or visibly, deliberately discarded.
Every function must validate what it receives from its caller rather than trusting it blindly.
- **Bash:** check `$?` or use `set -e` with `set -o pipefail` so every pipeline stage's exit status
  matters.
- **Python:** check `subprocess` return codes explicitly (`check=True` or inspect manually).
- **R:** check the result of I/O calls and any function whose return value signals success/failure.
- **JS/Node/React:** check API response status before using the body; validate function parameters at
  the top of a function, especially at module/API boundaries, rather than assuming well-formed input.
- **HTML/CSS:** translates to graceful handling of missing/failed resources — provide `alt` text as a
  fallback for images, `<noscript>` for JS-dependent content where relevant, and fallback values in
  CSS (e.g. font stacks, `@supports` for progressive enhancement) rather than assuming every resource
  loads and every browser supports every feature.

## 9. Limit macro/metaprogramming magic
**Principle:** avoid dynamic code-generation or heavy indirection that obscures what actually runs.
Prefer explicit code over "clever" dynamic dispatch when both are similarly short.
- **Bash:** avoid building commands via string concatenation + `eval` — a readability problem and a
  real injection risk.
- **Python:** minimize dynamic `exec`/`eval`; be judicious with decorators/metaclasses.
- **R:** minimize heavy non-standard evaluation (NSE) tricks and `eval(parse(...))`.
- **JS/React:** avoid `eval`/`new Function`; keep custom hooks/HOCs from becoming so abstracted that
  control flow is hard to trace.
- **HTML/CSS:** translates to avoiding inline scripting/styling as an escape hatch — minimize inline
  `<script>`/`onclick=` handlers and inline `style=` attributes in favor of external, linted files;
  these are also harder to secure (CSP) and harder to review as diffs.

## 10. Zero warnings from day one — not just zero errors
**Principle:** the bar is a clean compile/lint from the first commit, not "it happens to run."
Warnings are tomorrow's bugs — catch them early rather than retrofitting later. Treat warnings as
build-breaking where practical; never silently suppress one without a comment explaining why it's a
false positive.
- **Bash:** run everything through `shellcheck`.
- **Python:** `ruff`/`pylint`, plus `mypy --strict` if using type hints.
- **R:** `lintr`, `R CMD check`, and treat `warning()`s as bugs, not noise.
- **JS/Node/React:** ESLint with a strict config (and TypeScript strict mode, if used); CI fails the
  build on lint errors, not just runtime errors.
- **HTML/CSS:** run an HTML validator (W3C validator or equivalent) and a CSS linter (Stylelint) with
  zero errors/warnings from the start; check accessibility with an automated tool (axe, Lighthouse)
  as part of the normal workflow, not as an afterthought.

## 11. Avoid deep indirection
**Principle:** keep data flow traceable by reading the code, not by tracing runtime indirection. No
more than shallow chains of dereference/indirection/callbacks.
- **Bash:** avoid indirect variable references (`${!varname}`) except where genuinely necessary.
- **Python/R:** avoid long chains of dynamic attribute access or deeply wrapped decorators.
- **JS/React:** avoid deep optional-chaining pyramids (`a?.b?.c?.d?.e`) as a substitute for validating
  shape at the boundary; avoid excessive HOC-wrapping (`withA(withB(withC(Component)))`) in favor of
  hooks; prefer `async`/`await` over deeply nested callbacks.
- **HTML/CSS:** translates to DOM/selector depth — avoid needing to traverse many parent/child levels
  to style or select an element; deeply nested DOM structures are both a performance cost and a
  maintainability one. Flatten markup where semantically reasonable.

## 12. Every line gets read before it's committed
**Principle:** this is a human discipline, not something the AI can certify about its own output —
but the AI should make that read fast and honest, not a rubber-stamp skim.
- Never generate a diff so large it can't reasonably be read line-by-line in one sitting; split large
  changes into smaller reviewable pieces and say so.
- End any nontrivial change with a short summary of *what changed and why* — the reasoning, not a
  restatement of the diff — so the reviewer knows what to scrutinize.
- Flag anything unusual or non-obvious explicitly (a nonstandard pattern, an edge case, a deliberate
  rule exception) rather than leaving it to be noticed unprompted.
- Never present generated code as "done" or "ready to merge" — it's a draft until a human has read
  every line.

---

## Optional: notes for workflow/pipeline tools (Snakemake, Nextflow)

These aren't part of the core 12 — they're a translation note for when the general rules meet a
DAG-based tool rather than imperative code:
- Rules 1–2 (nesting, bounded loops) bind on code *inside* a `run:`/`script:` block or process body,
  not on the natural fan-out of a pipeline over samples/files — that's expected to scale with input.
- Rule 3 (resource cleanup) still applies inside `script:`/`run:` blocks; Nextflow's per-task work-dir
  isolation handles a lot of this for you, so don't force manual temp-file cleanup where the tool
  already isolates it.
- Rule 6 (never swallow errors) applies directly to `continue-on-error` (Snakemake) and
  `errorStrategy 'ignore'` (Nextflow) — restrict these to cases where a failure is genuinely expected
  and handled downstream, and document why.
- Rule 10 (zero warnings) maps to `snakemake --lint` and Nextflow's strict-syntax mode
  (`nextflow.enable.strict`).

---

**When these rules conflict with the user's explicit request** (e.g. a quick throwaway script),
default to a lighter touch but flag which rules were relaxed and why, in one short note at the end —
don't silently drop the standard.
