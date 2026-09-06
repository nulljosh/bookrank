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

test('avatar is a symmetric 8x8 svg with no purple or teal', () => {
  let n = 0; const rand = () => ((n++ * 7919) % 1000) / 1000;
  const svg = avatarSVG(rand);
  assert.match(svg, /^<svg /);
  const rects = [...svg.matchAll(/<rect x="(\d+)" y="(\d+)" width="8" height="8" fill="(#[0-9a-f]+)"/g)].map(m => [+m[1], +m[2], m[3]]);
  for (const [x, y, fill] of rects) assert.ok(rects.some(([x2, y2, f2]) => x2 === 56 - x && y2 === y && f2 === fill), `no mirror for ${x},${y}`);
  assert.doesNotMatch(svg, /#7b2d8b|#c77dff|#00b4d8/i);
});
