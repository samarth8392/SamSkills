# SamSkills

A self-contained collection of agent skills for research, machine learning, engineering, life sciences, R, design, and writing. Browse the **searchable website** instead of a long inventory table.

## Browse locally

```bash
python3 -m http.server 8000 --bind 127.0.0.1 --directory site
```

Open **http://localhost:8000**. The prebuilt website needs no package installation, API key, backend, remote fonts, or CDN. Serve `site/` from any static host; it also works under a repository subpath such as `/SamSkills/`. Opening `index.html` directly with `file://` will not load the JSON index.

- Search folder names, descriptions, topics, provider mentions, and full `SKILL.md` instructions.
- Filter by topic and agent classification; optionally show one folder per declared skill name.
- View author credits and source links in each listing and its details. Author names link to an explicitly provided URL or their declaration in `SKILL.md`; bundled copyright notices link to the license. Related GitHub projects are labeled separately and do not establish skill authorship. Generic `author: user` is not treated as an identified author.
- Open details for classification evidence, audit findings, instructions, and installation commands.
- Share a search URL or a link to a particular skill.
- Download [the JSON catalog](site/data/catalog.json) or use [skills.csv](skills.csv).

## Collection and audit

The initial audit indexed **247 skill folders**, representing **202 distinct declared names**. **95 external symlinks** were replaced by verified local copies, including supporting files. No symlinks remain under `skills/`. The 45 duplicate-name groups were retained; choose one variant per name when installing. Counts are regenerated in [the audit report](docs/AUDIT.md).

| Agent classification | Initial count | Meaning |
| --- | ---: | --- |
| Model-agnostic | 235 | No agent-specific requirement detected, or reviewed as portable |
| Multi-platform | 8 | Documents multiple agents or a generic fallback |
| Claude-oriented | 3 | Uses Claude-specific conventions or tool names |
| OpenAI / Codex-oriented | 1 | References Codex agent configuration |

These are static assessments, **not tested runtime guarantees**. A skill about OpenAI, Anthropic, or Gemini is not necessarily tied to that agent. Optional `agents/openai.yaml` metadata does not make a skill Codex-only. Some agent-agnostic workflows still call vendor-specific models or services; details show provider mentions separately. “Oriented” means adaptation may be needed, not that use elsewhere is impossible.

The audit checks front matter, duplicate names/instructions, symlinks, environment-specific paths, and relative Markdown links in `SKILL.md`. It does not execute the skills or certify all supporting code, external APIs, or licenses. All 23 originally reported broken reference links now resolve locally. The 17 distinct documents were also absent upstream, so clearly labeled replacement guides were added with official documentation snapshots, research PDFs, licenses, and pinned provenance. See [reference repairs](docs/REFERENCES.md). Self-contained files do not eliminate runtime packages, MCP servers, API credentials, model downloads, or user-supplied data.

Provenance and original SHA-256 checksums for materialized files are in [catalog/vendored.json](catalog/vendored.json). Original source locations are historical records, not dependencies. Existing skill licenses and attributions remain with their folders; this repository does not relicense them.

## Install a skill

Clone the repo and copy an entire skill folder, including its references and scripts. For example, from the repository root:

```bash
# Project-local Agent Skills directory
mkdir -p .agents/skills
cp -R skills/pdf .agents/skills/

# Or a Claude Code project directory
mkdir -p .claude/skills
cp -R skills/pdf .claude/skills/
```

Use your agent's configured skill directory for global installation. Check the skill's setup requirements before invoking it. Avoid copying every folder at once: some variants declare the same skill name, and workflows may have different prerequisites.

## Maintain the library

Requires Python 3.10+; tests also use Node 22+.

```bash
python3 -m pip install -r requirements-catalog.txt

# Preview external links, then copy if needed. Source files stay untouched.
python3 scripts/vendor_skills.py
python3 scripts/vendor_skills.py --apply

# Refresh website data, CSV and audit from the actual skill folders.
python3 scripts/build_catalog.py

# Verify generated outputs, structure, vendoring, and search behavior.
python3 scripts/build_catalog.py --check
python3 scripts/check_references.py
python3 -m unittest discover -s tests -p 'test_*.py'
npm test
```

Add a folder under `skills/` with YAML `name` and `description` fields at the beginning of `SKILL.md`. Regenerate the catalog after any edits. The generator preserves multiline YAML descriptions, uses folder IDs to avoid name collisions, and never executes skill code. The web interface treats skill content as text rather than executable HTML. Attribution is extracted from top-level/nested metadata, GitHub references in prose, and root license notices. It adds no author filter or search field; the original full-text instruction search is unchanged.

Classification rules live in [scripts/build_catalog.py](scripts/build_catalog.py); reviewed exceptions and explanations live in [catalog/overrides.json](catalog/overrides.json). Update those when an inference is misleading. The validation workflow checks for stale generated files on pushes and pull requests.

## Host the website

Only `site/` needs to be published. It contains the index, instructions, and static assets; repository links provide access to supporting skill files.

For **GitHub Pages**:

1. Commit and push the prepared changes when ready.
2. Under repository **Settings → Pages**, select **GitHub Actions** as the source.
3. In **Actions**, run **Publish skill library** manually.
4. Open the URL shown by the deployment job (normally `https://samarth8392.github.io/SamSkills/`).

The included workflow is manual: it does not publish on push. See GitHub's [custom Pages workflow documentation](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages). For another static host, upload `site/` as the document root; there is no build command required for the committed version.

Nothing has been published by the local audit/build. The website intentionally contains no analytics or third-party runtime requests; following repository links leaves the site.
