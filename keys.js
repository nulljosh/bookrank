// Keyboard shortcuts on the web, the same moves as the apps' Listen menu, plus a focus mode that leaves only
// the chapter text. They press the page's own buttons, so a shortcut can never do what a click could not.
// Keys are ignored while you type in a field. ? shows the list.
export const KEYS = [
  [' ', 'Play or pause', '.lp-play'],
  ['j', 'Next chapter', '.lp-next'],
  ['k', 'Previous chapter', '.lp-prev'],
  ['h', 'Highlight the line', '.lp-markbtn'],
  ['f', 'Focus mode: only the text', null],
  ['/', 'Search your summaries', '#find'],
  ['n', 'New summary', '#new'],
  ['Escape', 'Leave focus mode, or close the book', '#close'],
  ['?', 'These shortcuts', null],
];

const typing = el => el && (el.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(el.tagName));
const shown = el => el && el.offsetParent !== null && !el.disabled;

export function installKeys(doc = document) {
  const help = doc.createElement('dialog');
  help.id = 'keysHelp';
  help.innerHTML = `<h2>Shortcuts</h2><dl>${KEYS.map(([k, what]) => `<dt><kbd>${k === ' ' ? 'Space' : k === 'Escape' ? 'Esc' : k}</kbd></dt><dd>${what}</dd>`).join('')}</dl><form method="dialog"><button>Done</button></form>`;
  doc.body.append(help);
  doc.addEventListener('keydown', e => {
    if (e.metaKey || e.ctrlKey || e.altKey || typing(e.target)) return;
    if (help.open && e.key !== '?') return;   // the dialog handles Esc itself
    const k = KEYS.find(([key]) => key === e.key);
    if (!k) return;
    if (e.key === '?') { help.open ? help.close() : help.showModal(); e.preventDefault(); return; }
    if (e.key === 'f') { if (shown(doc.querySelector('.lp-play'))) { doc.body.classList.toggle('focus'); e.preventDefault(); } return; }
    if (e.key === 'Escape' && doc.body.classList.contains('focus')) { doc.body.classList.remove('focus'); e.preventDefault(); return; }
    const el = doc.querySelector(k[2]);
    if (!shown(el)) return;
    e.preventDefault();
    el.tagName === 'INPUT' ? el.focus() : el.click();
  });
}
