// POST { text, title } -> { script: [{ host: "A"|"B", line }] }
// Turns a chapter summary into a two-host conversation (the NotebookLM audio-overview
// shape): the hosts explain the ideas, why they matter, and how they connect, instead
// of the page reading its own markdown aloud. Text only; the browser does the voices.
// Signed-in accounts only, same gate as summarize-photo.
const MODEL = "@cf/meta/llama-3.3-70b-instruct-fp8-fast";
const SUPABASE_URL = "https://tjsxsqlxjmanwvmywwvw.supabase.co";
const SUPABASE_ANON = "sb_publishable_3a5WLExQ3oF_kPV3KRCjdg_iEOiHO90";
const MAX_CHARS = 24000; // ponytail: ~6k tokens fits the context; longer books are truncated, chunk+merge if it matters

export async function onRequest({ request, env }) {
  if (request.method !== "POST") return json({ error: "POST only" }, 405);
  if (!(await isSignedIn(request.headers.get("authorization") || ""))) return json({ error: "Sign in required." }, 401);

  const body = await request.json().catch(() => ({}));
  const text = String(body.text || "").trim().slice(0, MAX_CHARS);
  const title = String(body.title || "this book").slice(0, 200);
  if (!text) return json({ error: "Nothing to narrate." }, 400);

  let out;
  try {
    out = await env.AI.run(MODEL, {
      messages: [
        { role: "system", content:
          "You write the script for a short two-host audio conversation about a book, like a podcast overview. " +
          "Host A is the guide who knows the material; Host B is curious and asks the questions a smart reader would. " +
          "Do not read the notes back. Explain the main ideas in plain spoken English, say why each one matters, " +
          "give a concrete example or analogy where it helps, connect ideas to each other, and end with the one thing " +
          "to remember. Skip trivia, page details, and filler. 12 to 20 exchanges, each 1 to 3 sentences. " +
          "Output ONLY lines in the form `A: ...` or `B: ...`, one exchange per line, no headings or markdown." },
        { role: "user", content: `Book: ${title}\n\nNotes:\n${text}` },
      ],
      max_tokens: 1500,
    });
  } catch {
    return json({ error: "Could not build the conversation." }, 502);
  }

  const script = parseScript(out?.response || "");
  if (!script.length) return json({ error: "Could not build the conversation." }, 502);
  return json({ script });
}

export function parseScript(raw) {
  return raw.split("\n")
    .map(l => l.trim().match(/^\**([AB])\**\s*[:：]\s*\**(.+?)\**$/))
    .filter(Boolean)
    .map(m => ({ host: m[1], line: m[2].trim() }));
}

async function isSignedIn(authHeader) {
  if (!authHeader.startsWith("Bearer ")) return false;
  const res = await fetch(`${SUPABASE_URL}/auth/v1/user`, { headers: { authorization: authHeader, apikey: SUPABASE_ANON } });
  return res.ok;
}

function json(obj, status = 200) {
  return new Response(JSON.stringify(obj), { status, headers: { "content-type": "application/json" } });
}
