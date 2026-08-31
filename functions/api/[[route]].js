// REST surface. Thin: every route shuffles arguments into callTool() in src/lib/tools.js,
// which functions/mcp.js also calls. No shelf logic lives here.

import { callTool, ToolError, TOOL_NAMES } from '../../src/lib/tools.js';

const CORS = {
  'access-control-allow-origin': '*',
  'access-control-allow-headers': 'content-type',
  'access-control-allow-methods': 'GET, OPTIONS',
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
  'POST /mcp': 'Model Context Protocol, JSON-RPC. Same four tools.',
};

const ROUTES = {
  '/api/sections': 'list_sections',
  '/api/books': 'list_books',
  '/api/search': 'search_books',
  '/api/book': 'get_book',
};

export async function onRequest({ request }) {
  if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: CORS });
  // The shelf is read-only from outside; writing summaries is a signed-in, per-user action
  // and stays in library.html against Supabase, where RLS can see who is asking.
  if (request.method !== 'GET') return json({ error: 'This API is read-only; use GET.' }, 405);

  const url = new URL(request.url);
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
