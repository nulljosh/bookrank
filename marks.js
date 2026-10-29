// Highlights merge across devices, the same rule as ListenState.merge in the apps. `base` is what this device
// last saw on the row, `server` is the row now. Lines another device added since are kept, lines it removed go,
// and this device's own changes win on top. Each highlight is { ch, text }.
const key = m => `${m.ch}\u0000${m.text}`;

export function mergeMarks(base, local, server) {
  const b = new Set(base.map(key)), s = new Set(server.map(key)), l = new Set(local.map(key));
  const kept = local.filter(m => b.has(key(m)) ? s.has(key(m)) : true);   // dropped elsewhere since base: gone
  return [...kept, ...server.filter(m => !b.has(key(m)) && !l.has(key(m)))];
}

// Every highlight and note as one Markdown file: a section per book, the chapter's title, the lines as quotes,
// then your note.
// Same layout as exportMarkdown in HighlightsView.swift. `books`: [{ title, content, marks }].
import { chapters } from './listen.js';
export function marksMarkdown(books) {
  let out = '# Highlights\n';
  for (const b of books) {
    const marks = b.marks || [], notes = b.notes || {};
    const chs = [...new Set([...marks.map(m => m.ch), ...Object.keys(notes).map(Number)])].sort((x, y) => x - y);
    if (!chs.length) continue;
    const titles = chapters(b.content || '');
    out = out.trimEnd() + `\n\n## ${b.title}\n\n`;
    for (const ch of chs) {
      out += `### ${titles[ch]?.title || `Chapter ${ch + 1}`}\n\n`;
      for (const m of marks.filter(m => m.ch === ch)) out += `> ${m.text}\n\n`;
      if (notes[ch]) out += `${notes[ch]}\n\n`;
    }
  }
  return out.trimEnd() + '\n';
}

// Today's five: the same five highlights on every device for a given day, a different five tomorrow.
// Ranked by FNV-1a of the day and the line; dailyFive in HighlightsView.swift uses the same hash. `day` is "YYYY-MM-DD".
// ponytail: a daily shuffle, not spaced repetition; weight by last seen if people want the old ones back more.
export function dailyFive(marks, day, n = 5) {
  const h = s => { let x = 0x811c9dc5; for (let i = 0; i < s.length; i++) x = Math.imul(x ^ s.charCodeAt(i), 0x01000193) >>> 0; return x; };
  return [...marks].sort((a, b) => h(day + a.text) - h(day + b.text) || (a.text < b.text ? -1 : 1)).slice(0, n);
}
