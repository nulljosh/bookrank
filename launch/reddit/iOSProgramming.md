Note: check karma/flair requirements first, unknown. Use "Show and Tell" flair. Public post, not beta-only.

Title: Bookrank, a ranked book shelf with a shared SwiftUI target for iOS, Mac and Apple Watch

Body:
I wanted one shelf of books to read next, ranked instead of just listed, with private chapter notes on the ones I already finished. The web version came first, then I built native apps on top of it.

ios/Bookrank is SwiftUI with a shared BookrankMac target, same shelf and account and private summaries as the web. The Apple Watch app is a separate standalone SwiftUI target built with WKWatchOnly. It's a full local port rather than a network client, the ranked shelf and to-read list are the same JSON bundled into the iOS app and copied into watch resources, so it works with no pairing step and nothing goes stale offline. Per-account chapter summaries stay iOS and Mac only since that needs a sign-in flow that doesn't belong on a watch face.

Free on the App Store. Curious what other people did for watch-app data sharing without a live connection.

https://apps.apple.com/app/id6792376485
