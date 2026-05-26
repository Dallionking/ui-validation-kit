# Demo

Self-contained demo of the UI Validation Kit. Runs the kit against a tiny static-HTML app to show what a real validation session looks like.

## Files

| Path | Purpose |
|---|---|
| `sample-app/index.html` | Tiny static SPA with home/dashboard/settings + a modal + toggles. Zero deps. |
| `record/record-demo.sh` | Script that serves the app, drives it with agent-browser, captures screenshots + WebM + GIF |
| `demo.gif` | Output of the recording (committed for README embed once recorded) |
| `screenshots/` | Individual frames from the run |

## How to record the demo

```bash
# From repo root
bash demo/record/record-demo.sh
```

Requires: `agent-browser`, `python3`, `ffmpeg`. The script:
1. Starts a Python HTTP server serving `sample-app/` on port 8765
2. Opens agent-browser to the sample app
3. Clicks through every interactive element, screenshotting each
4. Records the whole thing as WebM
5. Converts WebM → GIF for README embed

Total runtime: ~30 seconds.

## What the demo shows

- **Home** — initial render, primary nav visible
- **Dashboard** — stats card + "Create New" button
- **Modal** — opens via click, closes via button
- **Settings** — three switches, one toggled live
- **Return to home** — back-nav works

This is what the kit does to your real app — just on a deterministic, dep-free target so the demo is reproducible.

## Why this matters

The README's GIF answers "what does this kit actually do?" in 30 seconds. Without it, the README is words. With it, you SEE the click-through philosophy in action.

## Status

The demo script is committed. The recorded `demo.gif` is generated on demand — run `bash demo/record/record-demo.sh` to produce it. (We don't commit the GIF directly to keep the repo small; it's gitignored. Reproducible from script.)

## Customizing the demo

If you want to record a different demo (e.g., your own app), edit `record/record-demo.sh` to:
1. Change the URL to your dev server
2. Update the click selectors
3. Adjust the screenshot filenames

The infrastructure (server, agent-browser orchestration, ffmpeg conversion) is reusable.
