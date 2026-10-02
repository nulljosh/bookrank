#!/bin/sh
# Turns on the $1 web voices gate. Run once after making the $1 product, webhook and restricted key in Stripe:
#   sh scripts/wire-stripe.sh
# Prompts for the three values (hidden), stores them as Pages secrets, redeploys. The gate is on once STRIPE_PRICE_ID exists.
set -e
cd "$(dirname "$0")/.."
put() { printf %s "$2" | npx wrangler pages secret put "$1" --project-name bookrank >/dev/null && echo "$1 ok"; }
printf "Price ID (price_...): "; read -r P
printf "Restricted key (rk_live_...): "; stty -echo; read -r K; stty echo; echo
printf "Webhook signing secret (whsec_...): "; stty -echo; read -r W; stty echo; echo
case "$P" in price_*) ;; *) echo "that is not a price id"; exit 1;; esac
case "$K" in rk_live_*|sk_live_*) ;; *) echo "that is not a live key"; exit 1;; esac
case "$W" in whsec_*) ;; *) echo "that is not a webhook secret"; exit 1;; esac
put STRIPE_SECRET_KEY "$K"; put STRIPE_WEBHOOK_SECRET "$W"; put STRIPE_PRICE_ID "$P"
sh scripts/build-site.sh >/dev/null 2>&1
npx wrangler pages deploy dist --project-name bookrank --branch main --commit-dirty=true 2>&1 | tail -1
echo "Gate is on. Natural voices on the web now cost \$1."
