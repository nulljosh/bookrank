// Highlights merge across devices, the same rule as ListenState.merge in the apps. `base` is what this device
// last saw on the row, `server` is the row now. Lines another device added since are kept, lines it removed go,
// and this device's own changes win on top. Each highlight is { ch, text }.
const key = m => `${m.ch}\u0000${m.text}`;

export function mergeMarks(base, local, server) {
  const b = new Set(base.map(key)), s = new Set(server.map(key)), l = new Set(local.map(key));
  const kept = local.filter(m => b.has(key(m)) ? s.has(key(m)) : true);   // dropped elsewhere since base: gone
  return [...kept, ...server.filter(m => !b.has(key(m)) && !l.has(key(m)))];
}

// Every highlight as one Markdown file: a section per book, the chapter's title, each line as a quote.
// Same layout as exportMarkdown in HighlightsView.swift. `books`: [{ title, content, marks }].
import { chapters } from './listen.js';
export function marksMarkdown(books) {
  let out = '# Highlights\n';
  for (const b of books.filter(b => b.marks?.length)) {
    const chs = chapters(b.content || '');
    out = out.trimEnd() + `\n\n## ${b.title}\n\n`;
    let last = null;
    for (const m of [...b.marks].sort((x, y) => x.ch - y.ch)) {
      if (m.ch !== last) { out += `### ${chs[m.ch]?.title || `Chapter ${m.ch + 1}`}\n\n`; last = m.ch; }
      out += `> ${m.text}\n\n`;
    }
  }
  return out.trimEnd() + '\n';
}
