import { messages, onRequest } from './functions/api/ask.js';
import assert from 'node:assert/strict';

const m = messages('T', 'Sun Tzu says plan first.', 'Why plan?');
assert.match(m[0].content, /only the chapter notes/);
assert.match(m[1].content, /Sun Tzu says plan first\.[\s\S]*Question: Why plan\?/);

// Signed out: 401 before the model is touched.
globalThis.fetch = async () => new Response('', { status: 401 });
const env = { AI: { run: () => { throw new Error('model must not run'); } } };
const post = (body, auth) => new Request('https://x/api/ask', { method: 'POST', headers: auth ? { authorization: auth } : {}, body: JSON.stringify(body) });
assert.equal((await onRequest({ request: post({ text: 'a', question: 'b' }), env })).status, 401);

// Signed in: the answer comes back; an empty question is refused.
globalThis.fetch = async () => new Response('{"id":"u1"}', { status: 200 });
env.AI.run = async () => ({ response: ' Because the ground decides the battle. ' });
const ok = await onRequest({ request: post({ text: 'notes', question: 'why?' }, 'Bearer t'), env });
assert.deepEqual(await ok.json(), { answer: 'Because the ground decides the battle.' });
assert.equal((await onRequest({ request: post({ text: 'notes', question: ' ' }, 'Bearer t'), env })).status, 400);
// Metered: past the daily cap the model is not called.
const kv = new Map(); env.TTS_KV = { get: async k => kv.get(k) ?? null, put: async (k, v) => { kv.set(k, v); } };
env.ASK_DAILY_CHARS = '20';
assert.equal((await onRequest({ request: post({ text: 'notes', question: 'why?' }, 'Bearer t'), env })).status, 200);
env.AI.run = () => { throw new Error('model must not run past the cap'); };
assert.equal((await onRequest({ request: post({ text: 'more notes here', question: 'and?' }, 'Bearer t'), env })).status, 429);
console.log('ask ok');
