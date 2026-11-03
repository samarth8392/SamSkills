import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
def module(name):
    spec = importlib.util.spec_from_file_location(name, ROOT / 'scripts' / f'{name}.py')
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod
vendor = module('vendor_skills')
catalog = module('build_catalog')

class CatalogTests(unittest.TestCase):
    def test_vendor_nested_links_and_idempotency(self):
        with tempfile.TemporaryDirectory() as t:
            base = Path(t); root=base/'repo'; source=base/'source'
            (root/'skills').mkdir(parents=True); source.mkdir()
            (source/'SKILL.md').write_text('content')
            asset=base/'asset'; asset.write_text('asset')
            (source/'reference').symlink_to(asset)
            assets=base/'assets'; assets.mkdir(); (assets/'example.txt').write_text('nested')
            (source/'references').symlink_to(assets)
            (root/'skills'/'example').symlink_to(source)
            self.assertEqual(vendor.vendor(root),['skills/example'])
            vendor.vendor(root, apply=True)
            self.assertFalse((root/'skills/example').is_symlink())
            self.assertFalse((root/'skills/example/reference').is_symlink())
            self.assertFalse((root/'skills/example/references').is_symlink())
            self.assertEqual((root/'skills/example/references/example.txt').read_text(), 'nested')
            self.assertEqual((root/'skills/example/reference').read_text(),'asset')
            self.assertEqual(vendor.vendor(root,apply=True),[])
            self.assertTrue((source/'reference').is_symlink())
    def test_broken_link_leaves_source_untouched(self):
        with tempfile.TemporaryDirectory() as t:
            root=Path(t); (root/'skills').mkdir()
            link=root/'skills/broken';link.symlink_to(root/'missing')
            with self.assertRaises(FileNotFoundError): vendor.vendor(root,apply=True)
            self.assertTrue(link.is_symlink())
    def test_cycles_rejected(self):
        with tempfile.TemporaryDirectory() as t:
            p=Path(t); (p/'cycle').symlink_to(p)
            with self.assertRaises(ValueError): vendor.preflight(p)
    def test_attribution_metadata_and_reference_distinction(self):
        from attribution import extract_attribution
        result = extract_attribution({'metadata': {'skill-author': 'Example', 'github-repo': 'https://github.com/author/skills'}}, 'Library: https://github.com/other/library')
        self.assertEqual(result['authors'][0]['name'], 'Example')
        self.assertEqual([link['kind'] for link in result['links']], ['declared', 'related'])
        self.assertEqual(result['authors'][0]['url'], '')

    def test_attribution_safe_urls_and_unknown_authors(self):
        from attribution import extract_attribution
        result = extract_attribution({'author': 'user', 'repository': 'javascript:alert(1)'}, '')
        self.assertTrue(result['authors'][0]['unspecified'])
        self.assertFalse(result['links'])
        result = extract_attribution({'authors': [{'name': 'Alice', 'url': 'https://example.org'}]}, '')
        self.assertEqual(result['authors'][0]['url'], 'https://example.org')

    def test_repaired_reference_bundle(self):
        checker = module('check_references')
        self.assertGreater(checker.check(), 23)
        _, audit = catalog.build()
        self.assertFalse([i for i in audit['issues'] if i['issue'].startswith('Unresolved relative')])

    def test_repository_structure(self):
        rows,audit=catalog.build()
        self.assertEqual(len(rows),len(list((ROOT/'skills').glob('*/SKILL.md'))))
        self.assertFalse(audit['symlinks'])
        self.assertTrue(all(not r['warnings'] for r in rows))
    def test_classification_ignores_vendor_mentions(self):
        self.assertEqual(catalog.classify('Uses the OpenAI API and Anthropic models')[0],'Model-agnostic')
        self.assertEqual(catalog.classify('Requires Claude Code TaskCreate')[0],'Claude-oriented')
        self.assertEqual(catalog.classify('Supports Claude Code and Codex')[0],'Multi-platform')

if __name__=='__main__': unittest.main()
