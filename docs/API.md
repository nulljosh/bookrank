# API

Kernel has four surfaces an agent or a script can use.

## Your summaries, in the browser (WebMCP)

`webmcp.js` registers these tools on `library.html` when the browser supports WebMCP. They call the page's own data layer (`window.__kernel.rows`), never the editor, so an agent cannot overwrite what you are typing.

| Tool | What it does |
|---|---|
| `list_summaries` | Your summaries: id, title, last updated |
| `get_summary` | One summary's full text |
| `whoami` | Your email, or signed out |
| `create_summary` | A new summary from a title and markdown |
| `save_summary` | Change a summary's title or text |
| `delete_summary` | Delete one for good. Asks you first |

Sign-in is never a tool. Credentials do not pass through an agent.

## The public book list (/api and /mcp)

Read-only, no account, over `books.json`. Both routes call `callTool()` in `src/lib/tools.js`, so they cannot disagree.

| REST | MCP tool | Returns |
|---|---|---|
| `GET /api` | | The endpoint list |
| `GET /api/sections` | `list_sections` | Each section with its count |
| `GET /api/books?section=&limit=&offset=` | `list_books` | Books, paginated, with a total |
| `GET /api/search?q=&limit=&section=` | `search_books` | Books whose title, author or notes match |
| `GET /api/book?title=` | `get_book` | One book; an exact title wins |

MCP is `POST /mcp`, JSON-RPC, stateless.

## Your summaries (/api/summaries and /mcp)

Send your Kernel sign-in token as `Authorization: Bearer <token>`. Calls go straight through to jaybulb-api, which only ever shows and changes your own rows; nothing is kept on the way.

| REST | MCP tool | Does |
|---|---|---|
| `GET /api/summaries` | `my_summaries` | Your summaries: id, title, last edited |
| `GET /api/summaries/:id` | `read_summary` | One in full, as Markdown |
| `POST /api/summaries` | `create_summary` | A new one from `{ title, markdown }` (`## ` per chapter) |
| `PATCH /api/summaries/:id` | `update_summary` | Change its `title` or `markdown` |

## The app's own endpoints

These back the apps and the web. Most need a signed-in account; the voices also take a share token.

| Endpoint | In | Out |
|---|---|---|
| `POST /api/narrate` | `{ text, title, ch, total, token? }` | `{ script: [{ host, line }] }` |
| `POST /api/speak` | `{ text, host, ch?, token? }` | `{ audio, words }`, or 402 or 429 and the device voice takes over |
| `POST /api/ask` | `{ text, title, question }` | `{ answer }` |
| `POST /api/summarize-photo` | one image, multipart | `{ text }` |
| `GET /api/goodreads?user=&shelf=` | a profile | the public Currently Reading box |
| `GET /api/usage` | | voice used today and this month, and the caps |
| `GET`/`POST /api/pay` | | whether you paid; the $1 Stripe link |

Summaries themselves live on jaybulb-api (`/rest/bookrank_summaries`), behind your account.
