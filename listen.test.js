// node --test — the listen player and its helpers, driven by a fake synth so the
// sequencing bugs the user hit (restarted lines, a gap at every chapter, no pause while
// loading) fail here before they reach a browser.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { coverCandidates, chapters, blocks, chunk, pickVoices, voicePair, matchCover, progress, createPlayer, shareUrl } from './listen.js';

const MD = '# Book\n\n## One\n\nFirst para.\nstill first.\n\n- a\n- b\n\n## Two\n\nSecond.';

test('chapters split on ## and fall back to one chapter', () => {
  assert.deepEqual(chapters(MD).map(c => c.title), ['One', 'Two']);
  assert.deepEqual(chapters('just text').map(c => c.title), ['Whole book']);
  assert.deepEqual(chapters(''), []);
  assert.deepEqual(chapters('# Book\n\n# Intro\n\ntext\n\n# Two\n\nmore').map(c => c.title), ['Intro', 'Two'], 'H1 chapters, title dropped');
  assert.deepEqual(chapters('# Only\n\ntext').map(c => c.title), ['Only']);
  assert.deepEqual(chapters('# Book\n\n# One\n\n## Sub a\n\nx\n\n## Sub b\n\n# Two\n\ny').map(c => c.title), ['One', 'Two'], 'H1 chapters beat H2 subsections');
});

test('blocks: paragraphs join, list items stay separate, rules drop', () => {
  assert.deepEqual(blocks('## One\n\nFirst para.\nstill first.\n\n---\n\n- a\n- b\n\nTail.').map(b => b.line),
    ['One', 'First para. still first.', 'a', 'b', 'Tail.']);
  assert.equal(blocks('- **a**')[0].md, '- **a**');
});

test('chunk keeps offsets and caps length', () => {
  const c = chunk('One two. Three four! ' + 'x'.repeat(450));
  assert.deepEqual(c.slice(0, 2), [{ text: 'One two.', offset: 0 }, { text: 'Three four!', offset: 9 }]);
  assert.equal(c.length, 5);
  assert.equal(c[2].offset, 21);
  assert.equal(c[3].offset, 221);
});

test('pickVoices: same language, local first, capped at six, preferred kept', () => {
  const all = [...Array(20)].map((_, i) => ({ name: 'v' + i, lang: i % 3 ? 'en-US' : 'fr-FR', localService: i > 10 }));
  const l = pickVoices(all, 'en-CA', 'v1');
  assert.equal(l.length, 7);
  assert.ok(l.every(v => v.lang === 'en-US'));
  assert.ok(l[0].localService);
  assert.ok(l.some(v => v.name === 'v1'));
  assert.equal(pickVoices([{ name: 'x', lang: 'de' }], 'en').length, 1, 'no match = whatever exists');
  const [a, b] = voicePair(l, 'v1');
  assert.equal(a.name, 'v1'); assert.notEqual(b, a);
});

test('matchCover: exact, prefix, then contains', () => {
  const books = [{ title: 'Adult Autism Essentials', cover: 'x' }, { title: 'AI in Business', cover: 'y' }, { title: 'No Cover' }];
  assert.equal(matchCover('Adult Autism', books), 'x');
  assert.equal(matchCover('ai in business', books), 'y');
  assert.equal(matchCover('Business', books), 'y');
  assert.equal(matchCover('No Cover', books), null);
  assert.equal(matchCover('', books), null);
});

test('progress weights chapters equally', () => {
  assert.equal(progress(0, 0, 10, 4), 0);
  assert.equal(progress(1, 5, 10, 4), 0.375);
  assert.equal(progress(3, 10, 10, 4), 1);
  assert.equal(progress(0, 0, 0, 0), 0);
});

test('shareUrl', () => assert.equal(shareUrl('https://x.y', 'abc'), 'https://x.y/share.html?t=abc'));

// ---- player against a fake synth ----
function fakeSynth() {
  const s = { spoken: [], queue: [], cancels: 0 };
  s.cancel = () => { s.cancels++; const q = s.queue.splice(0); q.forEach(u => u.onerror?.({ error: 'interrupted' })); };
  s.speak = u => { s.queue.push(u); s.spoken.push(u.text); };
  // finish the current utterance, like the browser firing `end`
  s.finish = () => { const u = s.queue.shift(); u?.onend?.(); };
  s.drain = async () => { while (s.queue.length) { s.finish(); await tick(); } };
  return s;
}
const tick = () => new Promise(r => setTimeout(r, 0));
class Utterance { constructor(t) { this.text = t; } }
const scripts = { 0: [{ host: 'A', line: 'Hello there.' }, { host: 'B', line: 'Why?' }], 1: [{ host: 'A', line: 'Chapter two.' }] };

function make(synth, extra = {}) {
  const calls = [], lines = [];
  const p = createPlayer({
    synth, Utterance, count: () => 2, voices: () => [null, null], rate: () => 1,
    scriptFor: async i => { calls.push(i); await tick(); return scripts[i]; },
    onLine: i => lines.push(i), ...extra,
  });
  return { p, calls, lines };
}

test('plays every line once, in order, across the chapter boundary without a refetch gap', async () => {
  const synth = fakeSynth();
  const done = [];
  const { p, calls, lines } = make(synth, { onDone: w => done.push(w) });
  await p.play(0, 0);
  assert.deepEqual(calls, [0, 1], 'chapter 1 is prefetched while chapter 0 plays');
  await synth.drain();
  assert.deepEqual(synth.spoken, ['Hello there.', 'Why?', 'Chapter two.']);
  assert.deepEqual(lines, [0, 1, 0]);
  assert.deepEqual(calls, [0, 1], 'the prefetched script was reused, not fetched again');
  assert.deepEqual(done, ['end']);
  assert.equal(p.playing, false);
});

test('a stale chapter never speaks after stop() or a new play()', async () => {
  const synth = fakeSynth();
  const { p } = make(synth);
  const first = p.play(0, 0);
  p.stop();               // pause while still "Loading…"
  await first;
  assert.equal(synth.spoken.length, 0, 'nothing queued from the cancelled play');
  assert.equal(p.playing, false);
  await p.play(1, 0);
  await synth.drain();
  assert.deepEqual(synth.spoken, ['Chapter two.']);
});

test('resume from a saved line skips what was already heard', async () => {
  const synth = fakeSynth();
  const { p } = make(synth);
  await p.play(0, 1);
  await synth.drain();
  assert.deepEqual(synth.spoken, ['Why?', 'Chapter two.']);
});

test('non-cancel utterance errors move on instead of stalling', async () => {
  const synth = fakeSynth();
  const { p } = make(synth);
  await p.play(0, 0);
  synth.queue.shift().onerror({ error: 'synthesis-failed' });
  await tick();
  assert.deepEqual(synth.spoken, ['Hello there.', 'Why?']);
  assert.equal(p.line, 1);
});

test('empty script ends cleanly', async () => {
  const synth = fakeSynth();
  const done = [];
  const p = createPlayer({ synth, Utterance, count: () => 1, voices: () => [null, null], rate: () => 1,
    scriptFor: async () => [{ host: 'A', line: '   ' }], onDone: w => done.push(w) });
  await p.play(0, 0);
  assert.deepEqual(done, ['empty']);
  assert.equal(synth.spoken.length, 0);
});

test('coverCandidates: work cover, then isbn, then edition, none when empty', () => {
  const c = coverCandidates({ cover_i: 5, isbn: ['1', '2'], edition_key: ['OL1M'] });
  assert.deepEqual(c, ['https://covers.openlibrary.org/b/id/5-M.jpg',
    'https://covers.openlibrary.org/b/isbn/1-M.jpg?default=false', 'https://covers.openlibrary.org/b/isbn/2-M.jpg?default=false',
    'https://covers.openlibrary.org/b/olid/OL1M-M.jpg?default=false']);
  assert.deepEqual(coverCandidates(null), []);
  assert.deepEqual(coverCandidates({}), []);
});
