// Listen: the player and the pure helpers behind it, shared by library.html (owner) and
// share.html (anyone with a link). No DOM in here except what mount() builds itself, so
// listen.test.js can drive the player with a fake synth.
//
// ponytail: one utterance in flight at a time, chained on `end`. Queueing a whole chapter
// at once is what made Chrome drop or restart lines; chaining also lets Pause work while
// the next chapter's script is still loading.

// ---- pure helpers ----

// Chapters: the coarsest heading level that yields at least two, "# " before "## ", the
// same rule Speaker.swift uses. A leading heading with nothing under it is the book
// title, not a chapter. No headings = one chapter.
export function chapters(md) {
  const src = String(md || '');
  const split = mark => src.split(new RegExp(`^(?=${mark} )`, 'm')).filter(c => c.startsWith(mark + ' '))
    .map(c => { const nl = c.indexOf('\n'); return { title: c.slice(mark.length + 1, nl < 0 ? undefined : nl).trim(), text: c, body: nl < 0 ? '' : c.slice(nl).trim() }; });
  const h1 = split('#').filter((c, i) => i > 0 || c.body);
  const parts = h1.length > 1 ? h1 : (split('##').length ? split('##') : h1);
  return parts.length ? parts.map(({ title, text }) => ({ title, text })) : (src.trim() ? [{ title: 'Whole book', text: src }] : []);
}
export const plain = md => String(md || '').replace(/[#*_`>\[\]()]/g, ' ').replace(/\s+/g, ' ').trim();

// "Read the notes" mode: every markdown block (paragraph, list item, heading) is one
// spoken line, so the transcript can highlight it like a host line.
export function blocks(md) {
  const out = [];
  let open = false; // a plain paragraph line is being accumulated
  for (const raw of String(md || '').split('\n')) {
    const t = raw.trim();
    if (!t || /^---+$/.test(t)) { open = false; continue; }
    const special = /^[-*] |^\d+\. |^#/.test(t);
    if (special || !open) { out.push({ host: 'A', md: t }); open = !special; }
    else out[out.length - 1].md += ' ' + t;
  }
  // `line` is what gets spoken and highlighted; `md` is what gets rendered.
  return out.map(b => ({ host: 'A', line: plain(b.md.replace(/^([-*]|\d+\.) /, '')), md: b.md }));
}

// Chrome truncates utterances past ~15s, so split at sentence bounds and hard-cap the
// length. Each chunk keeps its offset into the line for word highlighting.
export function chunk(line, max = 200) {
  const out = [];
  let at = 0;
  for (const s of line.split(/(?<=[.!?])\s+/)) {
    const start = line.indexOf(s, at); at = start + s.length;
    for (let i = 0; i < s.length; i += max) out.push({ text: s.slice(i, i + max), offset: start + i });
  }
  return out.filter(c => c.text.trim());
}

// Device voices live in voices.js; re-exported so pages and tests keep importing from here.
import { pickVoices, voicePair } from './voices.js';
export { pickVoices, voicePair };

// Covers and share links live in covers.js; re-exported so pages keep importing from here.
export { matchCover, coverCandidates, shareUrl } from './covers.js';

// 0..1 across the whole book. Chapters are weighted equally because unfetched ones have
// no line count yet.
export function progress(ch, line, len, count) {
  if (!count) return 0;
  return Math.min(1, (ch + (len ? Math.min(line, len) / len : 0)) / count);
}


// ---- player ----
// opts: { synth, scriptFor(i) -> Promise<lines>, count() -> chapters, voices() -> [a, b],
//         rate() -> number, onLine(i, chIndex), onWord(lineIdx, start, end), onState(), onDone() }
export function createPlayer(o) {
  const p = {
    ch: 0, line: 0, playing: false, loading: false, script: null,
    prefetch: new Map(), // ch -> Promise<lines>
    token: 0,
  };
  const emit = () => o.onState?.(p);
  const scriptFor = i => {
    if (!p.prefetch.has(i)) p.prefetch.set(i, Promise.resolve(o.scriptFor(i)).catch(() => null));
    return p.prefetch.get(i);
  };
  p.invalidate = () => p.prefetch.clear();

  p.stop = () => { p.token++; o.synth.cancel(); p.playing = false; p.loading = false; emit(); };

  // `fraction` (0..1) resumes at the same place in another script, e.g. after a mode switch.
  p.play = async (ch = p.ch, line = p.line, fraction = null) => {
    const tok = ++p.token;
    o.synth.cancel();
    p.ch = ch; p.line = line; p.playing = true; p.loading = true; p.script = null; emit();
    const script = await scriptFor(ch);
    if (tok !== p.token) return;
    p.loading = false;
    if (!script || !script.length || !plain(script.map(l => l.line).join(' '))) { p.playing = false; emit(); o.onDone?.('empty'); return; }
    p.script = script; p.line = Math.min(fraction == null ? line : Math.floor(fraction * script.length), script.length - 1); emit();
    if (ch + 1 < o.count()) scriptFor(ch + 1); // next chapter warms while this one plays
    speakLine(tok);
  };

  function speakLine(tok) {
    if (tok !== p.token) return;
    const script = p.script, i = p.line;
    if (i >= script.length) return nextChapter(tok);
    const l = script[i];
    const [a, b] = o.voices();
    const voice = l.host === 'B' ? b : a;
    const parts = chunk(l.line);
    o.onLine?.(i, p.ch);
    let k = 0;
    const speakPart = () => {
      if (tok !== p.token) return;
      if (k >= parts.length) { p.line = i + 1; return speakLine(tok); }
      const c = parts[k++];
      const u = new o.Utterance(c.text.trim());
      if (voice) { u.voice = voice; u.lang = voice.lang; }
      u.rate = o.rate();
      u.onboundary = e => { if (tok === p.token && e.name === 'word') o.onWord?.(i, c.offset + e.charIndex, c.offset + e.charIndex + (e.charLength || wordLen(c.text, e.charIndex))); };
      u.onend = speakPart;
      // "interrupted"/"canceled" are our own cancel(); else move on.
      u.onerror = e => { if (tok === p.token && !/interrupted|canceled/.test(e.error || '')) speakPart(); };
      o.synth.speak(u);
    };
    speakPart();
  }
  function nextChapter(tok) {
    if (tok !== p.token) return;
    if (p.ch + 1 < o.count()) p.play(p.ch + 1, 0);
    else { p.line = 0; p.playing = false; emit(); o.onDone?.('end'); }
  }
  return p;
}
const wordLen = (t, i) => (t.slice(i).match(/^\S+/) || [''])[0].length;

// ---- UI ----
// Builds the listen view inside `root`: progress bar, controls, chapter sidebar and the
// transcript with line + word highlighting. `api`:
//   { title, content, scripts, narrate(i, text, title, total) -> Promise<lines|null>,
//     save(pos, scripts, marks) (optional), voices() -> SpeechSynthesisVoice[], pos: {ch, line},
//     marks: [{ ch, text }] (saved lines; kept in the row's listen JSON) }
const NATURAL = '__natural';
/** Listening time at about 180 words a minute (~1,100 characters), never under one. Same rule as Swift's `minutes`. */
export const minutes = text => Math.max(1, Math.round((text || '').length / 1100));
/** "45 min", "4 hr 21 min", "2 hr". Same as Swift's `duration`. */
export const duration = m => m < 60 ? `${m} min` : m % 60 ? `${Math.floor(m / 60)} hr ${m % 60} min` : `${m / 60} hr`;

export function mount(root, api) {
  const synth = globalThis.speechSynthesis;
  const chs = chapters(api.content);
  // Old two-host scripts are dropped so they get rebuilt.
  const marks = [...(api.marks || [])];
  let resumed = !!(api.pos && (api.pos.ch || api.pos.line));
  const scripts = Object.fromEntries(Object.entries(api.scripts || {}).filter(([, s]) => !s?.some?.(l => l.host === 'B')));
  root.innerHTML = `
    <div class="lp-bar"><div class="lp-fill"></div></div>
    <div class="lp-controls">
      <button class="lp-prev" aria-label="Previous chapter">◀</button>
      <button class="lp-play primary">Play</button>
      <button class="lp-next" aria-label="Next chapter">▶</button>
      <select class="lp-voice" aria-label="Voice"></select>
      <select class="lp-rate" aria-label="Speed">${[0.75, 0.9, 1, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.75, 2].map(r => `<option value="${r}">${r}×</option>`).join('')}</select>
      <select class="lp-mode" aria-label="How to read it"><option value="talk">Explain it</option><option value="read">Read the notes</option></select>
      <button class="lp-markbtn" aria-label="Highlight this line">Highlight</button>
      <span class="lp-status msg" aria-live="polite"></span>
    </div>
    <div class="lp-body">
      <nav class="lp-toc" aria-label="Chapters"><ol></ol><div class="lp-marks"></div></nav>
      <div class="lp-text" aria-live="off"></div>
    </div>`;
  const q = s => root.querySelector(s);
  const toc = q('.lp-toc ol'), text = q('.lp-text'), fill = q('.lp-fill'), play = q('.lp-play'), status = q('.lp-status');
  const voiceSel = q('.lp-voice'), rateSel = q('.lp-rate'), modeSel = q('.lp-mode');
  // Speed is kept per book, falling back to the last speed picked anywhere.
  const rateKey = () => `bookrank.rate.${api.title || ''}`;
  const voiceKey = () => `bookrank.voice.${api.title || ''}`;
  rateSel.value = localStorage.getItem(rateKey()) || localStorage.getItem('bookrank.rate') || '1';
  modeSel.value = localStorage.getItem('bookrank.mode') || 'talk';

  let list = [];
  function fillVoices() {
    list = pickVoices(api.voices(), navigator.language, localStorage.getItem('bookrank.voice') || '');
    voiceSel.innerHTML = '';
    if (api.speak) voiceSel.append(new Option('Natural: Alice', NATURAL), new Option('Natural: George', NATURAL + 'B'));
    for (const v of list) voiceSel.append(new Option(v.name, v.name));
    const prev = localStorage.getItem(voiceKey()) || localStorage.getItem('bookrank.voice');   // per book first, like speed
    if (prev && (prev.startsWith(NATURAL) ? api.speak : list.some(v => v.name === prev))) voiceSel.value = prev;
    voiceSel.hidden = voiceSel.options.length < 2;
  }
  fillVoices();
  synth.addEventListener?.('voiceschanged', fillVoices);

  chs.forEach((c, i) => {
    const a = Object.assign(document.createElement('a'), { href: '#', textContent: c.title });
    a.append(Object.assign(document.createElement('small'), { textContent: ` ${duration(minutes(c.text))}` }));
    a.onclick = e => { e.preventDefault(); player.play(i, 0); };
    const li = document.createElement('li'); li.append(a); toc.append(li);
  });

  // Natural voices: ElevenLabs audio per line, played behind a speechSynthesis-shaped object so the
  // same player drives both. Word timestamps from the server light each word as it is spoken. Any
  // line it cannot fetch or play falls back to the device voice, so Listen never stalls.
  const natural = () => voiceSel.value.startsWith(NATURAL) && !!api.speak;
  const toReal = u => {
    const r = new globalThis.SpeechSynthesisUtterance(u.text);
    if (u.voice?.voiceURI) { r.voice = u.voice; r.lang = u.voice.lang; }
    r.rate = u.rate || 1; r.onboundary = u.onboundary; r.onend = u.onend; r.onerror = u.onerror;
    return r;
  };
  let audio = null, gen = 0;
  const voice = {
    cancel() { gen++; if (audio) { audio.pause(); audio = null; } synth.cancel(); },
    async speak(u) {
      if (!natural()) return synth.speak(toReal(u));
      const my = gen;
      const r = await api.speak(u.text, voiceSel.value === NATURAL + 'B' ? 'B' : 'A', player.ch).catch(() => null);   // one narrator: the voice picked
      if (my !== gen) return;
      if (!r?.audio) { status.textContent = 'Natural voice unavailable. Using the device voice.'; return synth.speak(toReal(u)); }
      const a = audio = new Audio('data:audio/mpeg;base64,' + r.audio);
      a.playbackRate = u.rate || 1;
      let w = 0;
      const tick = () => {
        if (audio !== a) return;
        while (w < r.words.length && r.words[w].t <= a.currentTime) { const x = r.words[w++]; u.onboundary?.({ name: 'word', charIndex: x.i, charLength: x.n }); }
        if (!a.paused && !a.ended) requestAnimationFrame(tick);
      };
      const fallback = () => { if (audio === a) { audio = null; synth.speak(toReal(u)); } };
      a.onplay = () => requestAnimationFrame(tick);
      a.onended = () => { if (audio === a) { audio = null; u.onend?.(); } };
      a.onerror = fallback;
      a.play().catch(fallback);
    },
  };
  const player = createPlayer({
    synth: voice, Utterance: class { constructor(t) { this.text = t; } },
    count: () => chs.length,
    voices: () => natural() ? [{ host: 'A' }, { host: 'B' }] : voicePair(list, voiceSel.value),
    rate: () => +rateSel.value,
    scriptFor: async i => {
      if (modeSel.value !== 'talk') return blocks(chs[i].text);
      if (scripts[i]) return scripts[i];
      const s = await api.narrate(i, chs[i].text, chs[i].title, chs.length);
      if (s) scripts[i] = s;
      return s || blocks(chs[i].text);
    },
    onState: st => {
      if (st.playing) resumed = true;   // "Continue" only once there is a place to go back to, never for a chapter just opened
      play.textContent = st.playing ? (st.loading ? 'Loading…' : 'Pause') : resumed ? 'Continue' : 'Play';
      play.disabled = false;
      markToc(st.ch);
      if (st.playing && st.loading) { text.innerHTML = '<p class="lp-loading">Preparing this chapter…</p>'; return; }
      if (st.script) renderScript(st.script, st.ch);
      fill.style.width = (progress(st.ch, st.line, st.script?.length || 0, chs.length) * 100) + '%';
      if (!st.playing) api.save?.({ ch: st.ch, line: st.line }, scripts, marks);
    },
    onLine: (i, ch) => {
      const el = text.children[i]; if (!el) return;
      [...text.querySelectorAll('.on')].forEach(e => { e.classList.remove('on'); e.innerHTML = e.dataset.raw; });
      el.classList.add('on');
      el.scrollIntoView({ behavior: 'smooth', block: 'center' });
      status.textContent = `${chs[ch].title} · ${i + 1}/${text.children.length}`;
      fill.style.width = (progress(ch, i, text.children.length, chs.length) * 100) + '%';
    },
    onWord: (i, s, e) => {
      const el = text.children[i]; if (!el) return;
      const raw = el.dataset.line, host = el.dataset.host;
      el.innerHTML = host + esc(raw.slice(0, s)) + '<mark>' + esc(raw.slice(s, e)) + '</mark>' + esc(raw.slice(e));
    },
    onDone: why => { status.textContent = why === 'end' ? 'Finished.' : 'Nothing to read in this chapter.'; },
  });
  player.ch = Math.min(api.pos?.ch || 0, Math.max(0, chs.length - 1));
  player.line = api.pos?.line || 0;

  function renderScript(script, ch) {
    text.innerHTML = '';
    for (const l of script) {
      const host = modeSel.value === 'talk' && script.some(x => x.host === 'B') ? `<b>${esc(l.host)}</b> ` : '';
      const p = document.createElement('div');
      p.dataset.line = l.line; p.dataset.host = host;
      p.innerHTML = host + (l.md ? md(l.md, l.line) : esc(l.line));
      p.dataset.raw = p.innerHTML;
      p.classList.toggle('marked', isMarked(ch, l.line));
      p.onclick = () => player.play(ch, [...text.children].indexOf(p));
      text.append(p);
    }
  }
  // Highlights: a saved line is its chapter and its text, so it survives a rebuilt script.
  function isMarked(ch, t) { return marks.some(m => m.ch === ch && m.text === t); }
  function renderMarks() {
    const box = q('.lp-marks');
    box.innerHTML = marks.length ? '<h4>Highlights</h4>' : '';
    for (const m of marks) {
      const a = Object.assign(document.createElement('a'), { href: '#', textContent: m.text });
      a.onclick = e => { e.preventDefault(); player.stop(); player.ch = m.ch; showChapter(); };
      box.append(a);
    }
  }
  q('.lp-markbtn').hidden = !api.save;   // share links cannot keep highlights
  q('.lp-markbtn').onclick = () => {
    const el = text.children[player.line] || text.querySelector('.on');
    const t = el?.dataset.line; if (!t) return;
    const k = marks.findIndex(m => m.ch === player.ch && m.text === t);
    if (k >= 0) marks.splice(k, 1); else marks.push({ ch: player.ch, text: t });
    el.classList.toggle('marked', k < 0);
    renderMarks();
    api.save?.({ ch: player.ch, line: player.line }, scripts, marks);
  };
  function markToc(i) { [...toc.querySelectorAll('a')].forEach((a, k) => a.classList.toggle('on', k === i)); api.onChapter?.(i); }
  const showChapter = async () => { // idle view: the current chapter's text, no audio
    markToc(player.ch);
    text.innerHTML = '<p class="lp-loading">…</p>';
    const s = modeSel.value === 'talk' && scripts[player.ch] ? scripts[player.ch] : blocks(chs[player.ch]?.text || '');
    renderScript(s, player.ch);
    if (resumed) play.textContent = 'Continue';
    if (api.pos && (api.pos.ch || api.pos.line)) status.textContent = `Resume at ${chs[player.ch].title} · line ${player.line + 1}`;
  };

  // A search.js hit: its chapter's notes, at the line, marked. The mode is not saved.
  const find = f => {
    player.stop(); modeSel.value = 'read'; player.invalidate(); player.ch = f.ch; player.line = f.line; resumed = true;
    showChapter(); const el = text.children[f.line];
    el?.classList.add('found'); el?.scrollIntoView({ block: 'center' }); status.textContent = `Found in ${f.title}`;
  };

  play.onclick = () => player.playing ? player.stop() : player.play();
  q('.lp-prev').onclick = () => player.play(Math.max(0, player.ch - 1), 0);
  q('.lp-next').onclick = () => player.play(Math.min(chs.length - 1, player.ch + 1), 0);
  voiceSel.onchange = () => { localStorage.setItem('bookrank.voice', voiceSel.value); localStorage.setItem(voiceKey(), voiceSel.value); if (player.playing) player.play(player.ch, player.line); };
  rateSel.onchange = () => { localStorage.setItem('bookrank.rate', rateSel.value); localStorage.setItem(rateKey(), rateSel.value); if (player.playing) player.play(player.ch, player.line); };
  modeSel.onchange = () => { localStorage.setItem('bookrank.mode', modeSel.value); const spot = player.script?.length ? player.line / player.script.length : 0; player.invalidate(); if (player.playing) player.play(player.ch, 0, spot); else showChapter(); };
  if ('mediaSession' in navigator) {
    navigator.mediaSession.metadata = new MediaMetadata({ title: api.title });
    navigator.mediaSession.setActionHandler('play', () => player.play());
    navigator.mediaSession.setActionHandler('pause', () => player.stop());
    navigator.mediaSession.setActionHandler('nexttrack', () => q('.lp-next').onclick());
    navigator.mediaSession.setActionHandler('previoustrack', () => q('.lp-prev').onclick());
    // Headphone and lock-screen skip buttons move one line, like the apps' player bar.
    for (const [action, d] of [['seekbackward', -1], ['seekforward', 1]]) {
      try { navigator.mediaSession.setActionHandler(action, () => { if (player.script?.length) player.play(player.ch, Math.max(0, Math.min(player.script.length - 1, player.line + d))); }); } catch {}
    }
  }
  const persist = () => { if (player.playing) api.save?.({ ch: player.ch, line: player.line }, scripts, marks); };
  addEventListener('pagehide', persist);
  document.addEventListener('visibilitychange', () => { if (document.hidden) persist(); });

  if (!chs.length) { text.innerHTML = '<p class="msg">Nothing to read yet.</p>'; play.disabled = true; }
  else showChapter();
  renderMarks();
  return { player, stop: () => player.stop(), scripts, marks, find };
}
// Markdown from a summary (possibly someone else's, via a share link) is untrusted: render it
// through DOMPurify, and fall back to plain escaped text if either library failed to load.
function md(src, plain) {
  const html = globalThis.marked?.parse?.(src);
  return html != null && globalThis.DOMPurify ? globalThis.DOMPurify.sanitize(html) : esc(plain);
}
const esc = s => String(s).replace(/[&<>]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]));
