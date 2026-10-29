// The site's fixed text in French, Spanish or German, picked from the browser's language.
// ponytail: whole text nodes and placeholder, aria-label and title are swapped by exact match from
// i18n/<lang>.json, including text added later. Sentences put together in JS stay English, and your
// own summaries, titles and notes are never touched.
const lang = (navigator.language || 'en').slice(0, 2);
const SKIP = '.lp-text, .lp-toc ol, [contenteditable], [translate="no"], script, style';
const ATTRS = ['placeholder', 'aria-label', 'title'];

export function translate(root, dict) {
  const swap = s => { const k = s.replace(/\s+/g, ' ').trim(); return dict[k] && s.replace(k, dict[k]); };
  const walk = document.createTreeWalker(root, NodeFilter.SHOW_TEXT | NodeFilter.SHOW_ELEMENT);
  for (let n = root; n; n = walk.nextNode()) {
    const el = n.nodeType === 1 ? n : n.parentElement;
    if (el?.closest(SKIP)) continue;
    if (n.nodeType === 3) { const t = swap(n.data); if (t) n.data = t; continue; }
    for (const a of ATTRS) { const v = n.getAttribute(a); const t = v && swap(v); if (t) n.setAttribute(a, t); }
  }
}

if (['fr', 'es', 'de'].includes(lang)) {
  fetch(`/i18n/${lang}.json`).then(r => r.ok ? r.json() : null).then(dict => {
    if (!dict) return;
    document.documentElement.lang = lang;
    translate(document.body, dict);
    new MutationObserver(ms => { for (const m of ms) for (const n of m.addedNodes) translate(n, dict); })
      .observe(document.body, { childList: true, subtree: true });
  }).catch(() => {});
}
