#!/usr/bin/env python3
"""Verify the repaired local reference bundle without network access."""
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def check(root=ROOT):
    repairs = json.loads((root / 'catalog/reference-repairs.json').read_text())
    sources = json.loads((root / 'catalog/reference-sources.json').read_text())
    checked = 0
    for record in repairs['guides'] + sources['sources']:
        for relative in record['paths']:
            path = root / relative
            if not path.resolve().is_relative_to(root.resolve()) or path.is_symlink():
                raise ValueError(f'Reference escapes repository: {relative}')
            digest = hashlib.sha256(path.read_bytes()).hexdigest()
            if digest != record['sha256']:
                raise ValueError(f'Reference checksum mismatch: {relative}')
            checked += 1
    for record in repairs['guides']:
        for relative in record['paths']:
            path = root / relative
            text = re.sub(r'(?ms)^(`{3,}|~{3,}).*?^\1[^\n]*$', '', path.read_text())
            for target in re.findall(r'\[[^\]\n]+\]\(([^)\n]+)\)', text):
                if re.match(r'https?://', target):
                    continue
                destination = (path.parent / target.split('#')[0]).resolve()
                if not destination.is_relative_to(root.resolve()) or not destination.is_file():
                    raise ValueError(f'Missing local guide reference: {relative} -> {target}')
    return checked


if __name__ == '__main__':
    print(f'Verified {check()} local guide/source copies and all replacement-guide links.')
