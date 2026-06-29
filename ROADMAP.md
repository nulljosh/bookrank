# Books Roadmap

## Pending: iCloud summarize pipeline

**Newton** (chapters 2–4 raw HEICs pending)
- bg job running as of 2026-06-27 night — check `Newton/` for summary.md files
- If ch2/ch3/ch4 succeeded: run `sync-summaries.sh`, add badge in `index.html`
- `summarize.sh` fix landed: `env -u CLAUDE_CODE_SESSION_ID ...` prevents context contamination

**Machine Learning for Dummies** (ch4–6 raw HEICs + orphaned JPGs pending)
- Run `./summarize.sh "Machine learning for dummies "` (trailing space in folder name)
- Then sync + badge

**Agentic AI for Dummies**
- ch2–15 all done, PDF merged — nothing pending

**AI Investing for Dummies**
- ch1–3 done, PDF merged — nothing pending

## After summaries are done
1. `cd ~/Documents/Code/books && ./sync-summaries.sh`
2. Add `<a href="summary.html?b=<slug>" class="badge">Summary</a>` in `index.html` for each new book (see Agentic AI entry for pattern)
3. Update `book_rankings.md` in parallel (both files must stay in sync)
4. Commit + push

## Known issues fixed
- `summarize.sh`: subprocess was inheriting `CLAUDE_CODE_SESSION_ID` and hallucinating. Fixed with `env -u` to strip session vars before calling `claude -p`.
- PC for Dummies ch1–7: photos permanently lost (bad summary passed validation, originals deleted). Needs re-photographing.
- Agentic AI ch12: photos permanently lost same way. Summary was later recovered manually.
