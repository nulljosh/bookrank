# Bookrank Money

How Bookrank makes money. The fleet-wide ledger is `GTM.md` in the Code root.

## Price

$0.99 upfront on iOS and Mac, since 2026-10-02.

## Rail

App Store, paid upfront. No in-app purchase.

## Why

We sell the voices, not the summaries. The summaries are Joshua's own notes on books he read. The natural ElevenLabs voices are what costs money to run, so they are what the dollar pays for.

## Cost guard

`/api/speak` stores every line forever, so a line is paid for once. A monthly character budget (25,000) for the whole app and a daily one per account keep the bill at the $5 ElevenLabs plan. Over either cap the player drops to the device voice and never breaks.

## Next

Gate the natural voices on the web behind the Stripe $1 rail, so web matches the apps.

## Change it

`asc pricing schedule create --app 6792376485 --price 0.99 --base-territory USA --start-date YYYY-MM-DD`

Anyone who got Bookrank while it was free keeps it free. Only new customers pay.

*ASC 6792376485. Set 2026-10-02.*
