# Web Platform Reference

How the UI Validation Kit drives web apps. Read this when validating Next.js, Vite, Astro, Remix, Svelte, Solid, Nuxt, or Angular projects.

## Tooling stack

| Tier | Tool | What it covers |
|---|---|---|
| Primary | [`agent-browser`](https://github.com/vercel-labs/agent-browser) (Vercel Labs) | Native Rust CDP CLI, accessibility-tree `@eN` refs, React DevTools, Web Vitals, video recording |
| Cross-browser | [`microsoft/playwright-mcp`](https://github.com/microsoft/playwright-mcp) | Chromium / Firefox / WebKit |
| Diagnostics | [`ChromeDevTools/chrome-devtools-mcp`](https://github.com/ChromeDevTools/chrome-devtools-mcp) | Web Vitals, console, network, CPU emulation |

Pick **agent-browser** for token efficiency (accessibility snapshots ≈ 200-400 tokens vs Playwright's verbose HTML dumps). Use Playwright when you specifically need Firefox or WebKit. Use Chrome DevTools MCP for perf diagnostics.

## Prerequisites

```bash
# agent-browser (primary)
npm install -g agent-browser
# OR: cargo install agent-browser
# OR: brew install agent-browser

# Playwright browsers (only if you need cross-browser)
npx playwright install --with-deps chromium
```

## `agent-browser` cheat sheet

```bash
# Lifecycle
agent-browser open https://localhost:3000
agent-browser close

# Navigation (ONLY for initial load — never for in-app routing)
agent-browser open <url>
agent-browser back
agent-browser forward
agent-browser reload

# Capture
agent-browser screenshot path.png
agent-browser record start path.webm
agent-browser record stop

# Interaction
agent-browser snapshot -i              # interactive elements with refs
agent-browser click @e3
agent-browser fill @e5 "user@example.com"
agent-browser select @e7 "option-value"
agent-browser hover @e3

# Inspection
agent-browser console                   # console log
agent-browser errors                    # page errors
agent-browser network                   # network requests
agent-browser vitals                    # Web Vitals (LCP, FID, CLS, INP)
agent-browser react                     # React DevTools introspection

# Viewport
agent-browser set viewport 375 667     # mobile
agent-browser set viewport 768 1024    # tablet
agent-browser set viewport 1280 720    # desktop
```

## Interaction patterns

### Click-through navigation (mandatory)

Start at `/`. Click visible navigation. **Never** type a URL path directly.

```bash
agent-browser open http://localhost:3000
agent-browser snapshot -i
# → [@e1] link "Dashboard"
# → [@e2] link "Settings"
# → [@e3] button "Sign In"

agent-browser click @e1                # navigates to /dashboard via SPA router
agent-browser screenshot dashboard.png
```

### Fill forms

```bash
agent-browser fill @e5 "test@example.com"
agent-browser fill @e6 "password123"
agent-browser click @e7                 # submit button
```

### Wait for state change

```bash
agent-browser wait 1000                 # ms
# OR: wait for a specific selector to appear
agent-browser wait-for text="Welcome back"
```

### React DevTools introspection

When a click does nothing, check the component tree:

```bash
agent-browser react component @e3       # inspect props/state of clicked element
```

Useful to confirm whether a handler is bound, what state is being passed, etc.

### Console + errors

After every interaction:

```bash
agent-browser errors                    # uncaught exceptions
agent-browser console                   # console.log / warn / error
```

A clean run = empty errors output. If anything is logged, triage it.

## Web Vitals

Get the perf snapshot:

```bash
agent-browser vitals
# →
# LCP: 1.2s
# FID: 12ms
# CLS: 0.02
# INP: 45ms
# TTFB: 0.4s
```

Targets (per [web.dev](https://web.dev/articles/vitals)):
- LCP ≤ 2.5s
- INP ≤ 200ms
- CLS ≤ 0.1

Anything over budget → flag as a finding (not a fix-in-flight unless it's an obvious miss like a non-deferred large script).

## Responsive sweep

```bash
for viewport in "375 667" "768 1024" "1280 720" "1920 1080"; do
  read w h <<< "$viewport"
  agent-browser set viewport $w $h
  agent-browser screenshot "recordings/responsive-${w}x${h}.png"
  agent-browser snapshot -i
  # Inspect for layout overflows, hidden nav, etc
done
```

## Dev server detection

The skill auto-detects the dev server port from `package.json`:

```bash
# Common patterns:
#   "dev": "next dev"             → port 3000
#   "dev": "vite"                 → port 5173
#   "dev": "astro dev"            → port 4321
#   "dev": "remix dev"            → port 3000
#   "dev": "svelte-kit dev"       → port 5173
#   "dev": "next dev -p 4000"     → port 4000

# Detect:
PORT=$(grep -oE 'PORT=[0-9]+' .env 2>/dev/null | cut -d= -f2)
[[ -z "$PORT" ]] && PORT=$(node -e "
  const pkg = require('./package.json');
  const dev = pkg.scripts?.dev || '';
  const m = dev.match(/-p\s+(\d+)/);
  console.log(m ? m[1] : (dev.includes('vite') ? 5173 : 3000));
")
```

Then check if it's already running:

```bash
if curl -s "http://localhost:$PORT" >/dev/null; then
  echo "Dev server already running"
else
  echo "Starting dev server"
  npm run dev &
  sleep 5
fi
```

## Authentication

Use agent-browser's auth vault to persist login between runs:

```bash
agent-browser auth save dev-user --url http://localhost:3000/login
# Walk through login once; agent-browser saves cookies/localStorage

# Subsequent runs:
agent-browser open --auth dev-user http://localhost:3000/dashboard
```

For test environments, prefer seeding a known test account over real OAuth flows.

## Common gotchas

| Symptom | Cause | Fix |
|---|---|---|
| `agent-browser` not found | Not on PATH | `which agent-browser`; reinstall |
| Click does nothing | Event handler missing OR wrong ref | `agent-browser react component @e3` to check; re-snapshot |
| Page never loads | Dev server down / port wrong | Check `curl` to root URL |
| Screenshot blank | Page still hydrating (SSR) | `agent-browser wait 2000` after navigation |
| Refs change between snapshots | DOM mutated | Re-snapshot before each interaction |
| Auth cookies don't persist | Same-site policy in dev | Use auth vault, or set `--insecure-cookies` |

## Visual regression

Two layers:

**Pixel diff** (deterministic, fast, brittle):
- [Argos](https://argos-ci.com) (OSS) — Playwright + Storybook integration, PR review UI
- [Lost Pixel](https://lost-pixel.com) (OSS) — Storybook-friendly
- [BackstopJS](https://github.com/garris/BackstopJS) — classic

**Intent diff** (semantic, slower, more useful):
- Vision-LLM-as-judge — pass before/after screenshots + the user's intent to Claude/GPT vision, ask "does the after still meet the intent"
- See `playbooks/visual-regression.md` for the prompt template

## Playwright fallback (cross-browser)

If you specifically need Firefox or WebKit:

```bash
# The Playwright MCP exposes:
playwright.browse(url, browser="firefox")
playwright.screenshot()
playwright.click(selector)
playwright.fill(selector, text)
```

Use sparingly — much heavier token cost than agent-browser.

## See also

- `playbooks/golden-path.md` — Canonical golden-path flow
- `playbooks/visual-regression.md` — Visual diff workflows
- `mcps/manifest.json` — MCP registry
