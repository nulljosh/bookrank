// Your own summaries over /api/summaries and /mcp, for scripts and agents. Every call carries your Kernel
// sign-in as `Authorization: Bearer <token>` and goes straight through to jaybulb-api, whose row rules only
// ever show and change your own rows. Nothing is stored here. Writing content moves updated_at, as in the app.
const API = 'https://api.jaybulb.com/rest/bookrank_summaries';

export const SUMMARY_TOOLS = [
  { name: 'my_summaries', description: 'Your Kernel summaries: id, title, last edited. Needs your sign-in token.',
    inputSchema: { type: 'object', properties: {} } },
  { name: 'read_summary', description: 'One of your summaries in full, as Markdown.',
    inputSchema: { type: 'object', properties: { id: { type: 'string' } }, required: ['id'] } },
  { name: 'create_summary', description: 'A new summary from a title and Markdown ("## " per chapter).',
    inputSchema: { type: 'object', properties: { title: { type: 'string' }, markdown: { type: 'string' } }, required: ['title', 'markdown'] } },
  { name: 'update_summary', description: 'Change a summary\'s title or Markdown.',
    inputSchema: { type: 'object', properties: { id: { type: 'string' }, title: { type: 'string' }, markdown: { type: 'string' } }, required: ['id'] } },
];
export const SUMMARY_TOOL_NAMES = SUMMARY_TOOLS.map(t => t.name);

export class SummaryError extends Error { constructor(message, status = 400) { super(message); this.status = status; } }

const slugify = t => t.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '') || 'untitled';

export async function callSummaryTool(name, args, auth, fetcher = fetch) {
  if (!/^Bearer \S+/.test(auth || '')) throw new SummaryError('Sign in first: send your Kernel token as Authorization: Bearer <token>.', 401);
  const call = async (path, init = {}) => {
    const r = await fetcher(API + path, { ...init, headers: { authorization: auth, 'content-type': 'application/json', prefer: 'return=representation', ...init.headers } });
    const body = await r.json().catch(() => null);
    if (!r.ok) throw new SummaryError(body?.message || body?.error || `jaybulb-api said ${r.status}.`, r.status);
    return body;
  };
  const id = String(args.id || '').trim(), title = String(args.title || '').trim(), md = String(args.markdown || '');
  switch (name) {
    case 'my_summaries': return { summaries: await call('?select=id,title,updated_at&order=updated_at.desc') };
    case 'read_summary': {
      if (!id) throw new SummaryError('Which summary? Pass its id.');
      const [row] = await call(`?id=eq.${encodeURIComponent(id)}&select=id,title,content,updated_at`);
      if (!row) throw new SummaryError('No summary of yours with that id.', 404);
      return { id: row.id, title: row.title, markdown: row.content, updated_at: row.updated_at };
    }
    case 'create_summary': {
      if (!title || !md.trim()) throw new SummaryError('A title and some Markdown, please.');
      const [row] = await call('', { method: 'POST', body: JSON.stringify({ slug: slugify(title), title, content: md, updated_at: new Date().toISOString() }) });
      return { id: row?.id, title };
    }
    case 'update_summary': {
      if (!id || (!title && !md.trim())) throw new SummaryError('Pass the id and a new title or Markdown.');
      const patch = { ...(title && { title }), ...(md.trim() && { content: md }) };
      const [row] = await call(`?id=eq.${encodeURIComponent(id)}`, { method: 'PATCH', body: JSON.stringify(patch) });
      if (!row) throw new SummaryError('No summary of yours with that id.', 404);
      return { id: row.id, title: row.title, updated_at: row.updated_at };
    }
    default: return null;
  }
}
