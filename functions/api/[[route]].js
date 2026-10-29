// REST surface. Thin: every route shuffles arguments into callTool() in src/lib/tools.js,
// which functions/mcp.js also calls. No shelf logic lives here.

import { callTool, ToolError, TOOL_NAMES } from '../../src/lib/tools.js';
import { callSummaryTool, SummaryError } from '../../src/lib/summaries.js';

const CORS = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'content-type, authorization',
  'access-control-allow-methods': 'GET, POST, PATCH, OPTIONS',
};

const json = (body, status = 200) =>
  new Response(JSON.stringify(body, null, 2), {
    status,
    headers: { 'content-type': 'application/json', 'cache-control': 'public, max-age=3600', ...CORS },
  });

const ENDPOINTS = {
  'GET /api/sections': 'The shelves, with counts.',
  'GET /api/books?section=&limit=&offset=': 'Books on the shelf, paginated.',
  'GET /api/search?q=&limit=&section=': 'Books matching a query.',
  'GET /api/book?title=': 'One book by title.',
  'GET /api/summaries': 'Your summaries (Authorization: Bearer <your Kernel token>).',
  'POST /api/summaries': 'Add one: { title, markdown }.',
  'GET /api/summaries/:id': 'One of yours, as Markdown.',
  'PATCH /api/summaries/:id': 'Change its { title, markdown }.',
  'POST /mcp': 'Model Context Protocol, JSON-RPC. The same tools, yours with the same token.',
};

const ROUTES = {
  '/api/sections': 'list_sections',
  '/api/books': 'list_books',
  '/api/search': 'search_books',
  '/api/book': 'get_book',
};

export async function onRequest({ request }) {
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
  const url = new URL(request.url);
  // Your own summaries: signed in with your token, passed through to jaybulb-api, never cached.
  const mine = url.pathname.replace(/\/+$/, '').match(/^\/api\/summaries(?:\/([^/]+))?$/);
  if (mine) return summaries(request, mine[1]);
  // The shelf is read-only from outside.
  if (request.method !== 'GET') return json({ error: 'This API is read-only; use GET.' }, 405);

  const path = url.pathname.replace(/\/+$/, '');
  const p = url.searchParams;
  const tool = ROUTES[path];

  if (!tool) {
    if (path === '/api') return json({ endpoints: ENDPOINTS, tools: TOOL_NAMES });
    return json({ error: `Unknown endpoint: GET ${url.pathname}`, endpoints: ENDPOINTS }, 404);
  }

  try {
    return json(
      callTool(tool, {
        section: p.get('section'),
        limit: p.get('limit'),
        offset: p.get('offset'),
        q: p.get('q'),
        title: p.get('title'),
      }),
    );
  } catch (err) {
    if (err instanceof ToolError) return json({ error: err.message, tool }, 400);
    throw err;
  }
}

async function summaries(request, id) {
  const tool = { 'GET': id ? 'read_summary' : 'my_summaries', 'POST': id ? null : 'create_summary', 'PATCH': id ? 'update_summary' : null }[request.method];
  const send = (body, status = 200) => new Response(JSON.stringify(body, null, 2), { status, headers: { 'content-type': 'application/json', 'cache-control': 'no-store', ...CORS } });
  if (!tool) return send({ error: `${request.method} is not allowed here.` }, 405);
  const body = request.method === 'GET' ? {} : await request.json().catch(() => ({}));
  try { return send(await callSummaryTool(tool, { ...body, id }, request.headers.get('authorization'))); }
  catch (err) {
    if (err instanceof SummaryError) return send({ error: err.message }, err.status);
    throw err;
  }
}
