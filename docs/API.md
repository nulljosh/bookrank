# API

Bookrank has no HTTP API of its own. `library.html` — the only real app in this
repo — talks to Supabase directly from the browser, reading and writing the
`bookrank_summaries` table with the anon/publishable key. There is no server,
no serverless function, and nothing to call from outside the page.

`index.html` and `rankings.html` are static content. `index.html` is a
marketing hero with no user actions. `rankings.html`'s rankings are hardcoded
HTML — there is no way for a user or an agent to actually rank or rate a book
on this site. Neither page carries WebMCP tools, and neither should: a tool
that implied you could rank a book, or take any action on those pages, would
be lying about what the app does.

## WebMCP

`webmcp.js`, loaded from `library.html` only, registers tools against
`window.modelContext` when a WebMCP-capable browser is present. Every tool
calls straight through to the existing functions in `library.html`'s module
script (exposed as `window.__bookrank`) — the same Supabase client, the same
queries, no reimplementation.

### Read-only

| Tool | Description |
|---|---|
| `list_summaries` | Lists the signed-in user's saved summaries (id, title, last updated). |
| `get_summary` | Fetches the full text of one saved summary by id. |
| `whoami` | Returns the signed-in user's email, or signed-out state. |

### Reversible writes

| Tool | Description |
|---|---|
| `create_summary` | Creates a new summary with a title and markdown body. |
| `save_summary` | Updates an existing summary's title and/or body. |

### Requires human confirmation

| Tool | Description |
|---|---|
| `delete_summary` | Permanently deletes a saved summary. This cannot be undone. |

Sign-in, sign-up, password reset, OAuth, and sign-out are intentionally **not**
exposed as tools — an agent should never drive someone's auth flow, and
credentials must never pass through a tool call.

## Why tools use the data layer, not the UI

`webmcp.js` calls `window.__bookrank.rows.*` — the query layer — never the
editor functions `open()` or `saveCurrent()`. Routing tools through the UI would
let a tool call reset the editor's `current` record or overwrite the open
textareas, so a user editing a summary when an agent created another one would
silently insert a duplicate on their next Save. Tools read and write by id and
leave the editor alone; `refreshList()` re-renders the list only when the user
is actually looking at it.
