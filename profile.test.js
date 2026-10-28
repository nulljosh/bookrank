// node --test — the profile page's pure bits, pulled out of profile.html's module.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, writeFileSync } from 'node:fs';
const src = readFileSync(new URL('./profile.html', import.meta.url), 'utf8').match(/<script type="module">([\s\S]*?)<\/script>/)[1];
// keep only the exported helpers; the rest needs a DOM
writeFileSync('/tmp/profile-helpers.mjs', src.split('\n').filter(l => !l.startsWith('import ') && !l.startsWith('const db = ')).join('\n').split('const showAvatar')[0]);
const { handleFor, avatarSVG } = await import('/tmp/profile-helpers.mjs');

test('handle falls back to the email local part, lowercased and cleaned', () => {
  assert.equal(handleFor({ email: 'Trommatic@icloud.com', user_metadata: {} }), 'trommatic');
  assert.equal(handleFor({ email: 'x@y.z', user_metadata: { username: 'Josh Tro!' } }), 'joshtro');
});

test('avatar is a 16x16 book sprite in house colours, stable per email', async () => {
  const { BOOKS } = await import('/tmp/profile-helpers.mjs');
  for (const b of BOOKS) { assert.equal(b.length, 16); for (const r of b) assert.equal(r.length, 16, r); }
  let n = 0; const rand = () => ((n++ * 7919) % 1000) / 1000;
  const svg = avatarSVG(rand);
  assert.match(svg, /^<svg [^>]*viewBox="0 0 64 64"/);
  assert.ok([...svg.matchAll(/<rect x="\d+" y="\d+" width="4" height="4"/g)].length > 40);
  assert.doesNotMatch(svg, /#7b2d8b|#c77dff|#00b4d8/i);
  assert.equal(avatarSVG(Math.random, 'a@b.c'), avatarSVG(Math.random, 'a@b.c'));
  assert.notEqual(avatarSVG(Math.random, 'a@b.c'), avatarSVG(Math.random, 'z@y.x'));
});
