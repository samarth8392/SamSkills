"""Search DSM study-note metadata; this retrieves references, not diagnoses.

Usage: python3 scripts/lookup.py 'PTSD' [--json] [--limit 10]
"""
import argparse
import json
from pathlib import Path
import re
import unicodedata


def norm(value):
    value = unicodedata.normalize('NFKC', str(value)).translate(str.maketrans({
        '\u2018': "'", '\u2019': "'", '\u02bc': "'",
        '\u2010': '-', '\u2011': '-', '\u2012': '-', '\u2013': '-', '\u2014': '-',
    }))
    return re.sub(r'\s+', ' ', value.casefold().strip())


def search(entries, query):
    query = norm(query)
    ranked = []
    for entry in entries:
        exact_fields = [*entry.get('aliases', []), *entry.get('icd10', [])]
        text = norm(' '.join(str(entry.get(key, '')) for key in
                            ['name', 'aliases', 'key_features', 'chapter', 'icd10']))
        if query == norm(entry.get('name', '')):
            score = 120
        elif any(query == norm(value) for value in exact_fields):
            score = 100
        elif query in norm(entry.get('name', '')):
            score = 60
        elif query in text:
            score = 40
        elif all(word in text for word in query.split()):
            score = 20
        else:
            continue
        ranked.append((score, entry))
    return [entry for score, entry in sorted(ranked, key=lambda pair:
            (-pair[0], pair[1].get('overview', False), norm(pair[1]['name']), pair[1]['file']))]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('query')
    parser.add_argument('--index', type=Path, default=Path(__file__).resolve().parents[1] / 'references/dsm5tr/index.json')
    parser.add_argument('--json', action='store_true')
    parser.add_argument('--limit', type=int, default=10)
    args = parser.parse_args()
    if not args.query.strip():
        parser.error('query must not be empty')
    if args.limit < 1:
        parser.error('limit must be positive')
    try:
        entries = json.loads(args.index.read_text())
    except (OSError, ValueError) as exc:
        parser.error(f'Cannot read index: {exc}. Run scripts/build_index.py references/dsm5tr first.')
    matches = search(entries, args.query)
    shown = matches[:args.limit]
    if args.json:
        print(json.dumps(shown, indent=2))
    elif not shown:
        print('No matches. Try the full disorder name, an alias, code, or fewer symptom terms.')
    else:
        print(f'{len(matches)} matching references; showing {len(shown)}. Match order is retrieval relevance, not diagnostic probability.')
        for entry in shown:
            print(f"\n{entry['name']} [{entry.get('kind', 'reference')}]")
            print(f"  {args.index.parent / entry['file']}")
            print(f"  PDF pp. {entry.get('pdf_pages', '')}; code references: {', '.join(entry.get('icd10', [])) or 'none'}")
    return 0 if matches else 1


if __name__ == '__main__':
    raise SystemExit(main())
