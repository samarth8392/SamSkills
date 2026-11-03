---
name: maryland-driver-quiz-builder
description: >
  Use when asked to build a practice test / quiz app for the Maryland driver's
  license knowledge test from the official MDOT MVA Driver's Manual PDF.
  Extracts text and sign/diagram images from the PDF, generates a verified
  question bank (50-75 questions, including image-based sign questions), and
  builds a single-page HTML quiz app with instant feedback and explanations.
  Zero tolerance for hallucinated facts — every question must be traceable to
  a specific page/section of the source PDF.
  Trigger phrases: "build the driver's license quiz", "$md-driver-quiz",
  "make the practice test from the manual".
author: user
---

# SKILL: maryland-driver-quiz-builder

## Metadata (for skills.csv / agents/openai.yaml)

```yaml
name: maryland-driver-quiz-builder
description: >
  Use when asked to build a practice test / quiz app for the Maryland driver's
  license knowledge test from the official MDOT MVA Driver's Manual PDF.
  Extracts text and sign/diagram images from the PDF, generates a verified
  question bank (50-75 questions, including image-based sign questions), and
  builds a single-page HTML quiz app with instant feedback and explanations.
  Zero tolerance for hallucinated facts — every question must be traceable to
  a specific page/section of the source PDF.
  Trigger phrases: "build the driver's license quiz", "$md-driver-quiz",
  "make the practice test from the manual".
author: user
```

---

## Why this skill is structured this way

The single hardest constraint in this task is: **every correct answer and
every explanation must be true, and traceable to the source PDF.** LLMs
generating quiz questions from memory (instead of from the extracted text)
will confidently invent numbers, distances, and fines that sound plausible
but are wrong (e.g. inventing "500 feet" when the manual says "300 feet").

So this skill is deliberately NOT "read PDF, write quiz." It is a
**5-stage pipeline with a mandatory verification gate between generation and
use**. No question reaches the final HTML file without being checked against
the extracted source text by a separate verification pass. Treat Stage 4
(Verification) as non-negotiable — do not skip it even if short on time.

---

## Prerequisites / Environment Setup

Run once at the start:

```bash
python3 -m venv venv
source venv/bin/activate   # on Windows: venv\Scripts\activate
pip install pdfplumber PyMuPDF pillow
```

- `pdfplumber` — best-in-class for extracting clean text with layout awareness
  (handles Maryland manual's two-column layout better than PyPDF2).
- `PyMuPDF` (imported as `fitz`) — used specifically for extracting embedded
  images (traffic signs, diagrams) at good resolution, and for rendering
  full pages to PNG as a fallback when a diagram is vector-drawn rather than
  an embedded raster image.
- `pillow` — image post-processing (cropping, resizing signs for web use).

Project folder structure to create:

```
md-driver-quiz/
├── source/
│   └── maryland_drivers_manual.pdf      <- the input PDF (agent already has this)
├── extracted/
│   ├── pages_text.json                  <- Stage 1 output
│   ├── images/                          <- Stage 2 output (cropped sign/diagram images)
│   │   ├── page07_img01.png
│   │   └── ...
│   └── images_manifest.json             <- Stage 2 output (metadata per image)
├── questions/
│   ├── questions_draft.json              <- Stage 3 output (unverified)
│   ├── verification_report.json          <- Stage 4 output
│   └── questions_final.json              <- Stage 4 output (verified only)
├── build_quiz.py                         <- Stage 5 script (final HTML generator)
├── quiz.html                             <- FINAL DELIVERABLE
└── scripts/
    ├── 01_extract_text.py
    ├── 02_extract_images.py
    ├── 03_generate_questions.py          <- this one is agent-authored (LLM), not scripted
    └── 04_verify_questions.py
```

---

## STAGE 0 — Setup

1. Create the folder structure above.
2. Copy/move the source PDF into `source/maryland_drivers_manual.pdf`.
3. Confirm the PDF opens and has readable text (not a scanned image-only
   PDF). Quick check:

```python
import pdfplumber
with pdfplumber.open("source/maryland_drivers_manual.pdf") as pdf:
    print(len(pdf.pages))
    print(pdf.pages[6].extract_text()[:300])  # page 7 (0-indexed page 6) should show Section 1 text
```

If this prints garbage or nothing, STOP and flag it — the PDF may need OCR
(not covered in this skill; ask the user before proceeding with OCR tools).

---

## STAGE 1 — Extract text with page/section provenance

**Goal:** every paragraph of text tagged with its page number and (where
identifiable) its Section/Letter heading, so later stages can cite sources.

Write `scripts/01_extract_text.py`:

```python
import pdfplumber
import json
import re

OUTPUT = "extracted/pages_text.json"
SOURCE = "source/maryland_drivers_manual.pdf"

section_pattern = re.compile(r"SECTION\s+(\d+)", re.IGNORECASE)
subsection_pattern = re.compile(r"^([A-Z])\.\s+(.+)$", re.MULTILINE)

pages_data = []

with pdfplumber.open(SOURCE) as pdf:
    current_section = None
    current_subsection = None
    for i, page in enumerate(pdf.pages):
        page_num = i + 1  # human-readable page number matching PDF page labels
        text = page.extract_text() or ""

        sec_match = section_pattern.search(text)
        if sec_match:
            current_section = sec_match.group(0)

        sub_matches = subsection_pattern.findall(text)
        if sub_matches:
            current_subsection = sub_matches[-1]  # last subsection heading on page

        pages_data.append({
            "page_number": page_num,
            "section": current_section,
            "subsection_letter": current_subsection[0] if current_subsection else None,
            "subsection_title": current_subsection[1] if current_subsection else None,
            "text": text,
        })

with open(OUTPUT, "w") as f:
    json.dump(pages_data, f, indent=2)

print(f"Extracted {len(pages_data)} pages to {OUTPUT}")
```

Run it. Then **manually spot-check** (agent should print and read) pages
7, 17, 33, and 43 to confirm section detection is working (these are known
section-start pages per the table of contents: Section 1 p.7, Section 4 p.17,
Section 6 p.33, Section 8 p.43).

---

## STAGE 2 — Extract sign/diagram images

**Goal:** pull out the traffic sign icons, signal diagrams, and pavement
marking illustrations as individual image files, with a manifest linking
each image to its page number and the caption/label text near it.

Write `scripts/02_extract_images.py`:

```python
import fitz  # PyMuPDF
import json
import os

SOURCE = "source/maryland_drivers_manual.pdf"
IMG_DIR = "extracted/images"
MANIFEST = "extracted/images_manifest.json"

os.makedirs(IMG_DIR, exist_ok=True)

doc = fitz.open(SOURCE)
manifest = []

# Pages known from the table of contents to contain sign/signal/marking
# graphics worth extracting. Extend this list if the agent finds more
# during review — do not silently skip pages with visual content.
TARGET_PAGES = list(range(17, 26))  # Section 4: Signs, Signals, Pavement Markings (pp 17-25)
TARGET_PAGES += [14, 30, 31, 32, 37, 38, 39, 44, 49, 53]  # scattered diagrams (speed limit sign, RR crossing, no-zones, work zone lights, disability sign, bike hand signals)

MIN_WIDTH = 40   # skip tiny decorative artifacts
MIN_HEIGHT = 40

for page_index in TARGET_PAGES:
    if page_index - 1 >= len(doc):
        continue
    page = doc[page_index - 1]
    image_list = page.get_images(full=True)

    for img_idx, img in enumerate(image_list):
        xref = img[0]
        base_image = doc.extract_image(xref)
        image_bytes = base_image["image"]
        ext = base_image["ext"]
        width = base_image["width"]
        height = base_image["height"]

        if width < MIN_WIDTH or height < MIN_HEIGHT:
            continue

        filename = f"page{page_index:02d}_img{img_idx:02d}.{ext}"
        filepath = os.path.join(IMG_DIR, filename)
        with open(filepath, "wb") as f:
            f.write(image_bytes)

        manifest.append({
            "filename": filename,
            "page_number": page_index,
            "width": width,
            "height": height,
            "caption_hint": None,  # agent fills this in manually in Stage 2b
        })

with open(MANIFEST, "w") as f:
    json.dump(manifest, f, indent=2)

print(f"Extracted {len(manifest)} images to {IMG_DIR}")
```

### STAGE 2b — Manual caption pass (REQUIRED, do not skip)

Embedded raster extraction from a PDF often pulls sign icons WITHOUT their
text labels (labels are usually separate text layers, not part of the image).
After running the script:

1. Open each extracted image file and view it.
2. Cross-reference against the corresponding page's extracted text
   (from `pages_text.json`) to identify what the image actually depicts
   (e.g. "Stop Ahead" warning sign vs "Yield Ahead" warning sign — on page 22
   these are laid out in a grid, so positional matching matters).
3. Fill in `caption_hint` in the manifest for every image with the exact
   sign/signal name as written in the manual (e.g. `"Stop Ahead"`, not
   `"stop sign warning"`).
4. If an image is unrecognizable, blank, or a rendering artifact, delete its
   manifest entry and the file. Do not guess captions — leave it out of the
   quiz entirely instead. **A missing image question is better than a
   mislabeled one.**
5. For composite grid images (e.g. page 21's regulatory sign grid, page 22's
   warning sign grid) where PyMuPDF extracts the whole grid as ONE image:
   use `PIL.Image.crop()` with manually-determined pixel boxes to cut out
   individual signs. Save each as its own file. This is slower but produces
   much better quiz questions than one giant "which of these is a wrong way
   sign" image with 30 signs in it.

Known important individual signs/diagrams to make sure exist as clean,
single-subject crops (cross-check against manifest after Stage 2b):
- Stop sign, Yield sign, Do Not Enter, Wrong Way, No U-Turn, No Left Turn,
  No Right Turn (page 21)
- Stop Ahead, Yield Ahead, Pedestrian Crossing, Deer Crossing, School
  Crossing Ahead, Railroad crossbuck (page 20, 22)
- Steady red/yellow/green traffic light diagrams (page 17-18)
- Pavement marking line-type diagrams: single broken yellow, double solid
  yellow, single solid white (page 24)
- Truck "No-Zones" diagram (page 38)
- Disability parking placard symbol (page 50)
- Bicycle hand signals (left turn / stop / right turn) (page 53)

---

## STAGE 3 — Generate draft questions (LLM authoring pass)

This stage is done by the agent's own reasoning (you, the LLM), not a
Python script. **Ground rules that override normal question-writing
instincts:**

1. **Every question must be generated by reading the actual extracted text
   for the page(s) it cites — not from general driver's-ed knowledge.**
   Before writing a question about, say, following distance, re-read the
   `pages_text.json` entry for page 15 in full. Do not rely on memory of
   "the 3-second rule" from other manuals — Maryland's manual says
   "3 to 4 seconds," cite that exact figure.
2. Every question object must include a `source_page` (int) and
   `source_quote` (a short exact substring copied from `pages_text.json`
   that supports the correct answer). This quote is NOT shown to the quiz
   user — it exists purely for the Stage 4 verification script to check
   against.
3. Distractors (wrong answers) must be plausible but must not be
   TRUE statements about some other part of the manual accidentally
   used out of context. E.g. don't make "300 feet" a wrong answer to a
   question about headlight dimming distance if 300 feet is the correct
   answer to a *different* headlight question elsewhere — that creates
   self-contradicting question pairs. Cross-check against other drafted
   questions for numeric consistency.
4. Do not invent penalty amounts, ages, distances, time periods, or
   percentages. If the manual says "at least 3 to 4 seconds," don't
   round to "3 seconds" as if it's precise — either quote the range or
   ask the question in a way the range answers cleanly (e.g. multiple
   choice options far enough apart that "3 to 4 seconds" clearly matches
   only one).
5. For image-based questions, the `image_filename` must exactly match a
   filename in `images_manifest.json` that has a non-null `caption_hint`.

### Output format — `questions/questions_draft.json`

```json
[
  {
    "id": "q001",
    "type": "text",
    "question": "What is the minimum following distance the MVA recommends under ideal driving conditions?",
    "options": [
      "1 to 2 seconds",
      "3 to 4 seconds",
      "5 to 6 seconds",
      "8 to 10 seconds"
    ],
    "correct_index": 1,
    "explanation": "The MVA recommends a minimum following distance of 3 to 4 seconds under ideal driving conditions. Increase this to 4-5 seconds or more when following vehicles that stop often, like buses or delivery vans.",
    "source_page": 15,
    "source_quote": "The MVA recommends a minimum following distance of 3 to 4 seconds under ideal driving conditions.",
    "category": "Basic Driving"
  },
  {
    "id": "q002",
    "type": "image",
    "question": "What does this sign mean?",
    "image_filename": "page21_stopsign_crop.png",
    "options": [
      "Yield to oncoming traffic",
      "Come to a complete stop",
      "No entry allowed",
      "Slow down, hazard ahead"
    ],
    "correct_index": 1,
    "explanation": "This is a Stop sign. The octagonal (eight-sided) shape always means stop \u2014 you must come to a complete stop, yield to vehicles and pedestrians in the intersection, and remain stopped until it is safe to enter.",
    "source_page": 21,
    "source_quote": "The octagonal (eight-sided) shape always means stop. You must come to a complete stop.",
    "category": "Traffic Signs"
  }
]
```

### Target distribution (50-75 questions total, aim for ~65)

Distribute roughly proportional to real MD knowledge test emphasis and
manual section length:

| Category                                   | # Questions | Source Section |
|---------------------------------------------|:-----------:|-----------------|
| Licensing requirements & GLS process         | 6           | Sec 1-2         |
| Basic driving (right-of-way, speed, following, turning) | 10 | Sec 3      |
| Traffic signals (text-based)                 | 6           | Sec 4A          |
| Traffic signs (IMAGE-based)                  | 12          | Sec 4B          |
| Pavement markings (IMAGE-based where possible) | 6         | Sec 4C          |
| Driving conditions (night, fog, rain, snow, skid, hydroplane) | 8 | Sec 5   |
| Dangerous driving (alcohol, distraction, drowsy, aggressive) | 8 | Sec 6   |
| Sharing the road (pedestrians, trucks, motorcycles, bicycles, buses) | 9 | Sec 7 |
| Crashes & traffic stops                      | 5           | Sec 8           |
| Restrictions, violations, penalties          | 5           | Sec 9           |
| Other (seatbelts, insurance, ABS, organ donor) | 4         | Sec 10          |

Do not force exactly these counts — adjust based on what's actually
extractable and verifiable. It's fine to end up with 58 or 71 instead of a
round number. **Never pad the count with a low-confidence or unverifiable
question just to hit a target.**

### Explicit list of high-value facts to turn into questions

(These are pre-checked against the source text above, so use them directly —
but still fill in exact `source_page`/`source_quote` yourself from the
actual extracted JSON, not from this list, in case OCR/extraction differs
slightly from the PDF text shown to you here.)

- Knowledge test: 25 questions, 20 minutes (p.7)
- Vision requirement: 20/40 in each eye, 140-degree field (p.7)
- Learner's Permit (Type 1): lasts up to 2 years (p.9)
- Type 2 Learner's Permit: 180 days, must hold 14 days before skills test, applicant must be 16 yrs 6 months+ (p.9)
- Practice hours under 25: 60 hours, 10 must be night (p.9-10)
- Practice hours 25+: 14 hours, 3 must be night (p.10)
- Provisional license held minimum 18 months before Driver's License (p.10-11)
- Driver's License eligibility: age 18+, 18 months provisional, no convictions in 18 months (p.11)
- BAC legal limit: .08 (p.33)
- Under 21: zero alcohol tolerance (p.33)
- Cell phone: hand-held illegal; under 18 no cell phone at all except 911 (p.35)
- Following distance: 3-4 seconds ideal, 4-5+ for buses/vans (p.15)
- Headlights: required when can't see 1000 ft ahead; dim to low beam 500 ft before oncoming, 300 ft before following (p.27)
- Passing: not within 100 ft of bridge/tunnel/intersection/RR crossing (p.16)
- School bus stop: 20 ft back, 20 ft front when red lights flashing (p.38-39)
- Bicycle passing clearance: at least 3 feet (p.40)
- Motorcyclist crash risk: 6x more likely to be hurt than car driver (p.39)
- Move Over Law fines: $110/1pt; $150/3pt if crash; $750/3pt if death/serious injury (p.45)
- Leaving scene of injury crash: up to 5 yrs / $5,000; death = felony, up to 10 yrs / $10,000 (p.43)
- Child safety seat: under 8 unless 4'9"+ tall; rear-facing under 2 (p.52)
- ADAS prevents ~40% of crashes when used properly (p.42)
- Traffic circle: yield to traffic already in circle (p.31)
- U-turn: check legality first, yield to oncoming, use outside/right lane after turn (p.15)
- Stop sign = octagon always means stop (p.20-21)
- Yield sign = triangle, red letters on white (p.20-21)
- Diamond = warning sign shape (p.20)
- Pentagon = school zone/crossing shape (p.20)
- Red-on-white circle NOT a shape used — careful not to invent shapes not in manual
- Single broken yellow = center line, 2-lane 2-way road, passing with care both directions (p.24)
- Double solid yellow = no passing either direction, left turn across allowed for driveways (p.24)
- Fog: use low beams only, plus fog lights if equipped (p.28)
- Skid: release accelerator/brake, steer INTO the skid direction, look where you want to go (p.29)
- Hydroplane: foot off gas, do NOT brake, keep straight, slow down (p.29-30)

---

## STAGE 4 — Verification gate (mandatory, automated + manual)

**This is the step that prevents hallucination from reaching the user.**
Do not treat this as optional or skip it under time pressure.

Write `scripts/04_verify_questions.py`:

```python
import json
import difflib

with open("extracted/pages_text.json") as f:
    pages = {p["page_number"]: p["text"] for p in json.load(f)}

with open("extracted/images_manifest.json") as f:
    images = {img["filename"]: img for img in json.load(f)}

with open("questions/questions_draft.json") as f:
    questions = json.load(f)

report = []
verified = []

for q in questions:
    issues = []

    # Check 1: source_page must exist in extracted text
    page_text = pages.get(q.get("source_page"))
    if page_text is None:
        issues.append(f"source_page {q.get('source_page')} not found in extracted text")

    # Check 2: source_quote must actually appear (near-exact) on that page
    quote = q.get("source_quote", "")
    if page_text and quote:
        # Normalize whitespace for comparison
        norm_page = " ".join(page_text.split())
        norm_quote = " ".join(quote.split())
        if norm_quote not in norm_page:
            # try fuzzy match as a fallback, but flag it either way for human review
            ratio = difflib.SequenceMatcher(None, norm_quote, norm_page).ratio()
            issues.append(f"source_quote not found verbatim on page {q.get('source_page')} (fuzzy ratio to full page: {ratio:.2f}) — MANUAL REVIEW REQUIRED")
    elif not quote:
        issues.append("no source_quote provided")

    # Check 3: exactly one correct_index, in range
    if not isinstance(q.get("correct_index"), int) or not (0 <= q["correct_index"] < len(q.get("options", []))):
        issues.append("correct_index missing or out of range")

    # Check 4: exactly 4 options, no duplicates
    opts = q.get("options", [])
    if len(opts) != 4:
        issues.append(f"expected 4 options, got {len(opts)}")
    if len(set(opts)) != len(opts):
        issues.append("duplicate option text found")

    # Check 5: image questions must reference a captioned image
    if q.get("type") == "image":
        fname = q.get("image_filename")
        img = images.get(fname)
        if img is None:
            issues.append(f"image_filename '{fname}' not found in manifest")
        elif not img.get("caption_hint"):
            issues.append(f"image '{fname}' has no caption_hint — cannot verify it depicts what the question claims")

    # Check 6: explanation should not contain numbers/facts absent from source_quote
    # (heuristic only — flag for human review, don't auto-fail)
    import re
    quote_numbers = set(re.findall(r"\d+", quote))
    explanation_numbers = set(re.findall(r"\d+", q.get("explanation", "")))
    extra_numbers = explanation_numbers - quote_numbers
    if extra_numbers:
        issues.append(f"explanation contains numbers not in source_quote: {extra_numbers} — VERIFY THESE MANUALLY against page {q.get('source_page')} full text")

    entry = {"id": q.get("id"), "issues": issues, "status": "PASS" if not issues else "NEEDS_REVIEW"}
    report.append(entry)

    if not issues:
        verified.append(q)

with open("questions/verification_report.json", "w") as f:
    json.dump(report, f, indent=2)

print(f"{len(verified)} / {len(questions)} passed automated checks cleanly.")
print(f"{len(questions) - len(verified)} need manual review — see verification_report.json")
```

### Mandatory manual review loop

1. Run the script.
2. For every question with `status: NEEDS_REVIEW`, the agent must:
   - Re-open the full `page_text` for that question's `source_page`.
   - Re-read it in full (not just the quote).
   - Either (a) fix the `source_quote` to an exact substring and re-run, or
     (b) confirm the flagged "extra number" is actually present elsewhere on
     the page and update `source_quote` to include it, or (c) if the fact is
     genuinely wrong or unverifiable, **delete the question** — do not
     patch it to force a pass.
3. Only questions that end in `status: PASS` (whether on first run or after
   correction) go into `questions_final.json`.
4. Re-run the script after any edits until every question in the final file
   shows PASS. Do not hand-append a NEEDS_REVIEW question directly to
   `questions_final.json` to skip this.
5. Do one last full read-through of `questions_final.json` end to end,
   checking that:
   - No two questions contradict each other on a shared fact (e.g. two
     different stated values for BAC limit).
   - Every `image_filename` file actually exists in `extracted/images/`.
   - Explanations read naturally and don't just repeat the source_quote
     verbatim in a robotic way (light paraphrasing for readability is fine
     as long as the facts are unchanged).

Write the surviving question list to `questions/questions_final.json`,
stripping the internal `source_page`/`source_quote` fields if you don't
want them visible in dev tools (optional — harmless to leave in, useful for
future re-verification if the manual is updated).

---

## STAGE 5 — Build the HTML quiz app

Write `build_quiz.py`:

```python
import json
import base64
import os

with open("questions/questions_final.json") as f:
    questions = json.load(f)

# Inline images as base64 so the final HTML is a single portable file
for q in questions:
    if q.get("type") == "image":
        img_path = os.path.join("extracted/images", q["image_filename"])
        with open(img_path, "rb") as imgf:
            b64 = base64.b64encode(imgf.read()).decode("utf-8")
        ext = q["image_filename"].split(".")[-1]
        q["image_data_uri"] = f"data:image/{ext};base64,{b64}"

questions_json = json.dumps(questions)

html_template = """<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Maryland Driver's License Practice Test</title>
<style>
  :root {
    --md-black: #1a1a1a; --md-yellow: #f0c414; --md-red: #a51c30;
    --bg: #f7f6f3; --surface: #ffffff; --border: #e2e0da;
    --correct: #1e7d32; --correct-bg: #e8f5e9;
    --incorrect: #b3261e; --incorrect-bg: #fdecea;
    --text-muted: #6b6b6b;
  }
  * { box-sizing: border-box; }
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
    background: var(--bg); margin: 0; padding: 24px; color: var(--md-black);
  }
  .app { max-width: 720px; margin: 0 auto; }
  header {
    background: var(--md-black); color: white; padding: 20px 24px;
    border-radius: 12px; margin-bottom: 20px; border-bottom: 5px solid var(--md-yellow);
  }
  header h1 { margin: 0 0 4px; font-size: 20px; }
  header p { margin: 0; color: #ccc; font-size: 13px; }
  .progress-bar { background: var(--border); height: 8px; border-radius: 4px; margin: 16px 0; overflow: hidden; }
  .progress-fill { background: var(--md-red); height: 100%; transition: width 0.3s ease; }
  .score-row { display: flex; justify-content: space-between; font-size: 13px; color: var(--text-muted); margin-bottom: 8px; }
  .card {
    background: var(--surface); border: 1px solid var(--border); border-radius: 12px;
    padding: 24px; box-shadow: 0 1px 3px rgba(0,0,0,0.06);
  }
  .category-tag {
    display: inline-block; font-size: 11px; font-weight: 600; text-transform: uppercase;
    letter-spacing: 0.04em; color: var(--md-red); background: #fceceb;
    padding: 3px 10px; border-radius: 20px; margin-bottom: 12px;
  }
  .question-text { font-size: 17px; font-weight: 600; line-height: 1.4; margin-bottom: 16px; }
  .question-image {
    display: block; max-width: 240px; max-height: 240px; margin: 0 auto 20px;
    border: 1px solid var(--border); border-radius: 8px; padding: 12px; background: white;
  }
  .options { display: flex; flex-direction: column; gap: 10px; margin-bottom: 8px; }
  .option {
    display: flex; align-items: center; gap: 12px; padding: 14px 16px;
    border: 1.5px solid var(--border); border-radius: 10px; cursor: pointer;
    transition: border-color 0.15s, background 0.15s; font-size: 15px;
  }
  .option:hover:not(.disabled) { border-color: var(--md-red); background: #fdf8f7; }
  .option input { accent-color: var(--md-red); width: 18px; height: 18px; flex-shrink: 0; }
  .option.correct { border-color: var(--correct); background: var(--correct-bg); }
  .option.incorrect { border-color: var(--incorrect); background: var(--incorrect-bg); }
  .option.disabled { cursor: default; }
  .feedback {
    margin-top: 18px; padding: 16px 18px; border-radius: 10px; font-size: 14px; line-height: 1.55;
    display: none;
  }
  .feedback.show { display: block; }
  .feedback.correct { background: var(--correct-bg); border: 1px solid #b7dfb9; }
  .feedback.incorrect { background: var(--incorrect-bg); border: 1px solid #f2c1bd; }
  .feedback-label { font-weight: 700; margin-bottom: 4px; display: block; }
  .feedback.correct .feedback-label { color: var(--correct); }
  .feedback.incorrect .feedback-label { color: var(--incorrect); }
  .actions { display: flex; justify-content: flex-end; margin-top: 20px; }
  button.next-btn {
    background: var(--md-black); color: white; border: none; padding: 12px 28px;
    border-radius: 8px; font-size: 14px; font-weight: 600; cursor: pointer; display: none;
  }
  button.next-btn.show { display: inline-block; }
  button.next-btn:hover { background: #333; }
  .results-card { text-align: center; padding: 40px 24px; }
  .results-score { font-size: 48px; font-weight: 800; margin: 8px 0; }
  .results-pass { color: var(--correct); }
  .results-fail { color: var(--incorrect); }
  .restart-btn {
    background: var(--md-red); color: white; border: none; padding: 12px 32px;
    border-radius: 8px; font-size: 14px; font-weight: 600; cursor: pointer; margin-top: 16px;
  }
  .missed-list { text-align: left; margin-top: 24px; }
  .missed-item { padding: 12px 0; border-bottom: 1px solid var(--border); font-size: 13px; }
  .missed-item:last-child { border-bottom: none; }
</style>
</head>
<body>
<div class="app">
  <header>
    <h1>Maryland Driver's License Practice Test</h1>
    <p>Based on the MDOT MVA Driver's Manual (Dec 2025 Edition) &middot; Not an official MVA product</p>
  </header>

  <div id="quiz-screen">
    <div class="score-row">
      <span id="progress-label">Question 1 of __TOTAL__</span>
      <span id="score-label">Score: 0</span>
    </div>
    <div class="progress-bar"><div class="progress-fill" id="progress-fill" style="width:0%"></div></div>

    <div class="card">
      <span class="category-tag" id="category-tag"></span>
      <div class="question-text" id="question-text"></div>
      <img id="question-image" class="question-image" style="display:none;">
      <div class="options" id="options-container"></div>
      <div class="feedback" id="feedback">
        <span class="feedback-label" id="feedback-label"></span>
        <span id="feedback-text"></span>
      </div>
      <div class="actions">
        <button class="next-btn" id="next-btn">Next Question →</button>
      </div>
    </div>
  </div>

  <div id="results-screen" style="display:none;">
    <div class="card results-card">
      <div style="font-size:14px;color:var(--text-muted);">YOUR SCORE</div>
      <div class="results-score" id="final-score"></div>
      <div id="pass-fail-msg" style="font-size:15px;margin-bottom:8px;"></div>
      <div style="font-size:13px;color:var(--text-muted);">(Real MVA test: 25 questions, need ~85% i.e. 22/25 correct to pass, 20-minute limit)</div>
      <button class="restart-btn" id="restart-btn">Try Again</button>
      <div class="missed-list" id="missed-list"></div>
    </div>
  </div>
</div>

<script>
const QUESTIONS = __QUESTIONS_JSON__;

let order = [...Array(QUESTIONS.length).keys()];
shuffleArray(order);
let current = 0;
let score = 0;
let answered = false;
let missed = [];

function shuffleArray(arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
}

function renderQuestion() {
  answered = false;
  const q = QUESTIONS[order[current]];
  document.getElementById('progress-label').textContent = `Question ${current + 1} of ${QUESTIONS.length}`;
  document.getElementById('score-label').textContent = `Score: ${score}`;
  document.getElementById('progress-fill').style.width = `${(current / QUESTIONS.length) * 100}%`;
  document.getElementById('category-tag').textContent = q.category || 'General';
  document.getElementById('question-text').textContent = q.question;

  const imgEl = document.getElementById('question-image');
  if (q.type === 'image' && q.image_data_uri) {
    imgEl.src = q.image_data_uri;
    imgEl.style.display = 'block';
  } else {
    imgEl.style.display = 'none';
  }

  const optsContainer = document.getElementById('options-container');
  optsContainer.innerHTML = '';

  // shuffle option order per-question but keep track of correct answer text
  const correctText = q.options[q.correct_index];
  const shuffledOpts = [...q.options];
  shuffleArray(shuffledOpts);

  shuffledOpts.forEach((optText, idx) => {
    const label = document.createElement('label');
    label.className = 'option';
    label.dataset.isCorrect = (optText === correctText).toString();
    label.innerHTML = `<input type="radio" name="option" value="${idx}"><span>${optText}</span>`;
    label.addEventListener('click', () => selectOption(label, correctText));
    optsContainer.appendChild(label);
  });

  document.getElementById('feedback').className = 'feedback';
  document.getElementById('next-btn').className = 'next-btn';
}

function selectOption(label, correctText) {
  if (answered) return;
  answered = true;

  const isCorrect = label.dataset.isCorrect === 'true';
  const q = QUESTIONS[order[current]];

  document.querySelectorAll('.option').forEach(opt => {
    opt.classList.add('disabled');
    if (opt.dataset.isCorrect === 'true') opt.classList.add('correct');
  });
  if (!isCorrect) label.classList.add('incorrect');

  if (isCorrect) score++;
  else missed.push(q);

  const feedbackEl = document.getElementById('feedback');
  feedbackEl.className = `feedback show ${isCorrect ? 'correct' : 'incorrect'}`;
  document.getElementById('feedback-label').textContent = isCorrect ? '✓ Correct!' : '✗ Not quite.';
  document.getElementById('feedback-text').textContent = q.explanation;

  document.getElementById('next-btn').className = 'next-btn show';
  document.getElementById('score-label').textContent = `Score: ${score}`;
}

document.getElementById('next-btn').addEventListener('click', () => {
  current++;
  if (current >= QUESTIONS.length) {
    showResults();
  } else {
    renderQuestion();
  }
});

function showResults() {
  document.getElementById('quiz-screen').style.display = 'none';
  document.getElementById('results-screen').style.display = 'block';
  const pct = Math.round((score / QUESTIONS.length) * 100);
  document.getElementById('final-score').textContent = `${score} / ${QUESTIONS.length} (${pct}%)`;
  document.getElementById('final-score').className = `results-score ${pct >= 85 ? 'results-pass' : 'results-fail'}`;
  document.getElementById('pass-fail-msg').textContent = pct >= 85
    ? "Great job — that's a passing score on the real test threshold!"
    : "Keep studying — aim for 85%+ before your real test.";

  const missedList = document.getElementById('missed-list');
  if (missed.length > 0) {
    missedList.innerHTML = '<h3 style="font-size:14px;">Review these:</h3>' +
      missed.map(q => `<div class="missed-item"><strong>${q.question}</strong><br>${q.explanation}</div>`).join('');
  } else {
    missedList.innerHTML = '<p style="color:var(--correct);font-weight:600;">Perfect score — no misses!</p>';
  }
}

document.getElementById('restart-btn').addEventListener('click', () => {
  order = [...Array(QUESTIONS.length).keys()];
  shuffleArray(order);
  current = 0; score = 0; missed = [];
  document.getElementById('results-screen').style.display = 'none';
  document.getElementById('quiz-screen').style.display = 'block';
  renderQuestion();
});

renderQuestion();
</script>
</body>
</html>
"""

html_output = html_template.replace("__QUESTIONS_JSON__", questions_json).replace("__TOTAL__", str(len(questions)))

with open("quiz.html", "w") as f:
    f.write(html_output)

print(f"Built quiz.html with {len(questions)} questions ({sum(1 for q in questions if q.get('type')=='image')} image-based).")
print("Open quiz.html directly in a browser — no server needed (images are inlined as base64).")
```

Run it. Open `quiz.html` in a browser and manually play through at least
10-15 questions (including all image questions) to confirm:
- Images render (not broken/missing).
- Clicking an option immediately shows correct answer highlighted in green,
  your wrong pick (if any) in red, and the explanation text.
- "Next Question" advances correctly and the progress bar updates.
- Final results screen shows score, pass/fail message, and a list of missed
  questions with their explanations for review.
- Refreshing/retrying reshuffles both question order and option order.

---

## Final delivery checklist (do not report "done" until all checked)

- [ ] `questions_final.json` contains only questions with verification `status: PASS`
- [ ] Every fact/number in every explanation was checked against actual PDF text, not memory
- [ ] No two questions contradict each other
- [ ] Every image file referenced actually exists and was manually confirmed to show the correct sign/diagram
- [ ] `quiz.html` opens standalone in a browser (double-click, no local server needed)
- [ ] Manually played through the full quiz at least once end-to-end
- [ ] Told the user: question count, category breakdown, and reminded them this is a study aid, not an official MVA product (manual is copyrighted by MDOT MVA — the app should not be redistributed/sold, per the manual's copyright notice on page 2)