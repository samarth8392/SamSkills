// Shared by the browser and Node tests. No external search service.
export function prepare(skills) {
  return skills.map(skill => ({...skill, haystack: [skill.id, skill.name, skill.description, skill.category,
    skill.compatibility, ...skill.tags, ...skill.providers, skill.body].join(' ').toLowerCase()}));
}
export function search(skills, {query = '', platform = '', category = '', unique = false, sort = 'relevance'} = {}) {
  const tokens = query.toLowerCase().trim().match(/"[^"]+"|\S+/g)?.map(t => t.replace(/^"|"$/g, '')) ?? [];
  const seen = new Set();
  return skills.filter(s => (!platform || s.compatibility === platform) && (!category || s.category === category))
    .map(s => ({skill: s, score: tokens.reduce((score, t) => score + (s.id.toLowerCase().includes(t) ? 20 : s.description.toLowerCase().includes(t) ? 5 : 1), 0)}))
    .filter(({skill}) => tokens.every(t => skill.haystack.includes(t)))
    .sort((a,b) => (sort === 'relevance' ? b.score - a.score : sort === 'category' ? a.skill.category.localeCompare(b.skill.category) : 0) || a.skill.id.localeCompare(b.skill.id))
    .filter(({skill}) => { if (!unique) return true; if (seen.has(skill.name)) return false; seen.add(skill.name); return true; })
    .map(({skill}) => skill);
}
