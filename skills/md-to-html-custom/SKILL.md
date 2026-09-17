---
name: md-to-html-custom
description: Convert a Markdown (.md) file into a single self-contained, styled HTML document using a warm off-white card-based theme with accent-colored headers, dark code blocks, and styled tables/blockquotes. Use when the user provides a .md file (or pastes markdown) and asks to convert it to HTML, render it, "make it look good", or produce a webpage version. No external CSS or JS frameworks — output is always one complete .html file with all styles inlined.
triggers: Use when the user provides a .md file or pastes markdown content and asks for an HTML version, a "styled HTML", a "rendered version", or a webpage. Also activate on "convert this to HTML", "render this markdown", "turn this into a webpage", "$md-to-html-custom".
---

# md-to-html-custom

Convert Markdown source into a polished, self-contained HTML file with a custom warm/editorial theme. Zero external dependencies — theme CSS is inlined directly into the output file.

## When to use this skill

- The user provides a `.md`/`.markdown` file and asks for an HTML render.
- The user pastes raw markdown text and wants a styled HTML version.
- The user asks to "convert to HTML", "make this look nice", or "render this markdown".

Do NOT use for PDFs, DOCX, or PPTX output — those are handled by other skills (`pdf`, `docx`, `pptx`).

## Theme spec

- Background: warm off-white (`#faf7f2`)
- Content card: white (`#ffffff`), rounded corners, subtle shadow, max-width ~900px, centered
- Ink/body text: `#2b2620`; secondary/muted text: `#6b625a`
- Accent 1 (headers, h1 underline, h2 left-border): `#b5562e` (burnt orange)
- Accent 2 (links, h3, blockquote border): `#2e6f77` (teal)
- Borders/dividers: `#e7ded2`
- Code blocks: dark background `#2b2620`, light text `#f5ead9`, rounded corners
- Inline code: light tan background `#f1e9dd`, small rounded padding
- Blockquotes: teal left border, pale teal background, rounded right corner
- Tables: bordered cells, tan header row background
- Font stack: system UI (`-apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif`)
- No external fonts, no CDN CSS, no JS frameworks — everything inlined in a single `<style>` block

## Supported markdown elements

Headers (h1–h6), bold, italic, inline code, fenced code blocks (```), links, images, blockquotes (`>`), unordered lists (`-`/`*`/`+`), ordered lists (`1.`), tables (pipe syntax with header separator row), horizontal rules (`---`/`***`/`___`), paragraphs.

Not supported (out of scope for this lightweight parser): nested/indented lists, footnotes, task-list checkboxes, definition lists, strikethrough, raw HTML passthrough. If the source markdown relies on these, note the limitation to the user rather than silently dropping content.

## Procedure

1. **Get the source markdown.**
   - If a `.md` file is provided, read it directly (`window.fs.readFile` in the analysis/artifact environment, or standard file read in a CLI/agent environment).
   - If markdown is pasted inline in the conversation, use it directly.

2. **Parse markdown to HTML** using a dependency-free parser (hand-rolled line-based parser — no external markdown library required, since it must run without CDN/npm access in constrained environments). Escape raw HTML in code spans/blocks to prevent injection artifacts.

3. **Wrap the rendered body HTML** in the theme's card layout with the full inlined `<style>` block (see Theme spec above). Use the exact CSS variables and rules from the reference implementation below so output is visually consistent across runs.

4. **Output a single, complete, self-contained `.html` file.** No external stylesheet links, no CDN imports, no JS framework dependencies. The file should open correctly by itself in any browser, offline.

5. **Naming:** name the output file after the source markdown file (e.g., `report.md` → `report.html`) unless the user specifies otherwise.

6. **If working interactively in a browser/artifact context**, prefer building this as a small self-contained HTML tool (upload/paste box + live preview + download button) rather than a one-shot static conversion, so the user can reuse it for multiple files without re-invoking the skill each time.

## Reference implementation

A complete reference implementation (parser + theme + file load/download UI) is maintained as a Claude artifact titled "Markdown → Styled HTML Converter." Reuse its `mdToHtml()` parsing logic and CSS block verbatim when regenerating this skill's output, to keep the theme consistent.

## Notes

- Always inline all CSS — never link to an external stylesheet, since the output must be portable as a single file.
- Only pull scripts from `https://cdnjs.cloudflare.com` if absolutely necessary; this skill's default implementation needs no external libraries at all.
- If the input markdown contains elements outside the "Supported markdown elements" list, flag this to the user briefly rather than failing silently.
