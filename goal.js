// Weekly listening goal on the web, the same idea as Goal.swift in the apps: minutes this week
// against a goal you pick, the week's days as dots. Kept in this browser only; the apps count their own.
// ponytail: weeks start on Sunday here (browsers do not expose the locale's first weekday everywhere).
const KEY = 'kernel.goal.web';

export function weekStart(now = new Date()) {
  const d = new Date(now); d.setHours(0, 0, 0, 0); d.setDate(d.getDate() - d.getDay()); return d.getTime();
}

export function load(store = globalThis.localStorage, now = new Date()) {
  let s = {};
  try { s = JSON.parse(store.getItem(KEY)) || {}; } catch {}
  const week = weekStart(now);
  return s.week === week ? s : { target: s.target || 0, week, secs: 0, days: [] };
}

export function save(s, store = globalThis.localStorage) { try { store.setItem(KEY, JSON.stringify(s)); } catch {} }

/** Count `secs` of listening at `now`: minutes toward the goal, and today's dot. */
export function add(s, secs, now = new Date()) {
  const fresh = s.week === weekStart(now) ? s : { target: s.target, week: weekStart(now), secs: 0, days: [] };
  return { ...fresh, secs: fresh.secs + secs, days: [...new Set([...fresh.days, now.getDay()])] };
}

/** The goal row: a gold ring, "12 of 60 min", seven dots, and the goal picker. */
export function render(el, s, now = new Date()) {
  const min = Math.floor(s.secs / 60), f = s.target ? Math.min(1, min / s.target) : 0, c = 2 * Math.PI * 15;
  const dots = 'SMTWTFS'.split('').map((d, i) => `<span class="gd${s.days.includes(i) ? ' on' : ''}${i === now.getDay() ? ' today' : ''}"><small>${d}</small><i></i></span>`).join('');
  const pick = `<select aria-label="Weekly listening goal">${[0, 15, 30, 60, 120].map(m => `<option value="${m}"${m === s.target ? ' selected' : ''}>${m ? `${m} min a week` : 'No weekly goal'}</option>`).join('')}</select>`;
  el.innerHTML = s.target
    ? `<svg viewBox="0 0 36 36" aria-hidden="true"><circle cx="18" cy="18" r="15"/><circle class="arc" cx="18" cy="18" r="15" stroke-dasharray="${f * c} ${c}"/></svg>
       <div><b>${min >= s.target ? 'Weekly goal met' : 'This week'}</b><span>${min} of ${s.target} min</span></div><div class="gdots" aria-hidden="true">${dots}</div>${pick}`
    : pick;
}

// Your reading in numbers, under the library: the same counts as ReadingStats in the apps.
// `books`: [{ content, marks, notes }].
import { chapters, minutes } from './listen.js';
export function readingStats(books) {
  const s = { books: books.length, chapters: 0, minutes: 0, highlights: 0, notes: 0 };
  for (const b of books) {
    s.chapters += chapters(b.content || '').length;
    if (b.content) s.minutes += minutes(b.content);
    s.highlights += b.marks?.length || 0;
    s.notes += Object.keys(b.notes || {}).length;
  }
  return s;
}
