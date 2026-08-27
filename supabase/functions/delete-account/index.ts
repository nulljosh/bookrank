import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

// Shared account-deletion endpoint for all apps on the spark Supabase project.
// Caller must send their own session JWT in the Authorization header.
// Deletes the authenticated user via the service-role admin API.
//
// Native callers (lexly, healstack, litigate, bookrank) hit this with a plain
// URLRequest and do not care about CORS. Browsers do: supabase-js
// functions.invoke() sends a preflighted POST, so the OPTIONS branch and the
// response headers below are what let bookrank's library.html call this at all.
const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: cors });
  }
  if (req.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return json({ error: "Missing Authorization header" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // Client scoped to the caller's own JWT, just to resolve who they are.
  const callerClient = createClient(supabaseUrl, serviceRoleKey, {
    global: { headers: { Authorization: authHeader } },
  });

  const { data: userData, error: userError } = await callerClient.auth.getUser();
  if (userError || !userData?.user) {
    return json({ error: "Invalid session" }, 401);
  }

  // bookrank_summaries.user_id is ON DELETE CASCADE, so the user's summaries
  // go with them. Nothing else to clean up.
  const admin = createClient(supabaseUrl, serviceRoleKey);
  const { error: deleteError } = await admin.auth.admin.deleteUser(userData.user.id);
  if (deleteError) {
    return json({ error: deleteError.message }, 500);
  }

  return json({ ok: true });
});
