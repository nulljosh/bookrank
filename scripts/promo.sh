#!/bin/sh
# Sets the promotional text on every App Store version that is live or editable, from docs/store/listing.json,
# for each language the version already has. Promotional text changes without a review, so run it each release.
#   sh scripts/promo.sh
set -e
cd "$(dirname "$0")/.."
APP=6792376485
export ASC_BYPASS_KEYCHAIN=1
# Newest first: per platform, the live version and any editable one above it; older live versions are history.
pick='
import json, sys
seen, out = set(), []
for x in json.load(sys.stdin)["data"]:
    a = x["attributes"]; state, plat = a.get("appStoreState") or "", a["platform"]
    if state in ("PREPARE_FOR_SUBMISSION", "DEVELOPER_REJECTED"): out.append(x["id"])
    elif state == "READY_FOR_SALE" and plat not in seen: seen.add(plat); out.append(x["id"])
print(" ".join(out))'
for v in $(asc versions list --app $APP --output json | python3 -c "$pick"); do
  asc localizations list --version "$v" --output json | python3 -c "import json,sys; [print(x['id'], x['attributes']['locale']) for x in json.load(sys.stdin)['data']]" | while read id locale; do
    text=$(python3 -c "import json,sys; d=json.load(open('docs/store/listing.json')); print(d.get('$locale', {}).get('promotionalText', ''))")
    [ -n "$text" ] && asc localizations update --id "$id" --promotional-text "$text" >/dev/null && echo "$v $locale ok"
  done
done
