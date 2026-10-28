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
globalThis.fetch = async () => new Response('{}', { status: 200 });
env.AI.run = async () => ({ response: ' Because the ground decides the battle. ' });
const ok = await onRequest({ request: post({ text: 'notes', question: 'why?' }, 'Bearer t'), env });
assert.deepEqual(await ok.json(), { answer: 'Because the ground decides the battle.' });
assert.equal((await onRequest({ request: post({ text: 'notes', question: ' ' }, 'Bearer t'), env })).status, 400);
console.log('ask ok');
