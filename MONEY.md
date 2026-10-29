# Kernel Money

How Kernel makes money. The fleet ledger is `GTM.md` in the Code root.

**Price.** $0.99 upfront on iPhone, iPad and Mac since 2026-10-02, no in-app purchase. The web is free to read; natural voices there are a one-time $1 Stripe Payment Link.

**Why.** We sell the voices, not the summaries. The summaries are your own; the natural voices are what costs money to run.

**How it is checked.** New app builds send StoreKit's AppTransaction as `X-Kernel-Receipt`, checked in `functions/api/apple.js`. Builds up to 1.2.1 send `X-Bookrank-App` and still work. On the web the Stripe webhook writes `paid:<user>` to KV. A 100% promo code unlocks too, so it works as a free pass for a friend.

**Cost guard.** `/api/speak` stores every line forever, so a line is paid for once. A monthly budget for the app and a daily one per account keep ElevenLabs on its $5 plan. Past those the line goes to Cloudflare's Aura-2 with its own caps, and past those to the device voice. Playback never breaks.

**Change the price.** `asc pricing schedule create --app 6792376485 --price 0.99 --base-territory USA --start-date YYYY-MM-DD`. Anyone who got it free keeps it.
