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
HTML = ROOT / "rankings.html"
CACHE = ROOT / "scripts" / "covers.json"  # slug -> cover URL, so re-runs cost no requests
UA = "bookrank.heyitsmejosh.com cover lookup (trommatic@icloud.com)"
# ponytail: one regex per <li>, never across them, or a book inherits its neighbour's cover
ITEM = re.compile(r'<li class="book">.*?</li>', re.S)
SLUG = re.compile(r'goodreads\.com/book/show/([^"?]+)"')
TITLE = re.compile(r'<div class="book-title">(.*?)</div>', re.S)
BADGE = re.compile(r'<a [^>]*class="badge".*?</a>', re.S)
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


def fields(item):
    """(cache key, title, author) for one <li class="book">."""
    t, a = TITLE.search(item), AUTHOR.search(item)
    title = text(BADGE.sub("", t.group(1))) if t else ""
    author = text(a.group(1)) if a else ""
    slug = SLUG.search(item)
    # ponytail: no Goodreads link (library/summary rows) -> key off the text instead
    key = slug.group(1) if slug else "t:" + re.sub(r"[^a-z0-9]+", "-", (title + " " + author).lower()).strip("-")
    return key, title, author


def google(title, author):
    """Google Books covers what Open Library doesn't — newer and niche titles mostly."""
    q = urllib.parse.urlencode({"q": f"{title} {author}".strip(), "maxResults": 3})
    for item in get("https://www.googleapis.com/books/v1/volumes?" + q).get("items", []):
        link = item.get("volumeInfo", {}).get("imageLinks", {}).get("thumbnail")
        if link:
            # served over http with page-curl styling by default; neither is wanted
            return link.replace("http://", "https://").replace("&edge=curl", "")
    return None


def lookup(title, author):
    # drop co-authors, barcodes, credentials and "(partial: ch. 1-4)" noise
    author = re.sub(r"\(.*?\)", "", author).split("&")[0].split("·")[0].split(",")[0].strip()
    queries = [{"title": title, "author": author}, {"q": f"{title} {author}"}, {"title": title}]
    for params in queries:
        params.update(limit=3, fields="cover_i")
        for doc in get("https://openlibrary.org/search.json?" + urllib.parse.urlencode(params)).get("docs", []):
            if doc.get("cover_i"):
                return f"https://covers.openlibrary.org/b/id/{doc['cover_i']}-M.jpg"
    try:
        return google(title, author)
    except Exception:
        return None


def main():
    dry = "--dry-run" in sys.argv
    retry = "--retry-misses" in sys.argv
    cache = json.loads(CACHE.read_text()) if CACHE.exists() else {}
    html = HTML.read_text()

    for item in ITEM.findall(html):
        key, title, author = fields(item)
        if not title or (key in cache and not (retry and cache[key] is None)):
            continue
        if dry:
            print("missing:", title, "—", author)
            continue
        try:
            url = lookup(title, author)
        except Exception as e:
            print("fail:", key, e); continue
        if not url:
            cache[key] = None  # remembered miss, so re-runs don't re-query
            print("no cover:", title, "—", author)
        else:
            cache[key] = url
            print("ok:", key)
        time.sleep(1)  # ponytail: Open Library asks for gentle pacing on bulk reads

    if dry:
        return
    CACHE.write_text(json.dumps(cache, indent=2, sort_keys=True) + "\n")

    def wire(m):
        item = m.group(0)
        url = cache.get(fields(item)[0])
        if 'cover-empty' in item and url:
            return re.sub(r'<div class="cover cover-empty"[^>]*></div>',
                          f'<img class="cover" src="{url}" alt="" loading="lazy" '
                          f'width="44" height="66" referrerpolicy="no-referrer">', item, count=1)
        if 'class="cover' in item:  # matches the img and the placeholder both
            return item
        # a miss still gets a blank slot, so every row lines up on the same text column
        img = (f'<img class="cover" src="{url}" alt="" loading="lazy" '
               f'width="44" height="66" referrerpolicy="no-referrer">') if url else \
              '<div class="cover cover-empty" aria-hidden="true"></div>'
        return item.replace('<div class="book-info">', img + '<div class="book-info">', 1)

    out = ITEM.sub(wire, html)
    if out != html:
        HTML.write_text(out)
    print("covers wired:", out.count('class="cover"'))


if __name__ == "__main__":
    main()
