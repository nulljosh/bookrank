// node --test: the summary tools need a token, pass it through, and shape jaybulb-api's rows.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { callSummaryTool, SummaryError } from './summaries.js';

const fake = rows => async (url, init) => { fake.last = { url, init }; return new Response(JSON.stringify(rows), { status: 200 }); };

test('no token, no call', async () => {
  await assert.rejects(callSummaryTool('my_summaries', {}, '', () => assert.fail('must not fetch')), e => e instanceof SummaryError && e.status === 401);
});

test('list, read, create and update go to jaybulb-api with your token', async () => {
  const auth = 'Bearer t';
  assert.deepEqual(await callSummaryTool('my_summaries', {}, auth, fake([{ id: 'a', title: 'A' }])), { summaries: [{ id: 'a', title: 'A' }] });
  assert.equal(fake.last.init.headers.authorization, auth);
  assert.deepEqual(await callSummaryTool('read_summary', { id: 'a' }, auth, fake([{ id: 'a', title: 'A', content: '## One', updated_at: 'x' }])), { id: 'a', title: 'A', markdown: '## One', updated_at: 'x' });
  await assert.rejects(callSummaryTool('read_summary', { id: 'zz' }, auth, fake([])), /No summary of yours/);
  assert.deepEqual(await callSummaryTool('create_summary', { title: 'Deep Work', markdown: '## Rules\n\nFocus.' }, auth, fake([{ id: 'n' }])), { id: 'n', title: 'Deep Work' });
  assert.equal(JSON.parse(fake.last.init.body).slug, 'deep-work');
  await callSummaryTool('update_summary', { id: 'a', title: 'B' }, auth, fake([{ id: 'a', title: 'B', updated_at: 'y' }]));
  assert.equal(fake.last.init.method, 'PATCH'); assert.deepEqual(JSON.parse(fake.last.init.body), { title: 'B' });
  assert.equal(await callSummaryTool('nope', {}, auth, fake([])), null);
});
