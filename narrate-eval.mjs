// Narrator eval (row 93): a fixed set of chapters, each narrated by /api/narrate and scored by plain
// rules, so a prompt change in functions/api/narrate.js is judged on the same set every time.
// Run: node narrate-eval.mjs [base url]. Reads summaries/ (private, gitignored) and the QA account in .env.
import { chapters, plain } from './listen.js';

// Openings, middles, endings, a long dense chapter and the three other languages.
export const CASES = [
  { book: 'good-feng-shui', ch: 0 }, { book: 'good-feng-shui', ch: 6 }, { book: 'good-feng-shui', ch: 'last' },
  { book: 'statistics-for-dummies', ch: 3 }, { book: 'acing-the-system-design-interview', ch: 2 },
  { book: 'sobriety-for-dummies', ch: 'last' }, { book: 'how-ai-thinks', ch: 1, lang: 'fr' },
  { book: 'data-science', ch: 2, lang: 'es' }, { book: 'ibs-for-dummies', ch: 0, lang: 'de' },
];
const GREETING = /\b(welcome|hello|hi there|today we|in this (book|episode)|bienvenue|bienvenid|willkommen)\b/i;
const CLOSE = /\b(one thing to remember|remember this|to sum up|in the end|à retenir|recuerda|merke dir)\b/i;
const ENGLISH = /\b(the|and|of|to|is|that|with)\b/gi;

// Every rule a narration must pass. `lines` are the script's lines; `notes` the chapter text.
export function score(lines, notes, { ch, total, lang }) {
  const text = lines.join(' '), words = text.split(/\s+/).filter(Boolean);
  const sentences = l => (l.match(/[.!?](\s|$)/g) || []).length || 1;
  const grams = s => { const w = plain(s).toLowerCase().split(' '); return new Set(w.slice(0, -7).map((_, i) => w.slice(i, i + 8).join(' '))); };
  const ours = grams(text), theirs = grams(notes);
  const copied = ours.size ? [...ours].filter(g => theirs.has(g)).length / ours.size : 0;
  const last = ch === total - 1;
  const checks = {
    length: lines.length >= 10 && lines.length <= 16,
    sentences: lines.every(l => sentences(l) <= 3),
    noMarkdown: !/[#*`]|^\s*[-•]/m.test(lines.join('\n')),
    ownWords: copied < 0.2,                                                    // explains, never reads the notes back
    opening: ch === 0 || !GREETING.test(lines.slice(0, 2).join(' ')),         // only chapter 1 says hello
    closing: !last || total === 1 || CLOSE.test(lines.slice(-2).join(' ')),
    language: !lang || (text.match(ENGLISH) || []).length / words.length < 0.05,
  };
  return { checks, pass: Object.values(checks).every(Boolean), copied: +copied.toFixed(2) };
}

async function main(base = 'https://bookrank.jaybulb.com') {
  const fs = await import('node:fs');
  const env = Object.fromEntries(fs.readFileSync('.env', 'utf8').split('\n').map(l => l.match(/^(\w+)=(.*)$/)).filter(Boolean).map(m => [m[1], m[2].replace(/^["']|["']$/g, '')]));
  const auth = await fetch('https://api.jaybulb.com/auth/token?grant_type=password', {
    method: 'POST', headers: { 'content-type': 'application/json', origin: base },
    body: JSON.stringify({ email: env.BOOKRANK_QA_EMAIL, password: env.BOOKRANK_QA_PASSWORD }),
  }).then(r => r.json());
  if (!auth.access_token) throw new Error('QA sign-in failed');
  const dir = n => `summaries/${fs.readdirSync('summaries').find(f => f.endsWith(' ' + n + '.md') || f === n + '.md')}`; // names may carry a leading glyph
  let passed = 0;
  for (const c of CASES) {
    const all = chapters(fs.readFileSync(dir(c.book), 'utf8')), ch = c.ch === 'last' ? all.length - 1 : c.ch;
    const res = await fetch(`${base}/api/narrate`, {
      method: 'POST', headers: { authorization: `Bearer ${auth.access_token}`, 'content-type': 'application/json' },
      body: JSON.stringify({ text: all[ch].text, title: c.book, ch, total: all.length, lang: c.lang }),
    });
    const out = res.ok ? await res.json() : { script: [] };
    const s = score(out.script.map(l => l.line), all[ch].text, { ch, total: all.length, lang: c.lang });
    passed += s.pass;
    const failed = Object.entries(s.checks).filter(([, v]) => !v).map(([k]) => k);
    console.log(`${s.pass ? 'pass' : 'FAIL'}  ${c.book} ch ${ch + 1}/${all.length}${c.lang ? ' ' + c.lang : ''}  ${res.ok ? failed.join(', ') || 'ok' : 'HTTP ' + res.status}`);
  }
  console.log(`${passed} of ${CASES.length} pass`);
}

if (import.meta.url === `file://${process.argv[1]}`) main(process.argv[2]).catch(e => { console.error(e.message); process.exit(1); });
