# Example: Validating a Next.js Web App

Web example using agent-browser as the primary driver.

## Setup

```
.
├── package.json          # has "next"
├── app/
│   ├── page.tsx
│   ├── dashboard/page.tsx
│   └── settings/page.tsx
└── recordings/
```

## User prompt

```
Click through this Next.js app starting from the home page. Test the dashboard and settings flows. Check responsive at 3 sizes.
```

## What the agent does

### 1. Detect + start dev server
```
$ grep '"next"' package.json
→ Platform: web (Next.js)

$ curl -s http://localhost:3000 >/dev/null
→ Dev server not running

$ npm run dev &
→ Started on http://localhost:3000
[wait 5s for server ready]
```

### 2. Open + record
```
$ agent-browser open http://localhost:3000
$ agent-browser record start recordings/web-2026-05-26-1543/run.webm
$ agent-browser screenshot recordings/web-2026-05-26-1543/00-home.png
```

### 3. Snapshot home
```
$ agent-browser snapshot -i

[@e1] link "Dashboard" (/dashboard)
[@e2] link "Settings" (/settings)
[@e3] button "Sign In"
[@e4] heading "Welcome to MyApp"
```

### 4. Click Dashboard
```
$ agent-browser click @e1
$ agent-browser wait 800       # SPA route transition
$ agent-browser screenshot 01-dashboard.png
$ agent-browser snapshot -i

[@e1] heading "Dashboard"
[@e2] card "Total users: 1,234"
[@e3] button "Create New"
[@e4] link "back" (/)
```

### 5. Test "Create New"
```
$ agent-browser click @e3
$ agent-browser wait 400
$ agent-browser screenshot 02-create-modal.png
$ agent-browser snapshot -i

[@e1] dialog "Create New"
[@e2] textbox "Name"
[@e3] button "Save"
[@e4] button "Cancel"

$ agent-browser fill @e2 "Test Item"
$ agent-browser click @e3
$ agent-browser wait 600
$ agent-browser errors
→ No errors

$ agent-browser console
→ "Saved item: Test Item" (info)
```

### 6. Navigate to Settings
```
$ agent-browser click @e4   # back link
$ agent-browser click @e2   # Settings link from home snapshot

[wait for hydration]
$ agent-browser eval "return !!window.__NEXT_DATA__"
→ true

$ agent-browser screenshot 03-settings.png
$ agent-browser snapshot -i

[@e1] heading "Settings"
[@e2] switch "Dark mode"
[@e3] switch "Notifications"
[@e4] button "Sign Out"
```

### 7. Toggle dark mode
```
$ agent-browser click @e2
$ agent-browser wait 300
$ agent-browser screenshot 04-dark-mode.png

[Visual confirmation: background is dark]
$ agent-browser eval "return document.documentElement.classList.contains('dark')"
→ true
```

### 8. Responsive sweep
```
$ for size in "375 667" "768 1024" "1280 720"; do
    read w h <<< "$size"
    agent-browser set viewport $w $h
    agent-browser screenshot "responsive-${w}x${h}.png"
  done

[Inspect screenshots — verify nav adapts]
→ 375x667: ✅ hamburger menu visible, content fits
→ 768x1024: ✅ tablet layout, sidebar visible
→ 1280x720: ✅ desktop layout, all features visible
```

### 9. Web Vitals
```
$ agent-browser vitals

LCP: 1.4s ✅ (under 2.5s target)
INP: 88ms ✅ (under 200ms target)
CLS: 0.04 ✅ (under 0.1 target)
TTFB: 0.3s
```

### 10. Wrap
```
$ agent-browser record stop
$ agent-browser close
```

## Output report

```markdown
# UI Validation Report

**Project:** MyApp (Next.js 15)
**Platform:** web
**Browser:** Chrome 131
**Date:** 2026-05-26T15:43:00-04:00
**Recording:** `recordings/web-2026-05-26-1543/run.webm`

## Verdict: **PASS**

## Navigation Paths Tested
| # | From → To | Method | Result | Evidence |
|---|---|---|---|---|
| 1 | / → /dashboard | Click nav "Dashboard" | PASS | `01-dashboard.png` |
| 2 | /dashboard → modal | Click "Create New" | PASS | `02-create-modal.png` |
| 3 | modal → close | Click "Save" | PASS | item saved, modal closed |
| 4 | /dashboard → / | Click "back" | PASS | — |
| 5 | / → /settings | Click nav "Settings" | PASS | `03-settings.png` |

## Interactive Elements
| Screen | Element | Action | Result |
|---|---|---|---|
| /dashboard | "Create New" button | Click | PASS — modal opened |
| Create modal | "Name" textbox | Fill "Test Item" | PASS |
| Create modal | "Save" button | Click | PASS — item saved, console confirmed |
| /settings | "Dark mode" switch | Click | PASS — `dark` class applied to `<html>` |
| /settings | "Sign Out" button | (not tested — would log out) | SKIPPED |

## Responsive
| Viewport | Layout | Issues |
|---|---|---|
| 375x667 | PASS | None |
| 768x1024 | PASS | None |
| 1280x720 | PASS | None |

## Web Vitals
| Metric | Value | Target | Status |
|---|---|---|---|
| LCP | 1.4s | ≤ 2.5s | ✅ |
| INP | 88ms | ≤ 200ms | ✅ |
| CLS | 0.04 | ≤ 0.1 | ✅ |
| TTFB | 0.3s | ≤ 0.6s | ✅ |

## Console
- 1 info log: "Saved item: Test Item"
- 0 errors

## Fixes Applied
None — clean run.

## Remaining Concerns
- "Sign Out" not tested to avoid disrupting session
- No auth flow validation (separate run recommended with throwaway test account)
```

## What this example demonstrates

1. **Auto-start dev server** — kit checks if port is up, starts `npm run dev` if not
2. **Hydration wait** — uses `window.__NEXT_DATA__` to confirm SSR hydration before interacting
3. **Token-efficient snapshots** — `@eN` refs are ~10 tokens vs 200+ for a CSS selector dump
4. **State verification via JS eval** — confirms dark mode toggle worked at the DOM level
5. **Web Vitals captured** — perf check as part of the run
6. **Clean PASS report** — no fixes needed; happy-path validation only
