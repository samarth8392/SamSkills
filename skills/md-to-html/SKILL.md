---
name: md-to-html
version: 1.0.0
description: >
  Use when asked to convert a Markdown file or pasted Markdown content into a
  polished, self-contained HTML document matching the peer-review aesthetic:
  warm off-white background, card-framed sections, severity badges, pills,
  Tabler icons, and responsive single-column shell. No frameworks. No external
  CSS. Output is always one complete .html file.
  Trigger phrases: "convert to html", "make this look good", "nice html",
  "render this md", "turn into webpage", "$md-to-html".
skills_used:
  - scientific-agent-skills:document-skills
  - scientific-agent-skills:scientific-writing
author: user
---

# md-to-html

Convert any Markdown file into a polished, self-contained HTML document that
matches the peer-review aesthetic: warm off-white background, card-framed
sections, clean typography, severity badges, and a responsive single-column
shell. No frameworks, no CDN dependencies beyond Tabler Icons.

---

## Trigger

Use when the user provides a `.md` file or pastes Markdown content and asks
for an HTML version, a "nice HTML", a "rendered version", or similar.
Also activate on: "convert this to HTML", "make this look good", "turn this
into a webpage", "$md-to-html".

---

## Design system (apply to every conversion)

### Tokens
```
Background:    #f8f7f4
Surface:       #ffffff
Border:        #e0ddd5
Border-light:  #f0ede6
Text:          #1a1a1a
Text-mid:      #333333
Text-muted:    #666666
Text-dim:      #888888 / #aaaaaa

Red:    #a32d2d  bg #fcebeb  bd #f7c1c1
Amber:  #854f0b  bg #faeeda  bd #fac775
Green:  #3b6d11  bg #eaf3de  bd #c0dd97
Blue:   #185fa5  bg #e6f1fb  bd #b8d4f0
Violet: #534ab7  bg #eeedfe  bd #c9c6f4
Teal:   #0f6e56  bg #e1f5ee  bd #9ed4c6
Pink:   #993556  bg #fbeaf0  bd #f0b8cc

Border-radius: 10px (cards), 12px (outer shell), 8px (small), 20px (pills)
Shadow:        0 1px 3px rgba(0,0,0,0.06)
Font:          system-ui, -apple-system, sans-serif
Mono:          JetBrains Mono, Fira Code, ui-monospace, monospace
Icon CDN:      https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.31.0/dist/tabler-icons.min.css
```

### Base CSS (include verbatim in every output)
```css
*{box-sizing:border-box;margin:0;padding:0}
body{font-family:system-ui,-apple-system,sans-serif;background:#f8f7f4;
     color:#1a1a1a;line-height:1.75;font-size:15px}
.shell{max-width:860px;margin:0 auto;padding:2rem 1.5rem 4rem}

/* Header card */
.header{background:#fff;border:0.5px solid #e0ddd5;border-radius:12px;
        padding:2rem 2rem 1.5rem;margin-bottom:2rem}
.ms-title{font-size:20px;font-weight:500;color:#1a1a1a;line-height:1.4;
          margin-bottom:0.75rem}
.ms-sub{font-size:13px;color:#666;margin-bottom:1rem}

/* Badge row */
.badge-row{display:flex;flex-wrap:wrap;gap:8px;margin-bottom:1.25rem}
.badge{font-size:11px;font-weight:500;padding:3px 10px;border-radius:20px;
       letter-spacing:0.03em;display:inline-flex;align-items:center;gap:5px}

/* Section cards */
.section{background:#fff;border:0.5px solid #e0ddd5;border-radius:12px;
         padding:1.75rem 2rem;margin-bottom:1.25rem}
.section-header{display:flex;align-items:center;gap:10px;margin-bottom:1.25rem}
.section-icon{width:32px;height:32px;border-radius:8px;display:flex;
              align-items:center;justify-content:center;flex-shrink:0;font-size:16px}
.section-title{font-size:17px;font-weight:500;color:#1a1a1a}

/* Prose */
.prose p{font-size:14px;color:#333;line-height:1.75;margin-bottom:0.85rem}
.prose p:last-child{margin-bottom:0}
.prose h3{font-size:14px;font-weight:500;color:#185fa5;border-bottom:0.5px solid
          #f0ede6;padding-bottom:0.3rem;margin:1.25rem 0 0.6rem}
.prose ul,.prose ol{font-size:14px;color:#333;line-height:1.75;
                    padding-left:1.5rem;margin-bottom:0.85rem}
.prose li{margin-bottom:0.35rem}
.prose code{font-family:"JetBrains Mono","Fira Code",ui-monospace,monospace;
            font-size:12px;background:#eeedfe;border:0.5px solid #c9c6f4;
            border-radius:4px;padding:1px 5px;color:#534ab7}
.prose pre{background:#fafaf8;border:0.5px solid #e0ddd5;border-radius:8px;
           padding:1rem 1.2rem;overflow-x:auto;margin-bottom:0.85rem}
.prose pre code{background:none;border:none;padding:0;color:#1a1a1a}
.prose blockquote{border-left:3px solid #b8d4f0;padding:0.4rem 0.85rem;
                  background:#f8fafd;border-radius:0 6px 6px 0;
                  font-style:italic;color:#444;margin-bottom:0.85rem;
                  font-size:13.5px;line-height:1.65}
.prose hr{border:none;border-top:0.5px solid #e0ddd5;margin:1.25rem 0}
.prose a{color:#185fa5;text-decoration:none}
.prose a:hover{text-decoration:underline}
.prose table{width:100%;border-collapse:collapse;font-size:13px;
             margin-bottom:0.85rem}
.prose th{background:#f8f7f4;color:#888;font-size:10.5px;font-weight:500;
          text-transform:uppercase;letter-spacing:0.06em;
          padding:0.55rem 0.9rem;border-bottom:0.5px solid #e0ddd5}
.prose td{padding:0.5rem 0.9rem;border-bottom:0.5px solid #f0ede6;
          color:#333;vertical-align:top}
.prose tr:last-child td{border-bottom:none}
.prose tr:hover td{background:#faf9f7}

/* Pills */
.pill{font-size:11px;padding:3px 10px;border-radius:20px;border:0.5px solid;
      display:inline-block}
.pill-missing{background:#fcebeb;color:#a32d2d;border-color:#f7c1c1}
.pill-partial{background:#faeeda;color:#854f0b;border-color:#fac775}
.pill-ok{background:#eaf3de;color:#3b6d11;border-color:#c0dd97}
.pill-blue{background:#e6f1fb;color:#185fa5;border-color:#b8d4f0}

/* TOC */
.toc{background:#fff;border:0.5px solid #e0ddd5;border-radius:10px;
     padding:1.25rem 1.5rem;margin-bottom:2rem}
.toc-title{font-size:12px;text-transform:uppercase;letter-spacing:0.07em;
           color:#888;margin-bottom:0.75rem}
.toc-list{list-style:none;display:flex;flex-direction:column;gap:2px}
.toc-list a{font-size:13px;color:#185fa5;text-decoration:none;
            display:flex;align-items:center;gap:6px;padding:3px 0}
.toc-list a:hover{color:#0c447c}
.toc-n{font-size:11px;color:#aaa;min-width:16px}
```

---

## Conversion rules

### 1. Document structure

Wrap everything in:
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{{INFERRED_TITLE}}</title>
  <link rel="stylesheet"
    href="https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.31.0/dist/tabler-icons.min.css">
  <style>
    /* paste base CSS here */
  </style>
</head>
<body>
<div class="shell">
  <!-- content -->
</div>
</body>
</html>
```

### 2. Markdown → HTML element mapping

| Markdown | HTML output |
|---|---|
| `# H1` at top of file | `.header` card with `.ms-title` |
| `## H2` | `.section` card with `.section-header` + `.section-icon` + `.section-title` |
| `### H3` | `<h3>` inside `.prose` |
| Body paragraphs | `<p>` inside `.prose` |
| `- list` / `1. list` | `<ul>`/`<ol>` inside `.prose` |
| `` `inline code` `` | `<code>` with violet pill style |
| ` ```block``` ` | `<pre><code>` |
| `> blockquote` | `<blockquote>` with blue left border |
| `---` | `<hr>` |
| `[text](url)` | `<a>` in blue |
| `**bold**` | `<strong>` |
| `*italic*` | `<em>` |
| `\| table \|` | `<table>` inside `.prose` |

### 3. Section icon assignment

Pick a Tabler icon for each `##` section based on its title keyword:

| Keyword | Icon class | Icon bg / fg |
|---|---|---|
| overview, summary, abstract | `ti-telescope` | `#eeedfe` / `#534ab7` |
| method, approach, how | `ti-settings` | `#e1f5ee` / `#0f6e56` |
| result, finding, data | `ti-chart-bar` | `#e6f1fb` / `#185fa5` |
| discussion, interpret | `ti-message-dots` | `#faeeda` / `#633806` |
| conclusion, summary | `ti-flag` | `#eaf3de` / `#3b6d11` |
| limitation, caveat, warning | `ti-alert-triangle` | `#faece7` / `#993c1d` |
| reference, citation | `ti-books` | `#e6f1fb` / `#185fa5` |
| reproducib, code, software | `ti-code` | `#e1f5ee` / `#0f6e56` |
| statistic, analysis | `ti-math` | `#fbeaf0` / `#993556` |
| introduction, background | `ti-info-circle` | `#eeedfe` / `#534ab7` |
| (default) | `ti-file-text` | `#f8f7f4` / `#888` |

### 4. Peer-review-specific patterns

When the Markdown is a peer review document, apply these additional rules:

**Verdict strip** — count Critical, Major, Minor, and Specific items in the document and render a 4-card `.verdict` grid immediately after the header. Use `.v-critical`, `.v-major`, `.v-minor`, `.v-flag` for colors.

**Consensus distribution bar** — render a `.consensus` block below the verdict strip with one row per severity level. Bar widths are proportional to the max count (max = 100%). Colors: critical `#e24b4a`, major `#ef9f27`, minor `#639922`, specific `#378add`.

**Reviewer tags** — when a `### heading` or paragraph starts with "Raised by R1, R2..." extract the reviewer list and render `.rtag .rt1`–`.rt5` chips (violet, teal, pink, blue, amber).

**Major comment cards** — each `### Major Comment N:` heading becomes a `.major-card` with:
- `.major-card-header` containing the title and a `.severity` badge
- Severity: CRITICAL (sev-critical, red) if the overview calls it critical; MAJOR (sev-major, amber) otherwise
- Reviewer count in badge: e.g. `MAJOR · 5/5`

**Minor comments** — numbered list items become `.minor-list` with `.minor-item` + `.minor-n` number badge.

**Specific comments** — `### Figure N` and `### Lines N–N` headings become `.spec-block` with a `.spec-label` that prepends a Tabler icon (`ti-photo` for figures, `ti-align-left` for line references).

**Reproducibility pill rows** — if a Reproducibility section contains a list of items with present/absent/partial status, render as `.pill-row` with `.pill-missing`, `.pill-partial`, `.pill-ok`. Infer status from keywords: absent/missing/not reported → missing; present but incomplete/partial → partial; confirmed/provided → ok.

**Add to CSS for all peer reviews:**
```css
.verdict{display:grid;grid-template-columns:repeat(auto-fit,minmax(140px,1fr));gap:10px;margin-bottom:2rem}
.vcard{background:#fff;border:0.5px solid #e0ddd5;border-radius:10px;padding:1rem 1.1rem}
.vcard-label{font-size:11px;color:#888;text-transform:uppercase;letter-spacing:0.06em;margin-bottom:6px}
.vcard-value{font-size:22px;font-weight:500;line-height:1}
.vcard-sub{font-size:11px;color:#888;margin-top:4px}
.v-critical{color:#a32d2d}.v-major{color:#854f0b}.v-minor{color:#3b6d11}.v-flag{color:#185fa5}
.consensus{background:#f8f7f4;border:0.5px solid #e0ddd5;border-radius:10px;padding:1rem 1.25rem;margin-bottom:1.5rem}
.consensus-title{font-size:11px;text-transform:uppercase;letter-spacing:0.07em;color:#888;margin-bottom:0.75rem}
.consensus-row{display:flex;align-items:center;gap:10px;margin-bottom:6px}
.consensus-label{font-size:12px;color:#555;min-width:70px}
.consensus-bar{flex:1;height:6px;border-radius:3px;background:#e8e5dd;overflow:hidden}
.cbar-fill{height:100%;border-radius:3px}
.cb-critical{background:#e24b4a}.cb-major{background:#ef9f27}
.cb-minor{background:#639922}.cb-specific{background:#378add}
.consensus-count{font-size:11px;font-weight:500;min-width:24px;text-align:right}
.major-card{border:0.5px solid #fac775;border-radius:10px;padding:1.25rem 1.5rem;margin-bottom:1rem;background:#fffcf5}
.major-card-header{display:flex;align-items:flex-start;justify-content:space-between;gap:12px;margin-bottom:0.75rem}
.major-card-title{font-size:14px;font-weight:500;color:#1a1a1a;line-height:1.4}
.severity{font-size:10px;font-weight:500;padding:2px 8px;border-radius:20px;white-space:nowrap;flex-shrink:0;margin-top:2px}
.sev-critical{background:#fcebeb;color:#a32d2d;border:0.5px solid #f7c1c1}
.sev-major{background:#faeeda;color:#854f0b;border:0.5px solid #fac775}
.reviewer-tags{display:flex;gap:4px;flex-wrap:wrap;margin-bottom:0.6rem}
.rtag{font-size:10px;padding:2px 7px;border-radius:12px;font-weight:500}
.rt1{background:#eeedfe;color:#534ab7}.rt2{background:#e1f5ee;color:#0f6e56}
.rt3{background:#fbeaf0;color:#993556}.rt4{background:#e6f1fb;color:#185fa5}
.rt5{background:#faeeda;color:#854f0b}
.major-card p{font-size:14px;color:#333;line-height:1.7}
.minor-list{list-style:none;display:flex;flex-direction:column;gap:0}
.minor-item{display:flex;align-items:flex-start;gap:12px;padding:0.75rem 0;border-bottom:0.5px solid #f0ede6}
.minor-item:last-child{border-bottom:none}
.minor-n{font-size:11px;font-weight:500;color:#888;min-width:20px;padding-top:3px}
.minor-item p{font-size:14px;color:#333;line-height:1.65}
.spec-block{margin-bottom:1.25rem;padding-bottom:1.25rem;border-bottom:0.5px solid #f0ede6}
.spec-block:last-child{border-bottom:none;margin-bottom:0;padding-bottom:0}
.spec-label{font-size:12px;font-weight:500;color:#185fa5;margin-bottom:0.5rem;display:flex;align-items:center;gap:6px}
.spec-block p{font-size:14px;color:#333;line-height:1.7}
.reviewer-line{margin-top:1rem;padding-top:1rem;border-top:0.5px solid #e8e5dd;display:flex;align-items:flex-start;gap:10px;font-size:13px;color:#555}
.reviewer-dots{display:flex;gap:6px;margin-top:2px}
.rdot{width:8px;height:8px;border-radius:50%;flex-shrink:0}
```

### 5. Auto-detect and render special patterns

**Callout blocks** — if a blockquote starts with `[!NOTE]`, `[!WARNING]`,
`[!TIP]`, or `[!IMPORTANT]`, render as a colored callout:
```html
<div class="callout callout-note">
  <strong>Note</strong>
  <p>...</p>
</div>
```
Add to CSS:
```css
.callout{border-radius:10px;padding:0.85rem 1rem;margin-bottom:0.85rem;
         font-size:14px;line-height:1.7}
.callout-note{border-left:3px solid #185fa5;background:#e6f1fb}
.callout-warning{border-left:3px solid #854f0b;background:#faeeda}
.callout-tip{border-left:3px solid #0f6e56;background:#e1f5ee}
.callout-important{border-left:3px solid #a32d2d;background:#fcebeb}
```

**Badge rows** — if the first `##` section header line is followed by a
metadata block (lines like `Date: ...`, `Author: ...`, `Status: ...`),
render those as `.badge` elements in a `.badge-row` before the title.
Choose badge color by key:
- Date → teal
- Author, reviewer → violet
- Status, stage → amber
- Version → blue
- Field, topic → green

**Pill rows** — if a list item matches the pattern `- [MISSING] text`,
`- [PARTIAL] text`, or `- [OK] text`, render as `.pill pill-missing`,
`.pill-partial`, or `.pill-ok` respectively inside a `.pill-row` div.

**TOC** — if the document has 3 or more `##` sections, auto-generate a TOC
card after the header and before the first section. Assign slugified IDs to
each section and link to them.

### 5. Output rules

- Output is a single fully self-contained `.html` file.
- Do NOT use external CSS files — all styles are inlined in `<style>`.
- Do NOT use JavaScript unless the source MD explicitly contains interactive
  elements (checkboxes, toggles). If JS is needed, add it before `</body>`.
- Preserve all source text verbatim — do not summarise, paraphrase, or omit.
- If the MD has a YAML front matter block (`---` ... `---`), extract
  `title`, `author`, `date`, `subtitle` and render them in the `.header` card.
  Do not render the raw YAML.
- Image references (`![alt](src)`) → render as
  `<img src="src" alt="alt" style="max-width:100%;border-radius:8px;margin:0.85rem 0">`.
  Note in a comment if the image path is local and may not resolve.

### 6. Quality checks before outputting

- Every `##` heading has a `.section` card with an icon.
- All inline code uses the violet pill style.
- Tables have sticky `<thead>` with uppercase dim headers.
- The output is valid HTML5 — no unclosed tags.
- The `<title>` matches the document's `# H1` or YAML title.
- If the source is longer than ~400 lines, a TOC is always present.

---

## Example invocation

User: "convert this md to html" + pastes or uploads a .md file

Response: a single complete HTML artifact, no explanation needed unless
the user asks why specific design choices were made.
