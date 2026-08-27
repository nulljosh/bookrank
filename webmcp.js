// WebMCP tool registration for the library page (bookrank's only real app).
// Tools call window.__bookrank.rows, the data layer library.html's own module
// script exposes — same Supabase client, same bookrank_summaries queries the UI
// runs. Nothing here talks to Supabase directly.
//
// ponytail: tools use the data layer, never the UI functions. Going through
// open()/saveCurrent() would let a tool null out the editor's `current` or
// overwrite the open textareas, so a user mid-edit would silently insert a
// duplicate on their next Save. Read and write by id; leave the editor alone.
//
// ponytail: index.html and rankings.html are static (a marketing hero and
// hardcoded ranking content) so they get no tools and no bridge — there is
// no real user action to expose there.

const mc = document.modelContext;
if (!mc?.registerTool) {
  // WebMCP not available in this browser/context — do nothing.
} else {
  const bridge = () => window.__bookrank;

  const tools = [
    // ---- read-only ----
    {
      name: 'list_summaries',
      description: 'Lists the signed-in user’s saved book summaries (id, title, last updated). Empty list if signed out or nothing saved yet.',
      inputSchema: { type: 'object', properties: {} },
      execute: async () => {
        const b = bridge();
        if (!b) return { error: 'App not ready.' };
        const { data, error } = await b.rows.list();
        if (error) return { error: error.message };
        return { summaries: data ?? [] };
      },
    },
    {
      name: 'get_summary',
      description: 'Fetches the full text of one saved summary by id.',
      inputSchema: {
        type: 'object',
        properties: { id: { type: 'string', description: 'The summary’s id, from list_summaries.' } },
        required: ['id'],
      },
      execute: async ({ id }) => {
        const b = bridge();
        if (!b) return { error: 'App not ready.' };
        const { data, error } = await b.rows.get(id);
        if (error) return { error: error.message };
        return data ? { summary: data } : { error: 'Not found, or not signed in.' };
      },
    },
    {
      name: 'whoami',
      description: 'Returns the currently signed-in user’s email, or signed-out if nobody is authenticated.',
      inputSchema: { type: 'object', properties: {} },
      execute: async () => {
        const b = bridge();
        if (!b) return { error: 'App not ready.' };
        const user = await b.whoami();
        return user ? { signedIn: true, email: user.email } : { signedIn: false };
      },
    },

    // ---- reversible writes ----
    {
      name: 'create_summary',
      description: 'Creates a new book summary with the given title and body (markdown).',
      inputSchema: {
        type: 'object',
        properties: {
          title: { type: 'string', description: 'Book title.' },
          body: { type: 'string', description: 'Summary content, in markdown.' },
        },
        required: ['title'],
      },
      execute: async ({ title, body }) => {
        const b = bridge();
        if (!b) return { error: 'App not ready.' };
        if (!title?.trim()) return { error: 'Title required.' };
        const { data, error } = await b.rows.insert(b.stamp(title.trim(), body ?? ''));
        if (error) return { error: error.message };
        b.refreshList();
        return { summary: data };
      },
    },
    {
      name: 'save_summary',
      description: 'Updates an existing summary’s title and/or body.',
      inputSchema: {
        type: 'object',
        properties: {
          id: { type: 'string', description: 'The summary’s id, from list_summaries.' },
          title: { type: 'string', description: 'New title.' },
          body: { type: 'string', description: 'New body content, in markdown.' },
        },
        required: ['id', 'title'],
      },
      execute: async ({ id, title, body }) => {
        const b = bridge();
        if (!b) return { error: 'App not ready.' };
        if (!title?.trim()) return { error: 'Title required.' };
        // Read first so an omitted body keeps the existing content and the slug
        // stays stable -- rows.get, not open(), so the editor is untouched.
        const { data: existing, error: readErr } = await b.rows.get(id);
        if (readErr) return { error: readErr.message };
        if (!existing) return { error: 'Not found, or not signed in.' };
        const { data, error } = await b.rows.update(id, b.stamp(title.trim(), body ?? existing.content, existing.slug));
        if (error) return { error: error.message };
        b.refreshList();
        return { summary: data };
      },
    },

    // ---- requires human confirmation ----
    {
      name: 'delete_summary',
      description: 'Permanently deletes a saved summary. This cannot be undone.',
      requiresConfirmation: true,
      inputSchema: {
        type: 'object',
        properties: { id: { type: 'string', description: 'The summary’s id, from list_summaries.' } },
        required: ['id'],
      },
      execute: async ({ id }) => {
        const b = bridge();
        if (!b) return { error: 'App not ready.' };
        const { error } = await b.rows.remove(id);
        if (error) return { error: error.message };
        b.refreshList();
        return { deleted: id };
      },
    },
  ];

  for (const tool of tools) {
    try {
      mc.registerTool(tool);
    } catch (e) {
      console.warn('webmcp: failed to register', tool.name, e);
    }
  }
}
