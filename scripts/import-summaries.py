#!/usr/bin/env python3
"""Upload summaries/*.md into the owner's private rows (bookrank_summaries) on spark-api.

Interactive (any account, scoped to that account):
    python3 scripts/import-summaries.py you@example.com          # prompts for password

Headless (owner account, via the service key in the macOS Keychain item "spark-api-service-key"):
    python3 scripts/import-summaries.py --service [slug ...]     # all summaries/*.md, or just the named slugs

Upserts on (user_id, slug). A row is never replaced by content under SHRINK_PCT (default 80)
percent of what is already stored; FORCE=1 overrides. Same guard as sync-summaries.sh.
"""
import getpass, json, os, pathlib, subprocess, sys, urllib.parse, urllib.request

API = os.environ.get("SPARK_API", "https://api.heyitsmejosh.com")
OWNER_ID = "7453f262-f3d7-41f6-a765-b83ad561b9e3"
ROOT = pathlib.Path(__file__).resolve().parent.parent
SUMMARIES = pathlib.Path(os.environ.get("SUMMARIES_DIR", ROOT / "summaries"))
SHRINK = int(os.environ.get("SHRINK_PCT", "80"))
FORCE = os.environ.get("FORCE") == "1"


def rows(slugs=()):
    files = sorted(SUMMARIES.glob("*.md"))
    if slugs:
        files = [f for f in files if f.stem in slugs]
    return [{"slug": f.stem, "title": f.stem.replace("-", " ").title(), "content": f.read_text()} for f in files]


def call(method, path, headers, body=None):
    # the User-Agent matters: Cloudflare rejects urllib's default one
    req = urllib.request.Request(API + path, json.dumps(body).encode() if body is not None else None, method=method,
                                 headers={"User-Agent": "bookrank-import/1.0", "Content-Type": "application/json", **headers})
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read() or "null")


def upload(headers, user_id, slugs):
    for r in rows(slugs):
        q = urllib.parse.urlencode({"slug": f"eq.{r['slug']}", "user_id": f"eq.{user_id}", "select": "id,content"})
        have = call("GET", f"/rest/bookrank_summaries?{q}", headers)
        if have:
            old = len(have[0]["content"])
            if not FORCE and old and len(r["content"]) * 100 < old * SHRINK:
                print(f"SKIP (shrink guard, FORCE=1 to override): {r['slug']} {len(r['content'])}b < {SHRINK}% of {old}b")
                continue
            call("PATCH", f"/rest/bookrank_summaries?id=eq.{have[0]['id']}", headers, {"title": r["title"], "content": r["content"]})
        else:
            call("POST", "/rest/bookrank_summaries", headers, {"user_id": user_id, "slug": r["slug"], "title": r["title"], "content": r["content"]})
        print(f"upserted: {r['slug']} {len(r['content'])}b")


if __name__ == "__main__":
    args = sys.argv[1:]
    if args and args[0] == "--service":
        key = subprocess.run(["security", "find-generic-password", "-s", "spark-api-service-key", "-w"],
                             capture_output=True, text=True, check=True).stdout.strip()
        upload({"x-service-key": key}, OWNER_ID, set(args[1:]))
    else:
        email = args[0] if args else input("email: ")
        s = call("POST", "/auth/token?grant_type=password", {}, {"email": email, "password": getpass.getpass("password: ")})
        upload({"Authorization": f"Bearer {s['access_token']}"}, s["user"]["id"], set())
