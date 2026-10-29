# Product page test

App Store Connect's product page optimization shows a share of visitors a second set of screenshots and counts who installs. Kernel tests one question at a time, for at least two weeks or until App Store Connect calls it.

The first test: light screenshots (the original, `ios/fastlane/screenshots/en-US`) against dark ones (the treatment, `ios/fastlane/ppo/en-US-dark`, kept out of the locale folders, taken with `fastlane snapshot --dark_mode true`). Half the visitors each, English, iPhone and iPad.

It starts once the version in those screenshots is the one on sale, so nobody installs for a screen the live app does not have. Set it up under App Store Connect > the app > Product Page Optimization > Create Test, add the dark set as the treatment, and submit it with or after that version. Keep whichever wins as the original for the next test.
