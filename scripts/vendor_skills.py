#!/usr/bin/env python3
"""Materialize external symlinks safely, retaining checksummed provenance."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import tempfile

ROOT = Path(__file__).resolve().parents[1]

def digest_tree(path):
    files = [path] if path.is_file() else sorted(
        Path(base) / name for base, _, names in os.walk(path, followlinks=True)
        for name in names if (Path(base) / name).is_file())
    return {('.' if path.is_file() else p.relative_to(path).as_posix()): hashlib.sha256(p.read_bytes()).hexdigest() for p in files}

def preflight(path, ancestors=()):
    real = path.resolve(strict=True)
    if real in ancestors:
        raise ValueError(f'Symlink cycle: {path}')
    if real.is_dir():
        for child in real.iterdir():
            preflight(child, (*ancestors, real))
    elif not real.is_file():
        raise ValueError(f'Unsupported file: {path}')

def vendor(root=ROOT, apply=False):
    root = root.resolve()
    links = []
    for base, dirs, files in os.walk(root / 'skills'):
        for name in sorted(dirs + files):
            p = Path(base) / name
            if p.is_symlink():
                target = p.resolve(strict=True)
                if not target.is_relative_to(root):
                    preflight(p)
                    links.append((p, target))
    if not apply:
        return [p.relative_to(root).as_posix() for p, _ in links]
    manifest = root / 'catalog' / 'vendored.json'
    entries = json.loads(manifest.read_text()) if manifest.exists() else []
    for p, target in links:
        # Stage and verify the full copy before replacing the link; source is never changed.
        with tempfile.TemporaryDirectory(prefix='.vendor-', dir=p.parent) as tmp:
            staged = Path(tmp) / 'payload'
            if target.is_dir():
                shutil.copytree(target, staged, symlinks=False)
            else:
                shutil.copy2(target, staged)
            hashes = digest_tree(target)
            if hashes != digest_tree(staged):
                raise ValueError(f'Copy verification failed: {p}')
            original = os.readlink(p)
            p.unlink()
            try:
                staged.rename(p)
            except Exception:
                p.symlink_to(original, target_is_directory=target.is_dir())
                raise
        source = str(target)
        if target.is_relative_to(Path.home()):
            source = '~/' + target.relative_to(Path.home()).as_posix()
        entries.append({'path': p.relative_to(root).as_posix(), 'source': source, 'sha256': hashes})
        manifest.parent.mkdir(exist_ok=True)
        manifest.write_text(json.dumps(entries, indent=2) + '\n')
    return [p.relative_to(root).as_posix() for p, _ in links]

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--apply', action='store_true')
    args = parser.parse_args()
    result = vendor(apply=args.apply)
    print(f'{len(result)} external links ' + ('materialized and verified.' if args.apply else 'found. Use --apply to copy.'))
