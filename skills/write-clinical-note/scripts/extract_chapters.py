"""Extract chapters plus every otherwise omitted page into an EMPTY directory.

Usage: python3 scripts/extract_chapters.py source.pdf /tmp/dsm-fresh-extract
Page markers cover the entire PDF once. Image-only content still needs visual review.
"""
import re
import sys
from pathlib import Path

from pypdf import PdfReader

PDF = Path(sys.argv[1])
OUT = Path(sys.argv[2])
if OUT.exists() and any(OUT.iterdir()):
    sys.exit("Output directory must be empty; use a new directory to avoid stale or duplicate extracts.")
OUT.mkdir(parents=True, exist_ok=True)

doc = PdfReader(PDF)
toc = []


def read_outline(items, level=1):
    for item in items:
        if isinstance(item, list):
            read_outline(item, level + 1)
        else:
            page = doc.get_destination_page_number(item)
            if page is not None and page >= 0:
                toc.append((level, item.title, page + 1))


read_outline(doc.outline)

# Chapters = every level-2 entry plus the level-1 front-matter blocks worth keeping.
keep_l1 = {"DSM-5-TR Classification"}
entries = [(t, p) for l, t, p in toc if l == 2 or t in keep_l1]
all_starts = sorted({p for _, _, p in toc} | {len(doc.pages) + 1})
covered = set()

def slug(s):
    return re.sub(r"[^a-z0-9]+", "-", s.lower()).strip("-")[:60]

for i, (title, start) in enumerate(entries):
    end = min(p for p in all_starts if p > start)  # next outline entry of any level
    parts = [f"# {title}\n"]
    for pno in range(start, end):
        parts.append(f"\n<!-- pdf page {pno} -->\n")
        parts.append(doc.pages[pno - 1].extract_text() or "[No extractable text; inspect PDF page visually.]\n")
        covered.add(pno)
    name = f"{i:02d}-{slug(title)}.md"
    (OUT / name).write_text("".join(parts))
    print(f"{name}\tpages {start}-{end - 1}\t{sum(len(x) for x in parts)//4} tok")

# Parent outline pages, prefaces, section openers and the back-of-book index used
# to disappear. Keep all remaining contiguous page spans as supplements.
missing = sorted(set(range(1, len(doc.pages) + 1)) - covered)
spans = []
for page in missing:
    if spans and page == spans[-1][-1] + 1:
        spans[-1].append(page)
    else:
        spans.append([page])
for span in spans:
    name = f"supplement-pages-{span[0]}-{span[-1]}.md"
    parts = [f"# Supplement: PDF pages {span[0]}–{span[-1]}\n"]
    for page in span:
        parts.append(f"\n<!-- pdf page {page} -->\n")
        parts.append(doc.pages[page - 1].extract_text() or "[No extractable text; inspect PDF page visually.]\n")
    (OUT / name).write_text("".join(parts))
    print(f"{name}\tpages {span[0]}-{span[-1]}")
