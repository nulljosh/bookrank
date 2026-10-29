// Device voices for the player when natural voices are off: a short list and a matching pair.
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
