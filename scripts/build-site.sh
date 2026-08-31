#!/bin/sh
# ponytail: the site is the repo root, but the repo also holds ios/, metadata/, content/
# and screenshots/. Copy the web subset into dist/ so a Pages deploy ships the site and
# nothing else. functions/ stays at the root — wrangler picks it up from there, not dist/.
set -e
cd "$(dirname "$0")/.."
rm -rf dist && mkdir -p dist
cp index.html rankings.html library.html privacy.html tokens.css webmcp.js sw.js \
   manifest.webmanifest books.json icon.svg icon-192.png icon-512.png \
   icon-512-maskable.png architecture.svg dist/
cp -R fonts dist/
echo "built dist/"
