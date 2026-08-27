// WebMCP tool registration for the library page (bookrank's only real app).
// Tools call straight through to window.__bookrank, the bridge library.html's
// own module script exposes — same Supabase client, same bookrank_summaries
// queries the UI already runs. Nothing here talks to Supabase directly.
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
        try {
          const data = await b.load();
          return { summaries: data ?? [] };
        } catch (e) {
          return { error: String(e) };
        }
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
        try {
          const data = await b.open(id);
          return data ? { summary: data } : { error: 'Not found, or not signed in.' };
        } catch (e) {
          return { error: String(e) };
        }
      },
    },
    {
      name: 'whoami',
      description: 'Returns the currently signed-in user’s email, or signed-out if nobody is authenticated.',
      inputSchema: { type: 'object', properties: {} },
      execute: async () => {
        const b = bridge();
        if (!b) return { error: 'App not ready.' };
        try {
          const user = await b.whoami();
          return user ? { email: user.email } : { signedIn: false };
        } catch (e) {
          return { error: String(e) };
        }
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
        try {
          b.newDraft();
          const { data, error } = await b.saveCurrent(title, body ?? '');
          if (error) return { error: error.message };
          return { summary: data };
        } catch (e) {
          return { error: String(e) };
        }
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
        try {
          const existing = await b.open(id);
          if (!existing) return { error: 'Not found, or not signed in.' };
          const { data, error } = await b.saveCurrent(title, body ?? existing.content);
          if (error) return { error: error.message };
          return { summary: data };
        } catch (e) {
          return { error: String(e) };
        }
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
        try {
          const { error } = await b.deleteRow(id);
          if (error) return { error: error.message };
          return { deleted: id };
        } catch (e) {
          return { error: String(e) };
        }
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
