import {test} from 'node:test';
import assert from 'node:assert/strict';
import {attributionHTML} from '../site/attribution.js';
test('author links use declared URLs, otherwise the source declaration',()=>{
  const html=attributionHTML({id:'example',attribution:{authors:[{name:'A & B',url:'https://example.org'}]}});
  assert.match(html,/A &amp; B/);assert.match(html,/https:\/\/example.org/);
  const fallback=attributionHTML({id:'example',attribution:{authors:[{name:'Name'}]}});
  assert.match(fallback,/skills\/example\/SKILL.md/);
});
test('related repositories are not presented as authors and unsafe URLs are inert',()=>{
  const html=attributionHTML({id:'example',attribution:{authors:[{name:'user',unspecified:true}],links:[{label:'org/project',kind:'related',url:'https://github.com/org/project'},{label:'unsafe',url:'javascript:alert(1)'}]}},true);
  assert.match(html,/Related project:/);assert.doesNotMatch(html,/Author: user|href="javascript:/);
});
