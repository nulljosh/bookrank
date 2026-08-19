#!/usr/bin/env python3
"""One-time: upload summaries/*.md into your private Supabase rows, then delete them from the repo.

    python3 scripts/import-summaries.py you@example.com
Prompts for your Bookrank password (the account you created on library.html).
"""
import getpass, json, pathlib, sys, urllib.request

URL = "https://tjsxsqlxjmanwvmywwvw.supabase.co"
KEY = "sb_publishable_3a5WLExQ3oF_kPV3KRCjdg_iEOiHO90"
ROOT = pathlib.Path(__file__).resolve().parent.parent


def post(path, body, token=None, method="POST"):
    req = urllib.request.Request(
        URL + path, json.dumps(body).encode(), method=method,
        headers={"apikey": KEY, "Content-Type": "application/json",
                 "Authorization": f"Bearer {token or KEY}", "Prefer": "resolution=merge-duplicates"})
    with urllib.request.urlopen(req) as r:
        return r.read()


def main():
    email = sys.argv[1] if len(sys.argv) > 1 else input("email: ")
    token = json.loads(post("/auth/v1/token?grant_type=password",
                            {"email": email, "password": getpass.getpass("password: ")}))["access_token"]
    rows = [{"slug": f.stem,
             "title": f.stem.replace("-", " ").title(),
             "content": f.read_text()}
            for f in sorted((ROOT / "summaries").glob("*.md"))]
    post("/rest/v1/bookrank_summaries?on_conflict=user_id,slug", rows, token)
    print(f"uploaded {len(rows)} summaries")


if __name__ == "__main__":
    main()
