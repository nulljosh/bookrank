// Highlights merge across devices, the same rule as ListenState.merge in the apps. `base` is what this device
// last saw on the row, `server` is the row now. Lines another device added since are kept, lines it removed go,
// and this device's own changes win on top. Each highlight is { ch, text }.
const key = m => `${m.ch}\u0000${m.text}`;

export function mergeMarks(base, local, server) {
  const b = new Set(base.map(key)), s = new Set(server.map(key)), l = new Set(local.map(key));
  const kept = local.filter(m => b.has(key(m)) ? s.has(key(m)) : true);   // dropped elsewhere since base: gone
  return [...kept, ...server.filter(m => !b.has(key(m)) && !l.has(key(m)))];
}
