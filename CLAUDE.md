# Working rules for this repo

## CI: every run costs the owner time and money
- **Batch changes. Never push small fixes one after another.** Each push to a PR branch starts a full CI run (3 macOS test shards + Linux). Collect all edits, check them locally (`bash -n`, brace balance, core tests via `swift test --package-path MenaceCore`), then push once.
- **Doc-only or non-code commits get `[skip ci]`** in the commit message.
- **At most one screenshot run at a time.** Before starting a manual (`workflow_dispatch`) run, list running runs and cancel any stale ones first. Never start a new one while another is in progress for the same branch unless the old one is cancelled.
- Manual runs take screenshots only (no tests); PR runs test only. Don't add steps back to either without being asked.
- Don't re-run CI "to check". Read the logs of the run that exists.

## Review with the owner
- Screens are reviewed one at a time with options A (current) / B / C. Collect all picks, then apply them in **one** push at the end.
- Nothing is merged until the owner approves every screen.
