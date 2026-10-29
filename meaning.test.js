// node --test: search by meaning picks real lines and ranks them by cosine; /api/embed is gated and metered.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { lines, cosine, closest } from './meaning.js';
import { onRequest } from './functions/api/embed.js';

test('lines skips headings and scraps, keeps chapter and line', () => {
  const md = '# Book\n\n## One\n\nShort.\n\nA real sentence that says something worth finding later on.\n\n## Two\n\nAnother real sentence about staying calm under pressure.';
  const l = lines(md);
  assert.equal(l.length, 2);
  assert.deepEqual({ ch: l[1].ch, title: l[1].title }, { ch: 1, title: 'Two' });
  assert.equal(l[0].line, 2);   // the line index the reader shows: heading 0, "Short." 1
});

test('closest ranks by cosine and drops what is not close', () => {
  assert.equal(Math.round(cosine([1, 0], [1, 0]) * 100), 100);
  const books = [{ id: 'b', title: 'B', lines: [{ ch: 0, line: 0, title: 'C', text: 'near' }, { ch: 0, line: 1, title: 'C', text: 'far' }], vecs: [[1, 0.1], [0, 1]] }];
  assert.deepEqual(closest([1, 0], books).map(h => h.text), ['near']);
});

test('/api/embed needs an account and stops at the cap', async () => {
  const post = (body, auth) => new Request('https://x/api/embed', { method: 'POST', headers: auth ? { authorization: auth } : {}, body: JSON.stringify(body) });
  const env = { AI: { run: () => { throw new Error('model must not run'); } } };
  globalThis.fetch = async () => new Response('', { status: 401 });
  assert.equal((await onRequest({ request: post({ texts: ['a'] }), env })).status, 401);
  globalThis.fetch = async () => new Response('{"id":"u1"}', { status: 200 });
  const kv = new Map(); env.TTS_KV = { get: async k => kv.get(k) ?? null, put: async (k, v) => { kv.set(k, v); } };
  env.AI.run = async (_, { text }) => ({ data: text.map(() => [0.123456, 1]) });
  assert.deepEqual(await (await onRequest({ request: post({ texts: ['hello'] }, 'Bearer t'), env })).json(), { vectors: [[0.1235, 1]] });
  assert.equal((await onRequest({ request: post({ texts: [] }, 'Bearer t'), env })).status, 400);
  env.EMBED_DAILY_CHARS = '6';
  env.AI.run = () => { throw new Error('model must not run past the cap'); };
  assert.equal((await onRequest({ request: post({ texts: ['too much text'] }, 'Bearer t'), env })).status, 429);
});
