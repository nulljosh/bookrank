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

// A short list instead of the device's 100+: the user's language only, local voices
// first, one per name, six at most. `preferred` (a saved name) is kept even if it is
// past the cap.
export function pickVoices(all, lang = 'en', preferred = '') {
  const base = lang.split('-')[0].toLowerCase();
  const seen = new Set();
  const mine = all.filter(v => v.lang.toLowerCase().startsWith(base) && !seen.has(v.name) && seen.add(v.name))
    .sort((a, b) => (b.localService === true) - (a.localService === true) || (b.default === true) - (a.default === true));
  const pool = mine.length ? mine : all;
  const list = pool.slice(0, 6);
  const p = pool.find(v => v.name === preferred);
  if (p && !list.includes(p)) list.push(p);
  return list;
}
export function voicePair(list, name) {
  const a = list.find(v => v.name === name) || list[0];
  return [a, list.find(v => v !== a && a && v.lang === a.lang) || a];
}

// Thumbnails: exact title match first, then either title starting with the other
// ("Adult Autism" vs "Adult Autism Essentials"), then a contains match.
const norm = s => String(s || '').toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim();
export function matchCover(title, books) {
  const t = norm(title); if (!t) return null;
  const withCover = books.filter(b => b.cover);
  const pick = f => withCover.find(b => f(norm(b.title)))?.cover || null;
  return pick(n => n === t) || pick(n => n.startsWith(t) || t.startsWith(n)) || pick(n => n.includes(t) || t.includes(n));
}

// Candidate cover URLs from one Open Library search doc: the work cover, then each ISBN
// and edition, which often carry a cover the work does not. `default=false` makes a miss a
// 404 the browser can detect instead of a placeholder image.
export function coverCandidates(doc) {
  if (!doc) return [];
  const out = [];
  if (doc.cover_i) out.push(`https://covers.openlibrary.org/b/id/${doc.cover_i}-M.jpg`);
  for (const i of (doc.isbn || []).slice(0, 4)) out.push(`https://covers.openlibrary.org/b/isbn/${i}-M.jpg?default=false`);
  for (const k of (doc.edition_key || []).slice(0, 3)) out.push(`https://covers.openlibrary.org/b/olid/${k}-M.jpg?default=false`);
  return out;
}

// 0..1 across the whole book. Chapters are weighted equally because unfetched ones have
// no line count yet.
export function progress(ch, line, len, count) {
  if (!count) return 0;
  return Math.min(1, (ch + (len ? Math.min(line, len) / len : 0)) / count);
}

// Public share URL for a token.
export const shareUrl = (origin, token) => `${origin}/share.html?t=${token}`;

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

  p.play = async (ch = p.ch, line = p.line) => {
    const tok = ++p.token;
    o.synth.cancel();
    p.ch = ch; p.line = line; p.playing = true; p.loading = true; p.script = null; emit();
    const script = await scriptFor(ch);
    if (tok !== p.token) return;
    p.loading = false;
    if (!script || !script.length || !plain(script.map(l => l.line).join(' '))) { p.playing = false; emit(); o.onDone?.('empty'); return; }
    p.script = script; p.line = Math.min(line, script.length - 1); emit();
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
      // "interrupted"/"canceled" come from our own cancel(); anything else, move on rather than stall.
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
//     save(pos, scripts) (optional), voices() -> SpeechSynthesisVoice[], pos: {ch, line} }
export function mount(root, api) {
  const synth = globalThis.speechSynthesis;
  const chs = chapters(api.content);
  const scripts = { ...(api.scripts || {}) };
  root.innerHTML = `
    <div class="lp-bar"><div class="lp-fill"></div></div>
    <div class="lp-controls">
      <button class="lp-prev" aria-label="Previous chapter">◀</button>
      <button class="lp-play primary">Play</button>
      <button class="lp-next" aria-label="Next chapter">▶</button>
      <select class="lp-voice" aria-label="Voice"></select>
      <select class="lp-rate" aria-label="Speed"><option value="1">1×</option><option value="1.25">1.25×</option><option value="1.5">1.5×</option><option value="2">2×</option></select>
      <select class="lp-mode" aria-label="How to read it"><option value="talk">Explain it</option><option value="read">Read the notes</option></select>
      <span class="lp-status msg" aria-live="polite"></span>
    </div>
    <div class="lp-body">
      <nav class="lp-toc" aria-label="Chapters"><ol></ol></nav>
      <div class="lp-text" aria-live="off"></div>
    </div>`;
  const q = s => root.querySelector(s);
  const toc = q('.lp-toc ol'), text = q('.lp-text'), fill = q('.lp-fill'), play = q('.lp-play'), status = q('.lp-status');
  const voiceSel = q('.lp-voice'), rateSel = q('.lp-rate'), modeSel = q('.lp-mode');
  rateSel.value = localStorage.getItem('bookrank.rate') || '1';
  modeSel.value = localStorage.getItem('bookrank.mode') || 'talk';

  let list = [];
  function fillVoices() {
    list = pickVoices(api.voices(), navigator.language, localStorage.getItem('bookrank.voice') || '');
    voiceSel.innerHTML = '';
    for (const v of list) voiceSel.append(new Option(v.name, v.name));
    const prev = localStorage.getItem('bookrank.voice');
    if (prev && list.some(v => v.name === prev)) voiceSel.value = prev;
    voiceSel.hidden = list.length < 2;
  }
  fillVoices();
  synth.addEventListener?.('voiceschanged', fillVoices);

  chs.forEach((c, i) => {
    const a = Object.assign(document.createElement('a'), { href: '#', textContent: c.title });
    a.onclick = e => { e.preventDefault(); player.play(i, 0); };
    const li = document.createElement('li'); li.append(a); toc.append(li);
  });

  const player = createPlayer({
    synth, Utterance: globalThis.SpeechSynthesisUtterance,
    count: () => chs.length,
    voices: () => voicePair(list, voiceSel.value),
    rate: () => +rateSel.value,
    scriptFor: async i => {
      if (modeSel.value !== 'talk') return blocks(chs[i].text);
      if (scripts[i]) return scripts[i];
      const s = await api.narrate(i, chs[i].text, chs[i].title, chs.length);
      if (s) scripts[i] = s;
      return s || blocks(chs[i].text);
    },
    onState: st => {
      play.textContent = st.playing ? (st.loading ? 'Loading…' : 'Pause') : 'Play';
      play.disabled = false;
      markToc(st.ch);
      if (st.playing && st.loading) { text.innerHTML = '<p class="lp-loading">Preparing this chapter…</p>'; return; }
      if (st.script) renderScript(st.script, st.ch);
      fill.style.width = (progress(st.ch, st.line, st.script?.length || 0, chs.length) * 100) + '%';
      if (!st.playing) api.save?.({ ch: st.ch, line: st.line }, scripts);
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
      const host = modeSel.value === 'talk' && script.some(x => x.host === 'B') ? `<b>${l.host}</b> ` : '';
      const p = document.createElement('div');
      p.dataset.line = l.line; p.dataset.host = host;
      p.innerHTML = host + (l.md ? (globalThis.marked?.parse?.(l.md) ?? esc(l.line)) : esc(l.line));
      p.dataset.raw = p.innerHTML;
      p.onclick = () => player.play(ch, [...text.children].indexOf(p));
      text.append(p);
    }
  }
  function markToc(i) { [...toc.querySelectorAll('a')].forEach((a, k) => a.classList.toggle('on', k === i)); }
  const showChapter = async () => { // idle view: the current chapter's text, no audio
    markToc(player.ch);
    text.innerHTML = '<p class="lp-loading">…</p>';
    const s = modeSel.value === 'talk' && scripts[player.ch] ? scripts[player.ch] : blocks(chs[player.ch]?.text || '');
    renderScript(s, player.ch);
    if (api.pos && (api.pos.ch || api.pos.line)) status.textContent = `Resume at ${chs[player.ch].title} · line ${player.line + 1}`;
  };

  play.onclick = () => player.playing ? player.stop() : player.play();
  q('.lp-prev').onclick = () => player.play(Math.max(0, player.ch - 1), 0);
  q('.lp-next').onclick = () => player.play(Math.min(chs.length - 1, player.ch + 1), 0);
  voiceSel.onchange = () => { localStorage.setItem('bookrank.voice', voiceSel.value); if (player.playing) player.play(player.ch, player.line); };
  rateSel.onchange = () => { localStorage.setItem('bookrank.rate', rateSel.value); if (player.playing) player.play(player.ch, player.line); };
  modeSel.onchange = () => { localStorage.setItem('bookrank.mode', modeSel.value); player.invalidate(); if (player.playing) player.play(player.ch, 0); else showChapter(); };
  if ('mediaSession' in navigator) {
    navigator.mediaSession.metadata = new MediaMetadata({ title: api.title });
    navigator.mediaSession.setActionHandler('play', () => player.play());
    navigator.mediaSession.setActionHandler('pause', () => player.stop());
    navigator.mediaSession.setActionHandler('nexttrack', () => q('.lp-next').onclick());
    navigator.mediaSession.setActionHandler('previoustrack', () => q('.lp-prev').onclick());
  }
  const persist = () => { if (player.playing) api.save?.({ ch: player.ch, line: player.line }, scripts); };
  addEventListener('pagehide', persist);
  document.addEventListener('visibilitychange', () => { if (document.hidden) persist(); });

  if (!chs.length) { text.innerHTML = '<p class="msg">Nothing to read yet.</p>'; play.disabled = true; }
  else showChapter();
  return { player, stop: () => player.stop(), scripts };
}
const esc = s => String(s).replace(/[&<>]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;' }[c]));
