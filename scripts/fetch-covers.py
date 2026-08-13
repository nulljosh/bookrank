#!/usr/bin/env python3
"""Wire a hotlinked cover image into every book <li> in index.html.

Covers are served straight from Open Library's CDN (free, no key, no rate limit on the
image host) — nothing is downloaded into this repo. Only the lookup hits the search API.
Goodreads has no free cover API and blocks bulk scraping, so its slug is used only as an id.

    python3 scripts/fetch-covers.py            # look up missing covers, patch index.html
    python3 scripts/fetch-covers.py --dry-run  # list books with no cover yet
"""
import html as htmlmod
import json, re, sys, time, urllib.error, urllib.parse, urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HTML = ROOT / "index.html"
CACHE = ROOT / "scripts" / "covers.json"  # slug -> cover URL, so re-runs cost no requests
UA = "bookrank.heyitsmejosh.com cover lookup (trommatic@icloud.com)"
# ponytail: one regex per <li>, never across them, or a book inherits its neighbour's cover
ITEM = re.compile(r'<li class="book">.*?</li>', re.S)
SLUG = re.compile(r'goodreads\.com/book/show/([^"?]+)"')
TITLE = re.compile(r'<div class="book-title">(?:<a[^>]*>)?(.*?)(?:</a>)?\s*(?:<a [^>]*class="badge".*?)?</div>', re.S)
AUTHOR = re.compile(r'<div class="author">(.*?)</div>', re.S)


def get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    for wait in (0, 5, 20):  # ponytail: brief backoff, Open Library rarely 429s
        time.sleep(wait)
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                return json.load(r)
        except urllib.error.HTTPError as e:
            if e.code != 429:
                raise
    raise RuntimeError("429 after retries: " + url)


def text(s):
    return htmlmod.unescape(re.sub(r"<[^>]+>", "", s)).strip()


def lookup(title, author):
    author = author.split("&")[0].split("·")[0].strip()
    queries = [{"title": title, "author": author}, {"q": f"{title} {author}"}]
    for params in queries:
        params.update(limit=3, fields="cover_i")
        for doc in get("https://openlibrary.org/search.json?" + urllib.parse.urlencode(params)).get("docs", []):
            if doc.get("cover_i"):
                return f"https://covers.openlibrary.org/b/id/{doc['cover_i']}-M.jpg"
    return None


def main():
    dry = "--dry-run" in sys.argv
    cache = json.loads(CACHE.read_text()) if CACHE.exists() else {}
    html = HTML.read_text()

    for item in ITEM.findall(html):
        slug = SLUG.search(item)
        if not slug or slug.group(1) in cache:
            continue
        slug = slug.group(1)
        t, a = TITLE.search(item), AUTHOR.search(item)
        title, author = text(t.group(1)) if t else "", text(a.group(1)) if a else ""
        if dry:
            print("missing:", title, "—", author)
            continue
        try:
            url = lookup(title, author)
        except Exception as e:
            print("fail:", slug, e); continue
        if not url:
            print("no cover:", title, "—", author)
        else:
            cache[slug] = url
            print("ok:", slug)
        time.sleep(1)  # ponytail: Open Library asks for gentle pacing on bulk reads

    if dry:
        return
    CACHE.write_text(json.dumps(cache, indent=2, sort_keys=True) + "\n")

    def wire(m):
        item = m.group(0)
        slug = SLUG.search(item)
        if not slug or 'class="cover"' in item or slug.group(1) not in cache:
            return item
        img = (f'<img class="cover" src="{cache[slug.group(1)]}" alt="" loading="lazy" '
               f'width="44" height="66" referrerpolicy="no-referrer">')
        return item.replace('<div class="book-info">', img + '<div class="book-info">', 1)

    out = ITEM.sub(wire, html)
    if out != html:
        HTML.write_text(out)
    print("covers wired:", out.count('class="cover"'))


if __name__ == "__main__":
    main()
