#!/bin/sh
# ponytail: the site is the repo root, but the repo also holds ios/, metadata/, content/
# and screenshots/. Copy the web subset into dist/ so a Pages deploy ships the site and
# nothing else. functions/ stays at the root — wrangler picks it up from there, not dist/.
set -e
cd "$(dirname "$0")/.."
rm -rf dist && mkdir -p dist
cp index.html spark.js _redirects library.html share.html profile.html listen.js covers.js privacy.html tokens.css webmcp.js sw.js onboarding.js \
   manifest.webmanifest books.json icon.svg icon-192.png icon-512.png \
   icon-512-maskable.png architecture.svg ad.mp4 ad-poster.jpg og.png favicon.svg favicon-32.png apple-touch-icon.png dist/
cp -R fonts brand dist/
cp ios/Kernel/Resources/summaries/sample.md dist/sample.md
mkdir -p dist/scripts && cp scripts/covers.json dist/scripts/
echo "built dist/"
