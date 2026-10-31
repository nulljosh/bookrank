Note: karma/flair requirements unknown, check first. Public post, not beta-only.

Title: Kernel: a book summary reader that works offline and reads aloud, on plain ES modules

Body:
Kernel is plain HTML and ES modules on Cloudflare Pages, no framework. Each chapter summary can be read or heard: lines are voiced one at a time, cached per line on the server and kept in Cache Storage, so a downloaded book plays with no connection.

Two pieces I like: every read goes through one read-through cache keyed by account, so the library opens offline, and saves made offline wait in an outbox and merge when you are back (a listening place reached later on another device wins). Search by meaning embeds each line once per book version and keeps the vectors on the device.

https://kernel.jaybulb.com
