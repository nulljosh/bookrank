// Study aids pulled from a summary's own text, on the device, no model: a book's key ideas, a chapter's two-line
// recap, and a short quiz that blanks out the chapter's bold terms. Same rules as Study.swift in the apps.
import { chapters } from './listen.js';

const TAKE = /^#{1,6}\s*(key takeaways?|takeaways?|key ideas|key points|lessons|in short|summary)\b/i;
const clean = s => s.replace(/^\s*(?:[-*•]|\d+\.)\s+/, '').replace(/\*\*|__|`/g, '').replace(/\[([^\]]+)\]\([^)]+\)/g, '$1').trim();
// Bold labels are not terms worth asking about.
const LABEL = /^(key|note|tip|example|photo|warning|remember|important|takeaway|summary|chapter|part)\b/i;
const sentences = p => clean(p).split(/(?<=[.!?])\s+(?=[A-Z0-9“"])/).filter(s => s.length >= 25);

/** The bullet lines under a chapter's "Key takeaways" (or similar) heading. */
export function takeaways(text) {
  const out = []; let on = false;
  for (const line of text.split('\n')) {
    if (/^#{1,6}\s/.test(line)) { on = TAKE.test(line); continue; }
    const m = on && line.match(/^\s*(?:[-*•]|\d+\.)\s+(.*)/);
    if (m && clean(m[1]).length >= 20) out.push(clean(m[1]));
  }
  return out;
}

const paragraphs = text => text.split(/\n\s*\n/).map(p => p.trim()).filter(p => p && !/^#/.test(p) && !/^\s*(?:[-*•]|\d+\.)\s/m.test(p) && clean(p).length >= 40);

/** Up to five ideas for the top of a book: each chapter's first takeaway, or its opening sentence. */
export function keyIdeas(content, n = 5) {
  const out = [];
  for (const c of chapters(content)) {
    const t = takeaways(c.text)[0] || sentences(paragraphs(c.text)[0] || '')[0];
    if (t && !out.includes(t)) out.push(t);
    if (out.length >= n) break;
  }
  return out;
}

/** Two lines to close a chapter: its first two takeaways, or the last paragraph's first two sentences. */
export function recap(text) {
  const t = takeaways(text);
  if (t.length) return t.slice(0, 2);
  const ps = paragraphs(text);
  return sentences(ps[ps.length - 1] || '').slice(0, 2);
}

/** Up to three questions: a sentence with one bold term blanked, that term and two others from the book to pick
 *  from, in a fixed order per question so a retry asks the same. */
export function quiz(text, bookContent = text, n = 3) {
  const terms = [...new Set([...bookContent.matchAll(/\*\*([^*\n]{2,40})\*\*/g)].map(m => m[1].trim().replace(/:$/, '')))].filter(t => !LABEL.test(t));
  const qs = [];
  for (const line of text.split('\n')) {
    if (/^#/.test(line)) continue;
    for (const m of line.matchAll(/\*\*([^*\n]{2,40})\*\*/g)) {
      const answer = m[1].trim().replace(/:$/, ''), sentence = clean(line);
      // A question needs a real sentence around the blank: eight words or more besides the term.
      // A sentence that stops on a colon (it introduces a list) makes a poor question.
      if (/:$/.test(sentence) || LABEL.test(answer) || sentence.replace(answer, '').split(/\s+/).filter(w => /\w/.test(w)).length < 8 || qs.some(q => q.answer === answer)) continue;
      const others = terms.filter(t => t !== answer);
      if (others.length < 2) continue;
      const pick = [others[(answer.length * 7) % others.length], others[(answer.length * 13 + 1) % others.length]];
      if (pick[0] === pick[1]) pick[1] = others.find(t => t !== pick[0]);
      const choices = [answer, ...pick].sort((a, b) => (a.length * 31 + a.charCodeAt(0)) % 7 - (b.length * 31 + b.charCodeAt(0)) % 7);
      qs.push({ question: sentence.replace(answer, '_____'), answer, choices });
      break;
    }
    if (qs.length >= n) break;
  }
  return qs;
}
