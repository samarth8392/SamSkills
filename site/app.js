import {prepare, search} from './search.js';
import {attributionHTML} from './attribution.js';
const $ = id => document.getElementById(id);
const repo = 'https://github.com/samarth8392/SamSkills/tree/main/skills/';
const escape = text => String(text).replace(/[&<>"']/g, c => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let skills = [], summary, limit = 30;
const controls = ['search', 'platform', 'category', 'sort', 'unique'];
const state = () => ({query: $('search').value, platform: $('platform').value, category: $('category').value, sort: $('sort').value, unique: $('unique').checked});
function syncURL() {
  const url = new URL(location.href);
  for (const [key,value] of Object.entries(state())) {
    if (value && !(key === 'sort' && value === 'relevance')) url.searchParams.set(key, String(value));
    else url.searchParams.delete(key);
  }
  history.replaceState(null, '', url);
}
function readURL() {
  const params = new URLSearchParams(location.search);
  $('search').value = params.get('query') || '';
  $('platform').value = params.get('platform') || '';
  $('category').value = params.get('category') || '';
  $('sort').value = params.get('sort') || 'relevance';
  $('unique').checked = params.get('unique') === 'true';
}
function render() {
  const matches = search(skills, state());
  $('status').textContent = `${matches.length} skills found · showing ${Math.min(limit,matches.length)}`;
  $('results').innerHTML = matches.length ? matches.slice(0,limit).map(s => `<article class="skill"><div><h2><a href="#skill=${encodeURIComponent(s.id)}">${escape(s.id)}</a></h2><p>${escape(s.description)}</p>${attributionHTML(s)}${s.sameName.length ? `<p class="duplicates">Shares a skill name with ${s.sameName.length} other folder${s.sameName.length > 1 ? 's' : ''}</p>` : ''}</div><div class="skill-meta"><span>${escape(s.compatibility)}</span><p>${escape(s.category)}</p></div></article>`).join('') : '<div class="empty"><h2>No skills match those filters.</h2><p>Try fewer words, a technology name, or reset the filters to browse the whole library.</p><button id="empty-reset">Reset filters</button></div>';
  $('empty-reset')?.addEventListener('click', reset);
  $('more').hidden = matches.length <= limit;
  syncURL();
}
function reset() {
  $('search').value = ''; $('category').value = ''; $('platform').value = ''; $('unique').checked = false; $('sort').value = 'relevance'; limit = 30; render();
}
async function copy(text, button) {
  try { await navigator.clipboard.writeText(text); button.textContent = 'Copied'; }
  catch { button.textContent = 'Select and copy the text below'; }
  setTimeout(() => {button.textContent = 'Copy command';}, 2500);
}
function showSkill() {
  if (!location.hash.startsWith('#skill=')) { if ($('detail').open) $('detail').close(); return; }
  let id;
  try {id = decodeURIComponent(location.hash.slice(7));} catch {return;}
  const s = skills.find(s => s.id === id);
  if (!s) {
    $('detail-content').innerHTML = '<h2 id="detail-title">Skill not found</h2><p>This link does not match a folder in the current catalog.</p>';
    if (!$('detail').open) $('detail').showModal();
    return;
  }
  const findings = summary.issues.filter(i => i.skill === id);
  $('detail-content').innerHTML = `<h2 id="detail-title">${escape(s.id)}</h2><p>${escape(s.description)}</p>
  <div class="actions"><a href="${repo + encodeURIComponent(s.id)}" target="_blank" rel="noopener">Browse full skill folder ↗</a><button id="download">Download SKILL.md</button></div>
  <h3>Author & sources</h3>${attributionHTML(s, true)}
  <h3>Agent compatibility</h3><div class="note"><strong>${escape(s.compatibility)}</strong><p>${escape(s.classificationNote)}</p>${s.declaredCompatibility ? `<p>Author’s declaration: ${escape(s.declaredCompatibility)}</p>` : ''}<p>Provider mentions: ${escape(s.providers.join(', ') || 'None detected')}. ${s.hasCodexMetadata ? 'Optional Codex interface metadata included.' : ''}</p></div>
  ${s.evidence.length ? `<details><summary>Why this classification?</summary><ul class="evidence">${s.evidence.map(e => `<li><strong>${escape(e.platform)} · line ${e.line}</strong><br>${escape(e.text)}</li>`).join('')}</ul></details>` : ''}
  ${s.sameName.length ? `<h3>Other folders with this skill name</h3><p>${s.sameName.map(id => `<a href="#skill=${encodeURIComponent(id)}">${escape(id)}</a>`).join(', ')}. Choose one when installing. ${s.identicalInstructions.length ? 'Some share identical SKILL.md content; their supporting files may differ.' : ''}</p>` : ''}
  ${findings.length ? `<details><summary>${findings.length} audit finding${findings.length === 1 ? '' : 's'} to review</summary><ul>${findings.map(i=>`<li>${escape(i.issue)}${i.target ? ': '+escape(i.target) : ''}${i.line ? ' · line '+i.line : ''}</li>`).join('')}</ul></details>` : ''}
  <h3>Install this folder</h3><p>Run from the root of your cloned SamSkills repository. Copies all ${s.files} files into a project-local skill directory.</p>
  <div class="install-controls"><label for="destination">Agent directory</label><select id="destination"><option value=".agents/skills">Codex / Agent Skills</option><option value=".claude/skills">Claude Code</option></select></div>
  <div class="install"><pre id="command"></pre><button id="copy">Copy command</button></div>
  <h3>Instructions</h3><p>The original SKILL.md, including requirements and setup. Downloading this file alone does not include supporting assets.</p><pre id="instructions" tabindex="0"></pre>`;
  const shellQuote = value => "'" + value.replaceAll("'", "'\"'\"'") + "'";
  const command = () => {
    const dest = $('destination').value;
    $('command').textContent = `mkdir -p ${shellQuote(dest)}\ncp -R ${shellQuote(`skills/${s.id}`)} ${shellQuote(`${dest}/`)}`;
  };
  command(); $('destination').addEventListener('change', command);
  $('copy').addEventListener('click', () => copy($('command').textContent, $('copy')));
  $('instructions').textContent = s.body;
  $('download').addEventListener('click', () => {
    const url = URL.createObjectURL(new Blob([s.body], {type:'text/markdown;charset=utf-8'}));
    const a = document.createElement('a'); a.href = url; a.download = `${s.id}-SKILL.md`; a.click(); setTimeout(()=>URL.revokeObjectURL(url), 1000);
  });
  if (!$('detail').open) $('detail').showModal();
  $('detail').scrollTop = 0;
}
function closeDetail() {
  const url = new URL(location.href); url.hash = ''; history.replaceState(null,'',url); $('detail').close();
}
$('close').addEventListener('click', closeDetail);
$('detail').addEventListener('cancel', e => {e.preventDefault();closeDetail();});
$('about').addEventListener('click', ()=>$('help').showModal());
$('close-help').addEventListener('click', ()=>$('help').close());
window.addEventListener('hashchange', showSkill);
window.addEventListener('popstate', () => {readURL(); render(); showSkill();});
document.addEventListener('keydown', e => {if(e.key === '/' && !['INPUT','TEXTAREA','SELECT'].includes(document.activeElement.tagName) && !$('detail').open && !$('help').open){e.preventDefault();$('search').focus();}});
$('reset').addEventListener('click', reset);
$('more').addEventListener('click', () => {limit += 30;render();});
for (const id of controls) $(id).addEventListener(id === 'search' ? 'input' : 'change', () => {limit=30;render();});
try {
  const response = await fetch('data/catalog.json');
  if (!response.ok) throw new Error(`HTTP ${response.status}`);
  const data = await response.json(); skills = prepare(data.skills); summary = data.summary;
  for (const [id, field] of [['platform','compatibility'],['category','category']]) {
    for (const value of [...new Set(skills.map(s => s[field]))].sort()) {const option = document.createElement('option');option.value=value;option.textContent=value;$(id).append(option);}
  }
  $('overview').innerHTML = [[skills.length,'Skill folders'],[new Set(skills.map(s=>s.name)).size,'Distinct skill names'],[Object.keys(summary.categories).length,'Topics']].map(([n,label])=>`<div class="stat"><strong>${n}</strong><span>${label}</span></div>`).join('');
  readURL(); render(); showSkill();
} catch (error) {
  $('status').textContent = 'The skill index could not load.';
  $('results').innerHTML = '<div class="empty"><h2>Try reloading the library.</h2><p>If you opened this as a local file, serve the site folder with a static web server. The repository also includes a CSV index.</p><button id="retry">Reload</button></div>';
  $('retry').addEventListener('click', () => location.reload());
  console.error(error);
}
