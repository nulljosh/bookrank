import assert from 'node:assert/strict';
const store = {};
globalThis.localStorage = { getItem: k => store[k] ?? null, setItem: (k, v) => { store[k] = v; }, removeItem: k => { delete store[k]; } };
const { save, flush, pending } = await import('./outbox.js');
let online = false; const sent = [];
const send = async (id, f) => online ? (sent.push([id, f]), { error: null }) : { error: Object.assign(new Error('offline'), { status: 0 }) };
assert.equal((await save(send, 'a', { notes: { 0: 'x' } })).queued, true);
await save(send, 'a', { collection: 'Work' });
await save(send, 'b', { listen: { pos: 1 } });
assert.equal(pending(), 2);
await flush(send); assert.equal(pending(), 2);   // still offline: kept
online = true; await flush(send);
assert.equal(pending(), 0);
assert.deepEqual(sent[0], ['a', { notes: { 0: 'x' }, collection: 'Work' }]);   // merged into one save
const refuse = async () => ({ error: Object.assign(new Error('gone'), { status: 404 }) });
store['kernel.outbox'] = JSON.stringify({ c: { cover: 'u' } }); await flush(refuse); assert.equal(pending(), 0);
console.log('outbox ok');
