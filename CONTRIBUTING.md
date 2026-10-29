# Contributing

```
git clone https://github.com/nulljosh/kernel.git && cd kernel
node --test                                   # web and server tests
sh scripts/build-site.sh && npx wrangler pages dev dist   # the site
cd ios && xcodegen && open Kernel.xcodeproj   # the apps
```

Keep a change to what it fixes and match the file you touch. Open a PR that says why. Found a bug? Open an issue with the smallest steps that show it. Security problems go to the address in [SECURITY.md](SECURITY.md).
