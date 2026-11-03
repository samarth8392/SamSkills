#!/usr/bin/env python3
"""Build the static catalog, CSV, and structural audit from every skill folder."""
import argparse
import collections
import csv
import hashlib
import json
from pathlib import Path
import re
import sys
import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
from attribution import extract_attribution

ROOT = Path(__file__).resolve().parents[1]
PLATFORMS = {
    'Claude': r'Claude Code|\.claude/|\bTaskCreate\b|\bTaskUpdate\b|\bTodoWrite\b',
    'OpenAI / Codex': r'\bCodex\b|\.codex/(?:agents|config)|functions\.(?:exec|apply_patch)|\bimage_gen\b',
    'Gemini': r'Gemini CLI|\bactivate_skill\b',
    'OpenClaw': r'\bOpenClaw\b|\.openclaw/',
}
CATEGORIES = {
    'R & Shiny': r'\br\b|shiny|quarto|tidyverse|ggplot|cran',
    'Life sciences & medicine': r'genomic|clinical|biolog|bioinformatic|anndata|scanpy|biopython|depmap|bioservices|protein|health|medical|cell',
    'Research & writing': r'research|paper|academic|citation|literature|peer.review|scientific|manuscript|poster|conference',
    'Design & documents': r'design|frontend|slides|pptx|docx|\bpdf\b|image|infographic|diagram|alt.text|brand|markdown|html|document',
    'ML training & models': r'train|fine.tun|quantiz|llm|model|torch|transformer|tokeniz|attention|distill|alignment|rlhf|multimodal|inference|gpu',
    'Data & retrieval': r'data|retriev|vector|search|embedding|rag|sql|database',
    'Agent workflows': r'agent|prompt|orchestrat|workflow|superpowers|planning|plans|brainstorm',
    'Engineering & tools': r'code|test|debug|git|review|deploy|release|package|implement|development|api|monitor|observab',
}

def metadata(text):
    if not text.startswith('---\n'):
        return {}, ['Missing YAML front matter']
    parts = text.split('---', 2)
    if len(parts) != 3:
        return {}, ['Unclosed YAML front matter']
    try:
        data = yaml.safe_load(parts[1])
        if not isinstance(data, dict):
            return {}, ['Front matter must be a mapping']
        return data, []
    except yaml.YAMLError as e:
        return {}, [f'Invalid YAML: {str(e).splitlines()[0]}']

def classify(text):
    evidence = []
    for platform, pattern in PLATFORMS.items():
        matches = [{'platform': platform, 'line': i, 'text': line.strip()[:300]}
                   for i, line in enumerate(text.splitlines(), 1) if re.search(pattern, line, re.I)]
        evidence.extend(matches[:4])
    platforms = sorted({e['platform'] for e in evidence})
    label = ('Model-agnostic' if not platforms else
             f'{platforms[0]}-oriented' if len(platforms) == 1 else 'Multi-platform')
    return label, platforms, evidence

def category(name, description, tags):
    # Favor the skill's identity; use its description only as a fallback.
    for field in (name.replace('-', ' '), ' '.join(tags), description):
        for label, pattern in CATEGORIES.items():
            if re.search(pattern, field, re.I):
                return label
    return 'General tools'

def build(root=ROOT):
    overrides = json.loads((root / 'catalog/overrides.json').read_text())
    rows, issues, names, hashes = [], [], collections.defaultdict(list), collections.defaultdict(list)
    for folder in sorted((root / 'skills').iterdir()):
        if not folder.is_dir():
            continue
        path = folder / 'SKILL.md'
        if not path.is_file():
            issues.append({'skill': folder.name, 'issue': 'Missing SKILL.md'})
            continue
        text = path.read_text(encoding='utf-8')
        meta, warnings = metadata(text)
        for field in ('name', 'description'):
            if not isinstance(meta.get(field), str) or not meta.get(field, '').strip():
                warnings.append(f'Missing or invalid {field}')
        name = str(meta.get('name') or folder.name)
        description = str(meta.get('description') or next((line.lstrip('# ').strip() for line in text.splitlines() if line.strip()), folder.name))
        tags = meta.get('tags') or []
        tags = [str(t) for t in tags] if isinstance(tags, list) else [str(tags)]
        compatibility, platforms, evidence = classify(text)
        providers = [p for p, pattern in {'OpenAI': r'\bopenai\b|\bgpt-\d', 'Anthropic': r'\banthropic\b|\bclaude\b', 'Google / Gemini': r'\bgemini\b|\bnano banana\b'}.items() if re.search(pattern, text, re.I)]
        row = dict(id=folder.name, name=name, path=path.relative_to(root).as_posix(), description=' '.join(description.split()),
                   category=category(folder.name, description, tags), tags=tags,
                   compatibility=compatibility, platforms=platforms, evidence=evidence,
                   classificationNote='Inferred from SKILL.md; not runtime-tested. Provider mentions alone do not imply an agent requirement.',
                   providers=providers, declaredCompatibility=meta.get('compatibility', ''),
                   hasCodexMetadata=(folder / 'agents/openai.yaml').exists(),
                   files=sum(1 for p in folder.rglob('*') if p.is_file() and p.name != '.DS_Store'),
                   warnings=warnings, body=text, attribution=extract_attribution(meta, text, folder))
        if folder.name in overrides:
            row.update(overrides[folder.name])
        names[name].append(folder.name)
        hashes[hashlib.sha256(text.encode()).hexdigest()].append(folder.name)
        for warning in warnings:
            issues.append({'skill': folder.name, 'issue': warning})
        # These findings require human review; examples can legitimately contain paths.
        for i, line in enumerate(text.splitlines(), 1):
            if re.search(r'/Users/|/home/[^/\s]+/|/mnt/(?:data|skills)/', line):
                issues.append({'skill': folder.name, 'issue': 'Environment-specific path (review)', 'line': i, 'text': line.strip()[:240]})
        prose = re.sub(r'(?ms)^(`{3,}|~{3,}).*?^\1[^\n]*$', '', text)
        prose = re.sub(r'`[^`\n]*`', '', prose)
        for match in re.finditer(r'\[[^\]\n]+\]\(([^)\n]+)\)', prose):
            target = match.group(1).split(' "')[0].strip('<>').split('#')[0]
            if not target or re.match(r'[a-z]+:|/|~|\$', target, re.I) or any(c in target for c in '*{}'):
                continue
            if not (folder / target).exists():
                issues.append({'skill': folder.name, 'issue': 'Unresolved relative Markdown link (review)', 'target': target})
        rows.append(row)
    duplicate_names = [v for v in names.values() if len(v) > 1]
    duplicate_content = [v for v in hashes.values() if len(v) > 1]
    for row in rows:
        row['sameName'] = [v for v in names[row['name']] if v != row['id']]
        row['identicalInstructions'] = next(([v for v in group if v != row['id']] for group in duplicate_content if row['id'] in group), [])
    symlinks = []
    for p in (root / 'skills').rglob('*'):
        if p.is_symlink():
            symlinks.append({'path': p.relative_to(root).as_posix(), 'external': not p.resolve().is_relative_to(root), 'broken': not p.exists()})
    audit = dict(totalSkills=len(rows), classifications=dict(sorted(collections.Counter(r['compatibility'] for r in rows).items())),
                 categories=dict(sorted(collections.Counter(r['category'] for r in rows).items())),
                 duplicateNames=duplicate_names, identicalInstructions=duplicate_content,
                 symlinks=symlinks, issues=issues,
                 scope='Static structural audit of every SKILL.md. Does not execute skills, validate external APIs, or certify licenses or runtime compatibility.')
    return rows, audit

def outputs(root=ROOT):
    rows, audit = build(root)
    data = root / 'site/data'
    data.mkdir(parents=True, exist_ok=True)
    (data / 'catalog.json').write_text(json.dumps({'skills': rows, 'summary': audit}, ensure_ascii=False, separators=(',', ':')) + '\n')
    (root / 'catalog/audit.json').write_text(json.dumps(audit, indent=2) + '\n')
    with (root / 'skills.csv').open('w', newline='') as f:
        writer = csv.writer(f, lineterminator='\n')
        writer.writerow(['skill', 'path', 'description', 'triggers', 'category', 'compatibility', 'classification_note', 'provider_mentions', 'same_name', 'authors', 'attribution_links'])
        for r in rows:
            writer.writerow([r['name'], r['path'], r['description'], r['description'], r['category'], r['compatibility'], r['classificationNote'], '; '.join(r['providers']), '; '.join(r['sameName']), '; '.join(a['name'] for a in r['attribution']['authors']), '; '.join(link['url'] for link in r['attribution']['links'])])
    lines = ['# Skills audit', '', audit['scope'], '', f"- Skill folders indexed: **{len(rows)}**", f"- Remaining symlinks: **{len(audit['symlinks'])}**", f"- Duplicate declared-name groups: **{len(audit['duplicateNames'])}**", f"- Identical SKILL.md groups: **{len(audit['identicalInstructions'])}**", '', '## Agent classifications', '', '| Classification | Count |', '| --- | ---: |']
    lines += [f'| {k} | {v} |' for k,v in audit['classifications'].items()]
    lines += ['', 'Classifications are heuristic with reviewed overrides, not compatibility certifications. See `catalog/overrides.json` and each website detail for evidence. Optional `agents/openai.yaml` does not make a skill Codex-only. Provider mentions describe content, not necessarily dependencies.', '', '## Duplicate declared names', '', 'Keep one folder from each group when installing by declared name. Identical instructions do not establish that supporting assets are identical. No duplicates were deleted.', '']
    lines += ['- ' + ', '.join(f'`{v}`' for v in group) for group in audit['duplicateNames']]
    lines += ['', '## Findings to review', '', 'The original 23 missing reference links were repaired with labeled local guides and pinned official source snapshots. See [reference provenance](REFERENCES.md). Remaining findings below describe the current files.', '', 'Environment paths and relative links may be examples or refer to consumer projects. They are reported, not rewritten blindly. Vendoring removes filesystem symlink dependencies; scripts may still require packages, credentials, external services, or data described in their instructions.', '']
    lines += [f"- `{i['skill']}`: {i['issue']}" + (f" — line {i['line']}" if 'line' in i else '') + (f" — `{i['target']}`" if 'target' in i else '') for i in audit['issues']]
    (root / 'docs/AUDIT.md').write_text('\n'.join(lines) + '\n')
    return rows, audit

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check', action='store_true', help='Fail if generated files are stale; writes nothing.')
    args = parser.parse_args()
    if args.check:
        import tempfile
        import shutil
        with tempfile.TemporaryDirectory() as temp:
            temp = Path(temp)
            (temp / 'skills').symlink_to(ROOT / 'skills', target_is_directory=True)
            for d in ('catalog', 'docs', 'site'): (temp / d).mkdir()
            shutil.copy2(ROOT / 'catalog/overrides.json', temp / 'catalog/overrides.json')
            outputs(temp)
            files = ['site/data/catalog.json', 'catalog/audit.json', 'skills.csv', 'docs/AUDIT.md']
            stale = [p for p in files if not (ROOT / p).exists() or (ROOT / p).read_bytes() != (temp / p).read_bytes()]
            if stale:
                sys.exit('Stale generated files: ' + ', '.join(stale))
        print('Generated catalog is current.')
    else:
        rows, audit = outputs()
        print(f"Indexed {len(rows)} skills; {len(audit['issues'])} review findings.")
        print(json.dumps(audit['classifications'], indent=2))
