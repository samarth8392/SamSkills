"""Extract declared authors and source links without inferring project ownership."""
import re
from urllib.parse import urlsplit, urlunsplit


def safe_url(value):
    if not isinstance(value, str):
        return ''
    value = value.strip().rstrip('.,;')
    try:
        parts = urlsplit(value)
        if parts.scheme not in ('http', 'https') or not parts.hostname or parts.username or parts.password:
            return ''
        if any(c.isspace() or ord(c) < 32 for c in value):
            return ''
        return urlunsplit(parts)
    except ValueError:
        return ''


def extract_attribution(meta, text, folder=None):
    nested = meta.get('metadata')
    fields = {**meta, **(nested if isinstance(nested, dict) else {})}
    authors, links = [], []
    declared = fields.get('authors') or fields.get('author') or fields.get('skill-author') or []
    if not isinstance(declared, list):
        declared = [declared]
    for author in declared:
        url = ''
        if isinstance(author, dict):
            name = str(author.get('name', '')).strip()
            url = safe_url(author.get('url') or author.get('website'))
        elif isinstance(author, str):
            name = author.strip()
            match = re.fullmatch(r'\[([^]]+)\]\((https?://[^)]+)\)', name)
            if match:
                name, url = match[1], safe_url(match[2])
        else:
            continue
        if name:
            # "user" does not establish the identity of an author or owner.
            authors.append({'name': name, 'url': url, 'unspecified': name.lower() in ('user', 'unknown')})
    if len(authors) == 1 and not authors[0]['url']:
        authors[0]['url'] = safe_url(fields.get('author-url') or fields.get('author_url'))
    for key in ('source', 'repository', 'repo', 'github-repo', 'github', 'homepage', 'website', 'url'):
        url = safe_url(fields.get(key))
        if url and not any(link['url'] == url for link in links):
            links.append({'label': 'Declared source' if key in ('source', 'repository', 'repo', 'github-repo', 'github') else 'Website', 'url': url, 'kind': 'declared'})
    # References to a library are useful, but do not identify the skill's author.
    prose = text.split('---', 2)[-1] if text.startswith('---\n') else text
    prose = re.sub(r'(?ms)^(`{3,}|~{3,}).*?^\1[^\n]*$', '', prose)
    for match in re.finditer(r'https?://github\.com/([A-Za-z0-9_.-]+)/([A-Za-z0-9_.-]+)', prose):
        owner, repo = match[1], match[2].rstrip('.')
        if repo.endswith('.git'):
            repo = repo[:-4]
        url = f'https://github.com/{owner}/{repo}'
        if not any(link['url'].rstrip('/') == url for link in links):
            links.append({'label': f'{owner}/{repo}', 'url': url, 'kind': 'related'})
    copyright = []
    if folder is not None:
        for path in sorted(folder.glob('LICENSE*')):
            if path.is_file():
                for line in path.read_text(errors='replace').splitlines()[:15]:
                    if re.match(r'^(?:©|Copyright\s+(?:\(c\)\s*)?\d)', line.strip(), re.I):
                        copyright.append({'notice': line.strip(), 'file': path.name})
    return {'authors': authors, 'links': links, 'copyright': copyright}
