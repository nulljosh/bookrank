// Saves made with no connection (where you stopped, a highlight, a note, a collection), kept in this
// browser and sent when the connection is back. Later saves to the same book merge, newest field wins.
const KEY = 'kernel.outbox';
const read = () => { try { return JSON.parse(localStorage.getItem(KEY)) || {}; } catch { return {}; } };
const write = o => { try { Object.keys(o).length ? localStorage.setItem(KEY, JSON.stringify(o)) : localStorage.removeItem(KEY); } catch {} };

export const pending = () => Object.keys(read()).length;

/** send(id, fields) resolves to { error }; a network failure (status 0) keeps the save for later and counts as done. */
export async function save(send, id, fields) {
  const r = await send(id, fields);
  if (r.error?.status !== 0) return r;
  const o = read(); o[id] = { ...o[id], ...fields }; write(o);
  return { data: null, error: null, queued: true };
}

/** Sends what is waiting. A save the server refuses is dropped, since sending it again will not help. */
export async function flush(send) {
  const o = read();
  for (const [id, fields] of Object.entries(o)) {
    const r = await send(id, fields);
    if (r.error?.status !== 0) delete o[id];
  }
  write(o);
}
