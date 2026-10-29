// Someone's public profile at /profile?u=<username>: the books they shared by link, and their
// highlights from those books if they chose to show them. Off until the owner turns it on in their profile.
const esc = s => String(s).replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);

export async function showPublic(db, u, el) {
  const { data: p } = await db.rpc('public_profile', { u });
  document.title = `${u}, Kernel`;
  if (!p) { el.innerHTML = `<h1>${esc(u)}</h1><p class="sub">This profile is private, or there is no one by that name.</p>`; return; }
  const avatar = p.avatar ? `<img alt="" src="data:image/svg+xml;utf8,${encodeURIComponent(p.avatar)}">` : esc(u[0].toUpperCase());
  const books = p.books.map(b => `<li><a href="/share?t=${encodeURIComponent(b.t)}">${esc(b.title)}</a>${b.marks.map(m => `<blockquote>${esc(m)}</blockquote>`).join('')}</li>`).join('');
  el.innerHTML = `<div class="head"><div class="avatar" style="cursor:default">${avatar}</div><div><h1>${esc(p.username)}</h1>
    <p class="sub">${p.books.length === 1 ? '1 shared book' : `${p.books.length} shared books`}</p></div></div>
    ${books ? `<ul class="list public" translate="no">${books}</ul>` : '<p class="sub">Nothing shared yet.</p>'}`;
}

// Your own switches: the profile is public only with an explicit username, so the email never stands in for it.
export function publicSwitches(db, user, el, handle) {
  const m = user.user_metadata || {};
  el.innerHTML = `<label><input type="checkbox" id="pubOn"${m.public_profile ? ' checked' : ''}> Public profile: books you shared by link, which search engines may then list</label>
    <label><input type="checkbox" id="pubMarks"${m.public_marks ? ' checked' : ''}${m.public_profile ? '' : ' disabled'}> Show my highlights from those books</label>
    <p class="sub" id="pubMsg"></p>`;
  const msg = t => { el.querySelector('#pubMsg').textContent = t; };
  if (m.public_profile) msg(`Anyone with kernel.jaybulb.com/profile?u=${handle} can see it.`);
  el.querySelector('#pubOn').onchange = async e => {
    const on = e.target.checked;
    const { error } = await db.auth.updateUser({ data: { public_profile: on, ...(on && !m.username ? { username: handle } : {}) } });
    if (error) { e.target.checked = !on; msg(error.message); return; }
    m.public_profile = on; el.querySelector('#pubMarks').disabled = !on;
    msg(on ? `Anyone with kernel.jaybulb.com/profile?u=${handle} can see it.` : 'Your profile is private.');
  };
  el.querySelector('#pubMarks').onchange = async e => {
    const { error } = await db.auth.updateUser({ data: { public_marks: e.target.checked } });
    if (error) { e.target.checked = !e.target.checked; msg(error.message); }
  };
}
