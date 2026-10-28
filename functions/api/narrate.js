// POST { text, title, ch, total, token? } -> { script: [{ host: "A", line }] }
// `ch`/`total` (0-based index, chapter count) shape the prompt: only chapter 0 opens the
// conversation and only the last one closes it, so a whole book does not re-introduce
// itself every chapter. `token` is a share link: it stands in for sign-in and the result is
// cached on the shared row so the next listener does not pay for the model again.
// Turns a chapter summary into one narrator explaining it: the ideas, why they matter and
// how they connect, instead of the page reading its own markdown aloud. Every line is host
// "A" (the field stays so old clients and cached rows keep parsing). Text only; the browser does the voices.
// Signed-in accounts only, same gate as summarize-photo.
const MODEL = "@cf/meta/llama-3.3-70b-instruct-fp8-fast";
const API = "https://api.jaybulb.com";
const MAX_CHARS = 24000; // ponytail: ~6k tokens fits the context; longer books are truncated, chunk+merge if it matters

export async function onRequest({ request, env }) {
  if (request.method !== "POST") return json({ error: "POST only" }, 405);
  const body = await request.json().catch(() => ({}));
  const token = typeof body.token === "string" && body.token.length > 8 ? body.token : "";
  const ok = token ? await isShared(token) : await isSignedIn(request.headers.get("authorization") || "", request.headers.get("apikey"));
  if (!ok) return json({ error: "Sign in required." }, 401);
  const text = String(body.text || "").trim().slice(0, MAX_CHARS);
  const title = String(body.title || "this book").slice(0, 200);
  if (!text) return json({ error: "Nothing to narrate." }, 400);

  let out;
  try {
    out = await env.AI.run(MODEL, { messages: messages(title, text, +body.ch || 0, +body.total || 1), max_tokens: 1500 });
  } catch {
    return json({ error: "Could not build the conversation." }, 502);
  }

  const script = parseScript(out?.response || "");
  if (!script.length) return json({ error: "Could not build the conversation." }, 502);
  if (token) await rpc("cache_shared_script", { t: token, ch: String(+body.ch || 0), script }).catch(() => {});
  return json({ script });
}

export function messages(title, text, ch, total) {
  const place = total > 1
    ? (ch === 0 ? `This is chapter 1 of ${total}: open by introducing the book in a sentence or two. Do not close the book.`
      : ch === total - 1 ? `This is the last chapter (${ch + 1} of ${total}): no greeting or re-introduction of the book, and close the whole book with the one thing to remember.`
      : `This is chapter ${ch + 1} of ${total} of one continuous narration: no greeting, no "welcome back", no re-introduction of the book. Pick up as if the previous chapter just ended, and do not wrap up the book.`)
    : "Open briefly and end with the one thing to remember.";
  return [
    { role: "system", content:
      "You are one narrator explaining a book chapter out loud to one listener, like a good teacher. " +
      "No second speaker, no questions to a co-host, no dialogue. " +
      "Do not read the notes back. Explain the main ideas in plain spoken English, say why each one matters, " +
      "give a concrete example or analogy where it helps, and connect ideas to each other. " +
      "Skip trivia, page details, and filler. 10 to 16 lines, each 1 to 3 sentences. " + place + " " +
      "Output ONLY lines in the form `A: ...`, one per line, no headings or markdown." },
    { role: "user", content: `Book: ${title}\n\nNotes:\n${text}` },
  ];
}

export function parseScript(raw) {
  return raw.split("\n")
    .map(l => l.trim().match(/^\**([AB])\**\s*[:：]\s*\**(.+?)\**$/))
    .filter(Boolean)
    .map(m => ({ host: "A", line: m[2].trim() }));
}

// The installed iOS and Mac apps still sign in through Supabase. They send their project key as
// `apikey`, and a token spark-api does not know is checked there. Drop that once the apps move over.
export async function isSignedIn(authHeader, apikey = null) {
  if (!authHeader.startsWith("Bearer ")) return false;
  const res = await fetch(`${API}/auth/user`, { headers: { authorization: authHeader } });
  if (res.ok || !apikey) return res.ok;
  const sb = await fetch("https://tjsxsqlxjmanwvmywwvw.supabase.co/auth/v1/user", { headers: { authorization: authHeader, apikey } });
  return sb.ok;
}

export async function isShared(token) {
  const rows = await rpc("shared_summary", { t: token }).catch(() => []);
  return Array.isArray(rows) && rows.length > 0;
}
async function rpc(fn, args) {
  const res = await fetch(`${API}/rpc/${fn}`, {
    method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(args),
  });
  if (!res.ok) throw new Error(fn);
  return res.status === 204 ? null : res.json();
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), { status, headers: { "content-type": "application/json" } });
}
