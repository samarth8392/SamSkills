const escape = text => String(text).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
function link(label, url) {
  try {
    const parsed = new URL(url);
    if (!['https:', 'http:'].includes(parsed.protocol) || parsed.username || parsed.password) return escape(label);
    return `<a href="${escape(parsed.href)}" target="_blank" rel="noopener noreferrer">${escape(label)} ↗</a>`;
  } catch { return escape(label); }
}
export function attributionHTML(skill, detailed = false) {
  const {authors = [], links = [], copyright = []} = skill.attribution || {};
  const named = authors.filter(a => !a.unspecified);
  const sourceFile = file => 'https://github.com/samarth8392/SamSkills/blob/main/skills/' + encodeURIComponent(skill.id) + '/' + encodeURIComponent(file);
  const authorsHTML = named.length ? `Author: ${named.map(a => link(a.name, a.url || sourceFile('SKILL.md'))).join(', ')}` : '';
  const shownLinks = detailed ? links : links.slice(0, 1);
  const linksHTML = shownLinks.map(l => link(l.kind === 'related' ? `Related project: ${l.label}` : l.label, l.url)).join(' · ');
  const copyrightHTML = copyright.map(c => link(c.notice, sourceFile(c.file))).join(' · ');
  const content = [authorsHTML, copyrightHTML, linksHTML].filter(Boolean).join(' · ');
  if (!content && !detailed) return '';
  return `<div class="attribution">${content || 'Author not identified in the skill metadata.'}${detailed ? '<p class="attribution-note">Author links open the provided profile or the credit in SKILL.md. Copyright notices link to the bundled license. Related projects are references, not claims of skill authorship or ownership.</p>' : ''}</div>`;
}
