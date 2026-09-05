#!/usr/bin/env python3
"""Upload summaries/*.md into the owner's private Supabase rows (bookrank_summaries).

Interactive (any account, RLS-scoped):
    python3 scripts/import-summaries.py you@example.com          # prompts for password

Headless (owner account, via the Management API PAT in the macOS Keychain "Supabase CLI"):
    python3 scripts/import-summaries.py --pat [slug ...]         # all summaries/*.md, or just the named slugs

Upserts on (user_id, slug). A row is never replaced by content under SHRINK_PCT (default 80)
percent of what is already stored; FORCE=1 overrides. Same guard as sync-summaries.sh.
"""
import getpass, json, os, pathlib, secrets, subprocess, sys, urllib.request

URL = "https://tjsxsqlxjmanwvmywwvw.supabase.co"
KEY = "sb_publishable_3a5WLExQ3oF_kPV3KRCjdg_iEOiHO90"
REF = "tjsxsqlxjmanwvmywwvw"
OWNER = "trommatic@icloud.com"
ROOT = pathlib.Path(__file__).resolve().parent.parent
SHRINK = int(os.environ.get("SHRINK_PCT", "80"))
FORCE = os.environ.get("FORCE") == "1"


def rows(slugs=()):
    files = sorted((ROOT / "summaries").glob("*.md"))
    if slugs:
        files = [f for f in files if f.stem in slugs]
    return [{"slug": f.stem, "title": f.stem.replace("-", " ").title(), "content": f.read_text()} for f in files]


def post(path, body, token=None, method="POST"):
    req = urllib.request.Request(
        URL + path, json.dumps(body).encode(), method=method,
        headers={"apikey": KEY, "Content-Type": "application/json",
                 "Authorization": f"Bearer {token or KEY}", "Prefer": "resolution=merge-duplicates"})
    with urllib.request.urlopen(req) as r:
        return r.read()


def sql(pat, query):
    # ponytail: curl not urllib, the Management API 403s urllib's requests.
    out = subprocess.run(
        ["curl", "-sS", "-X", "POST", f"https://api.supabase.com/v1/projects/{REF}/database/query",
         "-H", f"Authorization: Bearer {pat}", "-H", "Content-Type: application/json",
         "-d", json.dumps({"query": query})], capture_output=True, text=True, check=True).stdout
    data = json.loads(out)
    if isinstance(data, dict) and "message" in data:
        raise SystemExit(f"SQL error: {data['message']}")
    return data


def quote(s):
    tag = "q" + secrets.token_hex(4)
    while f"${tag}$" in s:
        tag = "q" + secrets.token_hex(4)
    return f"${tag}${s}${tag}$"


def upload_pat(slugs):
    pat = subprocess.run(["security", "find-generic-password", "-s", "Supabase CLI", "-w"],
                         capture_output=True, text=True, check=True).stdout.strip()
    guard = "true" if FORCE else f"length(excluded.content) * 100 >= length(bookrank_summaries.content) * {SHRINK}"
    for r in rows(slugs):
        res = sql(pat, f"""
            insert into bookrank_summaries (user_id, slug, title, content)
            select id, {quote(r['slug'])}, {quote(r['title'])}, {quote(r['content'])}
              from auth.users where email = {quote(OWNER)}
            on conflict (user_id, slug) do update
              set title = excluded.title, content = excluded.content, updated_at = now()
              where {guard}
            returning slug, length(content) as bytes""")
        print(f"{'upserted' if res else 'SKIP (shrink guard, FORCE=1 to override)'}: {r['slug']} {len(r['content'])}b")


def upload_password(email):
    token = json.loads(post("/auth/v1/token?grant_type=password",
                            {"email": email, "password": getpass.getpass("password: ")}))["access_token"]
    rs = rows()
    post("/rest/v1/bookrank_summaries?on_conflict=user_id,slug", rs, token)
    print(f"uploaded {len(rs)} summaries")


if __name__ == "__main__":
    args = sys.argv[1:]
    if args and args[0] == "--pat":
        upload_pat(set(args[1:]))
    else:
        upload_password(args[0] if args else input("email: "))
