// The one definition of what Bookrank does over the network. Both surfaces — the REST
// routes in functions/api/ and the MCP server in functions/mcp.js — call `callTool` from
// here, so they cannot drift apart.
//
// Deliberately different from webmcp.js: those tools are STATEFUL and per-user — they read
// and write the signed-in reader's summaries in Supabase. These read the public shelf,
// which is `books.json` and nothing else. That is what keeps this free of a database
// binding, an auth check and a session.
//
// ponytail: books.json is imported, not fetched. It is the repo's source of truth and it
// ships in the bundle; a KV round trip would add latency for a file that only changes when
// someone edits it here.

import books from '../../books.json' with { type: 'json' };

const MAX_LIMIT = 100;
const DEFAULT_LIMIT = 20;

export class ToolError extends Error {}

export const SECTIONS = [...new Set(books.map((b) => b.section))].sort();

// `pick` rows are pointers to a book listed in full elsewhere, so several fields are
// legitimately absent; null them rather than dropping the key, so a client can rely on the
// shape being the same for every row.
const shape = (b) => ({
  title: b.title,
  author: b.author ?? null,
  section: b.section,
  rank: b.rank ?? null,
  rating: b.rating ?? null,
  reviewCount: b.reviewCount ?? null,
  notes: b.notes ?? b.blurb ?? null,
  badges: b.badges ?? (b.badge ? [b.badge] : []),
  cover: b.cover ?? null,
  goodreadsURL: b.goodreadsURL ?? null,
});

const limitOf = (v) => {
  if (v === undefined || v === null || v === '') return DEFAULT_LIMIT;
  const n = Number(v);
  if (!Number.isInteger(n) || n < 1 || n > MAX_LIMIT) {
    throw new ToolError(`limit must be a whole number between 1 and ${MAX_LIMIT}`);
  }
  return n;
};

const sectionOf = (v) => {
  if (v === undefined || v === null || v === '') return null;
  if (typeof v !== 'string') throw new ToolError('section must be a string');
  const s = v.trim();
  if (!SECTIONS.includes(s)) throw new ToolError(`Unknown section: ${v}. Try one of: ${SECTIONS.join(', ')}.`);
  return s;
};

const sectionProp = {
  section: { type: 'string', description: `Restrict to one shelf: ${SECTIONS.join(', ')}.` },
};

export const TOOLS = [
  {
    name: 'list_sections',
    description: 'The shelves on the site, with how many books each holds.',
    inputSchema: { type: 'object', properties: {} },
  },
  {
    name: 'list_books',
    description: 'Books on the shelf, ranked first. Paginated.',
    inputSchema: {
      type: 'object',
      properties: {
        ...sectionProp,
        limit: { type: 'integer', description: `Max results, 1-${MAX_LIMIT}. Default ${DEFAULT_LIMIT}.` },
        offset: { type: 'integer', description: 'How many to skip. Default 0.' },
      },
    },
  },
  {
    name: 'search_books',
    description: 'Books whose title, author or notes match a query.',
    inputSchema: {
      type: 'object',
      properties: {
        q: { type: 'string', description: 'Case-insensitive substring to match.' },
        limit: { type: 'integer', description: `Max results, 1-${MAX_LIMIT}. Default ${DEFAULT_LIMIT}.` },
        ...sectionProp,
      },
      required: ['q'],
    },
  },
  {
    name: 'get_book',
    description: 'One book by exact or partial title.',
    inputSchema: {
      type: 'object',
      properties: { title: { type: 'string', description: 'The title, or enough of it to be unambiguous.' } },
      required: ['title'],
    },
  },
];

export const TOOL_NAMES = TOOLS.map((t) => t.name);

const matches = (b, needle) =>
  [b.title, b.author, b.notes, b.blurb].some((f) => f && f.toLowerCase().includes(needle));

export function callTool(name, args = {}) {
  switch (name) {
    case 'list_sections':
      return {
        total: books.length,
        sections: SECTIONS.map((s) => ({ section: s, count: books.filter((b) => b.section === s).length })),
      };

    case 'list_books': {
      const section = sectionOf(args.section);
      const limit = limitOf(args.limit);
      const offset = args.offset === undefined || args.offset === '' ? 0 : Number(args.offset);
      if (!Number.isInteger(offset) || offset < 0) throw new ToolError('offset must be a whole number, 0 or more');
      const pool = section ? books.filter((b) => b.section === section) : books;
      return { total: pool.length, offset, results: pool.slice(offset, offset + limit).map(shape) };
    }

    case 'search_books': {
      if (typeof args.q !== 'string' || !args.q.trim()) throw new ToolError('q is required');
      const needle = args.q.trim().toLowerCase();
      const limit = limitOf(args.limit);
      const section = sectionOf(args.section);
      const pool = section ? books.filter((b) => b.section === section) : books;
      const hits = pool.filter((b) => matches(b, needle));
      // `total` before slicing, so a caller can tell "20 of 60" from "20 of 20".
      return { query: args.q.trim(), total: hits.length, results: hits.slice(0, limit).map(shape) };
    }

    case 'get_book': {
      if (typeof args.title !== 'string' || !args.title.trim()) throw new ToolError('title is required');
      const needle = args.title.trim().toLowerCase();
      // An exact title wins over a substring, or asking for "Brothers" could return
      // "The Brothers Karamazov" while the exact book sits further down the shelf.
      const hit =
        books.find((b) => b.title.toLowerCase() === needle) ||
        books.find((b) => b.title.toLowerCase().includes(needle));
      if (!hit) throw new ToolError(`No book matching "${args.title}".`);
      return shape(hit);
    }

    default:
      return null;
  }
}
