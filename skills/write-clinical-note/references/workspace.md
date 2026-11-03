# Bundled DSM reference library

## Locate the included files

`SKILL_ROOT` means the directory containing this skill's `SKILL.md`, wherever the folder
has been copied. Resolve paths from that directory, **not** the current working directory.
The complete library is included; no original repository, configured home directory or
environment variable is required.

| Resource | Path from SKILL_ROOT |
|---|---|
| Human-readable index | `references/dsm5tr/INDEX.md` |
| Machine-readable index | `references/dsm5tr/index.json` |
| Chapter and disorder notes | `references/dsm5tr/chapters/` |
| Clinical retrieval guide | `references/dsm5tr/AGENT_GUIDE.md` |
| Coverage and source audit | `references/dsm5tr/PROGRESS.md`, `references/dsm5tr/SOURCE_AUDIT.md` |
| Original source PDF | `references/source/DSM 5 TR-APA (2022).pdf` |
| Page-marked source extracts | `references/source/dsm5tr_text/` |
| Lookup and maintenance tools | `scripts/` |

Read [AGENT_GUIDE.md](dsm5tr/AGENT_GUIDE.md) and [PROGRESS.md](dsm5tr/PROGRESS.md)
once per session. The other library files are loaded only as needed; do not put the
entire book into context for each note.

If the included library cannot be accessed, say so outside chart prose, draft only from
supplied encounter facts, and ask for access to the complete skill folder. Do not claim
DSM retrieval or source verification without actually reading the references. If the
user explicitly supplies an alternate library, identify it as an override and use its
own index/source relationships.

## Model-agnostic retrieval

Any assistant with access to the files can read the Markdown index and follow its
relative links. No Python, vendor API or Codex metadata is required for that workflow.
`agents/openai.yaml` is optional Codex display/invocation metadata; other runtimes can
ignore it and follow `SKILL.md` directly.

If Python 3 is available, run from SKILL_ROOT:

```bash
python3 scripts/lookup.py "Generalized Anxiety Disorder" --json --limit 5
python3 scripts/lookup.py "F43.10" --json --limit 5
```

The lookup script uses only Python's standard library and locates the bundled index
relative to itself, even when invoked from another directory. Treat names as data and
quote shell arguments safely. Open returned files relative to `references/dsm5tr/`,
along with their chapter overview and key differential notes. JSON metadata alone is
insufficient. Search rank is retrieval relevance, not diagnostic probability.

For clinical reasoning, check actual core features, thresholds, duration/frequency,
age/context, required impairment, substance/medical explanations and specifiers.
Distinguish supported, contradicted, unclear and unassessed evidence. Consult a chapter's
`_coverage.md` and cited source pages for consequential ambiguities.

Page citations are 1-based PDF positions; printed-book and PDF pagination differ.
The library describes **DSM-5-TR, APA 2022**, and does not verify later billing updates.
Metadata codes may describe associated conditions or differentials. Read the Coding
section before suggesting a source-edition code. Verify applicable current official
coding separately when requested; keep an unverified source-code caveat outside chart
prose. Preserve clinician-supplied codes while flagging apparent discrepancies.

## Included writing sources and maintenance

- [HOPI.txt](source/HOPI.txt): original HPI writing model.
- [Assessment Impression.txt](<source/Assessment Impression.txt>): original formulation model.
- [tabs.png](source/tabs.png): EHR tab labels.
- [template_note.txt](source/template_note.txt): background guidance, not a finished note.

The skill's style and tab references encode these models. Read original files for exact
wording/layout questions. Use examples' structure without importing hypothetical facts.

To rebuild an edited bundled index, run from SKILL_ROOT:

```bash
python3 scripts/build_index.py references/dsm5tr
```

Index rebuilding requires PyYAML; fresh PDF extraction requires pypdf. These optional
maintenance dependencies are listed in `scripts/requirements.txt`. Reading the existing
notes/index and running lookup do not require installing them. `bundle-manifest.json`
records file hashes at packaging time; historical audit host paths describe the original
work session and are not runtime dependencies.
