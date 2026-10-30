#!/bin/sh
# Puts docs/store/listing.json on an editable App Store version, every language in it.
#   sh scripts/store-listing.sh <VERSION_ID>
# Run it once a new version is created and before it is submitted; a version in review is locked.
# The subtitle lives on the app info, not the version: set it with the apple-metadata skill.
set -e
cd "$(dirname "$0")/.."
V=${1:?version id}
for l in $(python3 -c "import json; print(' '.join(json.load(open('docs/store/listing.json'))))"); do
  f() { python3 -c "import json,sys; print(json.load(open('docs/store/listing.json'))['$l']['$1'])"; }
  ASC_BYPASS_KEYCHAIN=1 asc localizations create --version "$V" --locale "$l" --if-exists update \
    --description "$(f description)" --keywords "$(f keywords)" --promotional-text "$(f promotionalText)" \
    --support-url https://kernel.jaybulb.com --marketing-url https://kernel.jaybulb.com >/dev/null && echo "$l ok"
done
