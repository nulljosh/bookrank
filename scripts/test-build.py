#!/usr/bin/env python3
"""Checks on the books.json -> everything generator.

Pins the regression that motivated it: scripts/export-books.py required a
`**Rating:**` line and silently dropped every book without one, so the shipping
app carried 71 of 111 ranked books. An unrated book must survive the round trip.
"""
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "scripts"))
import importlib

build = importlib.import_module("build")

books = build.load()
ranked = build.by(books, "ranked")

# 1. Nothing is dropped: every ### entry in the markdown is a ranked entry.
md_headings = len(re.findall(r"^### \d+\. ", (ROOT / "book_rankings.md").read_text(), re.M))
assert len(ranked) == md_headings, f"{len(ranked)} ranked vs {md_headings} md headings"

# 2. The actual regression: unrated books exist and are still exported.
unrated = [b for b in ranked if b.get("rating") is None]
assert unrated, "expected unrated books; if this fires the fixture changed, not the bug"
ios = json.loads((ROOT / "ios/Bookrank/Resources/books.json").read_text())
assert len(ios) == len(ranked), f"iOS ships {len(ios)} of {len(ranked)} ranked books"
titles = {b["title"] for b in ios}
for b in unrated:
    assert b["title"] in titles, f"unrated book dropped from the app: {b['title']}"

# 3. Ranks are unique and contiguous from 1.
seen = sorted(b["rank"] for b in ranked)
assert seen == list(range(1, len(ranked) + 1)), "ranks are not 1..N without gaps"

# 4. Every entry the app decodes has the non-optional fields Book.swift demands.
for b in ios:
    for field in ("rank", "title", "goodreadsURL", "author", "notes"):
        assert b.get(field) not in (None, ""), f"{b.get('title')!r} missing {field}"
    assert isinstance(b["badges"], list)

# 5. The generator is idempotent — running it twice changes nothing.
before = (ROOT / "rankings.html").read_bytes()
subprocess.run([sys.executable, str(ROOT / "scripts/build.py")], check=True,
               capture_output=True)
assert (ROOT / "rankings.html").read_bytes() == before, "build.py is not idempotent"

print(f"ok: {len(ranked)} ranked ({len(unrated)} unrated) all reach the app; "
      f"{len(books)} entries total")
