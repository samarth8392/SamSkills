import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {prepare,search} from '../site/search.js';
const {skills:raw,summary} = JSON.parse(readFileSync(new URL('../site/data/catalog.json',import.meta.url)));
const skills = prepare(raw);
test('every skill is searchable by its folder ID',()=>{
  assert.equal(skills.length,summary.totalSkills);
  for (const s of skills) assert.ok(search(skills,{query:s.id}).some(hit=>hit.id===s.id));
});
test('multiple tokens, phrase matching and full instructions',()=>{
  assert.ok(search(skills,{query:'"sparse autoencoders"'}).length>0);
  assert.equal(search(skills,{query:'zzz_nonexistent_123'}).length,0);
  const hits=search(skills,{query:'genomics audit'});
  assert.ok(hits.some(s=>s.id==='hybrid-genomics-project-audit'));
});
test('filters intersect and duplicate-name grouping preserves one',()=>{
  const hits=search(skills,{platform:'Model-agnostic',category:'Research & writing'});
  assert.ok(hits.length>0);
  assert.ok(hits.every(s=>s.compatibility==='Model-agnostic' && s.category==='Research & writing'));
  assert.equal(search(skills,{unique:true}).length,new Set(skills.map(s=>s.name)).size);
});
test('provider subject matter does not make a skill agent-specific',()=>{
  assert.equal(raw.find(s=>s.id==='whisper').compatibility,'Model-agnostic');
  assert.equal(raw.find(s=>s.id==='implement').compatibility,'Multi-platform');
  assert.equal(raw.find(s=>s.id==='write-clinical-note').compatibility,'Model-agnostic');
});

test('attribution is display metadata, not an additional search field',()=>{
  const fixture=prepare([{...raw[0],attribution:{authors:[{name:'UniqueCreditNotInInstructions'}],links:[]}}]);
  assert.equal(search(fixture,{query:'UniqueCreditNotInInstructions'}).length,0);
});
