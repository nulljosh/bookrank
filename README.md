<img src="icon.svg" width="80">

![version](https://img.shields.io/github/v/release/nulljosh/kernel?label=version) ![license](https://img.shields.io/badge/license-Apache%202.0-blue) [![App Store](https://img.shields.io/badge/App%20Store-iPhone%2C%20iPad%2C%20Mac-0D96F6?logo=apple&logoColor=white)](https://apps.apple.com/us/app/kernel/id6792376485)

**Kernel.** You finish a book. A month later you remember one idea. Kernel keeps the rest: every chapter in plain words, read it or listen to it.

[![Kernel, 32 seconds. Click to play.](ad/ad-poster.jpg)](https://github.com/nulljosh/kernel/releases/download/v1.0.2/kernel-ad.mp4)

Free on the [web](https://bookrank.jaybulb.com), $0.99 on iPhone, iPad and Mac. Formerly Bookrank.

- **Chapters.** Open a book, pick a chapter, read it.
- **Listen.** One narrator explains the chapter while the words light up.
- **Highlights and questions.** Save a line, or ask the chapter something.
- **Goodreads.** Your shelves show up next to your summaries.
- **Offline.** Your books stay on the device, and the apps can download the audio too.

## Run it

```
node --test              # tests
sh scripts/build-site.sh # builds dist/, then wrangler pages deploy dist
```

The apps come from `ios/project.yml` with xcodegen.

[Changelog](docs/CHANGELOG.md) · [Roadmap](roadmap.md) · [Architecture](docs/ARCHITECTURE.md) · [API](docs/API.md) · [Shipping](docs/SHIPPING.md) · [Whitepaper](WHITEPAPER.md)
