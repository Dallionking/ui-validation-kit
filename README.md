# UI Validation Kit

Drop-in UI validation for any CLI coding agent — iOS Simulator, Android emulator, and web in one kit.

Your agent installs the right MCPs, picks the right platform tools, drives the app like a real user, and ships an evidence-backed report. No hand-holding.

> Works with **Claude Code**, **Codex CLI**, **Cursor**, and any AGENTS.md-compatible agent (Windsurf, Cline, Continue, Aider, Zed).

---

## Why this kit

Agentic UI testing has two best-in-class primitives:
- **Web** — [`agent-browser`](https://github.com/vercel-labs/agent-browser) (Vercel Labs): token-efficient `@eN` accessibility refs, video recording, React DevTools
- **Mobile + TV + desktop** — [`agent-device`](https://github.com/callstackincubator/agent-device) (Callstack): same `@eN` refs, one CLI for iOS / Android / tvOS / macOS / Linux

Both ship `@eN` refs that the kit's skill already speaks. Add [Maestro](https://maestro.dev) for declarative cross-platform flows (with the brand-new [Maestro Viewer](https://maestro.dev) putting a live device inside your coding agent), wrap them in a portable skill + QA sub-agent, and you have a complete validation rig.

This kit is the integration: skill + sub-agent + auto-install per harness + platform-aware tool selection.

**One install. Your agent figures out the rest.**

---

## Install

**One-liner (humans):**

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR-ORG/ui-validation-kit/main/install.sh)
```

Auto-detects which agent harness(es) you have (Claude Code, Codex, Cursor) and installs the skill, sub-agent, and MCPs into each. Project-scope by default; `--global` for user-scope.

**Or paste this to your agent:**

```
Read https://github.com/YOUR-ORG/ui-validation-kit and install it. Follow GETTING-STARTED-PROMPT.md.
```

The agent will clone, detect the platform stack (iOS/Android/web/Expo), install the required MCPs, register the skill + QA sub-agent, and run a smoke validation on the current app.

### Primary tools install via npm (no MCP needed)

```bash
npm install -g agent-device       # mobile + TV + desktop
npm install -g agent-browser      # web
brew install maestro              # cross-platform declarative flows
```

These are CLIs that ANY agent can call. No MCP server registration required for the primary tools.

### One-click MCP install (Cursor 0.45+) — fallback layer

Only needed if you specifically want the lower-level MCPs (the primary CLIs above are usually all you need):

| Platform | One-click install |
|---|---|
| iOS Simulator (fallback) | [Install `ios-simulator`](cursor://install-mcp?name=ios-simulator&config=eyJjb21tYW5kIjogIm5weCIsICJhcmdzIjogWyIteSIsICJpb3Mtc2ltdWxhdG9yLW1jcCJdfQ==) |
| Xcode build (fallback) | [Install `xcodebuild`](cursor://install-mcp?name=xcodebuild&config=eyJjb21tYW5kIjogIm5weCIsICJhcmdzIjogWyIteSIsICJ4Y29kZWJ1aWxkbWNwQGxhdGVzdCJdfQ==) |
| Mobile unified (fallback) | [Install `mobile-mcp`](cursor://install-mcp?name=mobile-mcp&config=eyJjb21tYW5kIjogIm5weCIsICJhcmdzIjogWyIteSIsICJAbW9iaWxlbmV4dC9tb2JpbGUtbWNwIl19) |
| Web — Playwright | [Install `playwright`](cursor://install-mcp?name=playwright&config=eyJjb21tYW5kIjogIm5weCIsICJhcmdzIjogWyIteSIsICJAcGxheXdyaWdodC9tY3BAbGF0ZXN0Il19) |
| Web — Chrome DevTools | [Install `chrome-devtools`](cursor://install-mcp?name=chrome-devtools&config=eyJjb21tYW5kIjogIm5weCIsICJhcmdzIjogWyIteSIsICJjaHJvbWUtZGV2dG9vbHMtbWNwIl19) |

After installing the MCPs above, copy the rule:

```bash
mkdir -p .cursor/rules
curl -fsSL https://raw.githubusercontent.com/YOUR-ORG/ui-validation-kit/main/adapters/cursor/rules/ui-validation.mdc > .cursor/rules/ui-validation.mdc
```

---

## What gets installed

| Platform | Primary tool the agent installs | Optional / fallback |
|---|---|---|
| **iOS / Android / tvOS / desktop** | [`agent-device`](https://github.com/callstackincubator/agent-device) — one CLI, `@eN` refs, screenshots/video/logs/network/profile | `xcrun simctl`, `adb`, `ios-simulator-mcp`, `XcodeBuildMCP`, `mobile-mcp` |
| **Web** | [`agent-browser`](https://github.com/vercel-labs/agent-browser) — `@eN` refs, video, React DevTools, Web Vitals | Playwright MCP, Chrome DevTools MCP |
| **Cross-platform declarative flows** | [Maestro](https://maestro.dev) CLI (one YAML runs everywhere) + [Maestro Viewer](https://maestro.dev) (CLI 2.6.0+) | — |
| **Expo / React Native** | `agent-device` (covers Expo, RN, Flutter, native) | Expo dev menu shortcuts |
| **Visual diff (optional)** | — | [Argos](https://argos-ci.com), [Lost Pixel](https://lost-pixel.com) |

The installer is platform-aware: only installs what your project needs. Mobile project → `agent-device` + Maestro. Web-only → `agent-browser` + Playwright. Both → both.

**Why this stack?** `agent-device` and `agent-browser` share the same `@eN` ref convention, so the skill speaks one language across all platforms.

---

## What you get

1. **Skill** — `ui-validation` skill that loads on UI-related triggers ("validate the app", "click through test", "screenshot the home screen")
2. **QA Sub-agent** — `qa-validator` agent the orchestrator can dispatch for full validation runs
3. **MCP fleet** — Platform-appropriate MCPs registered with your harness
4. **Playbooks** — Golden path, visual regression, accessibility audit, flaky-debug
5. **Cost-tiered fix triage** — Agent fixes cheap bugs in-flight (CSS, JSX, missing handlers), bails on expensive ones (native rebuilds, cross-file refactors), reports everything

---

## How it works

1. **Detect** — Agent reads `package.json`, `Package.swift`, `build.gradle`, `app.json` to identify the stack
2. **Install** — Pulls only the MCPs and CLI tools relevant to the detected platform
3. **Drive** — Click-through navigation (never typing URLs / deep links) with accessibility-tree refs
4. **Evidence** — Screenshots + video at every step, saved to `recordings/`
5. **Fix-or-flag** — Cost-tiered triage: cheap fixes in-flight, expensive ones reported
6. **Report** — Structured Markdown report with verdict, evidence, remaining concerns

## Live demo

A self-contained demo runs the kit against a tiny static-HTML app — no real project needed.

```bash
bash demo/record/record-demo.sh
```

Produces `demo/demo.gif` (≈30s, ~720KB) showing click-through, modal interaction, settings toggles. See [`demo/README.md`](./demo/README.md).

## Maestro starter pack

[`.maestro/templates/`](./.maestro/) ships 3 ready-to-customize flows:

- `login.yaml` — login form → home
- `navigation.yaml` — sweep every top-level tab
- `settings.yaml` — toggles + scroll + sign-out

Customize the `appId` + selectors and run with `maestro test .maestro/login.yaml`.

---

## Repo structure

```
ui-validation-kit/
├── skill/SKILL.md                  # Canonical skill (Anthropic format)
├── agent/qa-validator.md           # Sub-agent definition
├── adapters/                       # Per-harness install shims
│   ├── claude-code/
│   ├── codex/
│   ├── cursor/
│   └── generic/                    # AGENTS.md for Cline/Continue/Aider/Windsurf/Zed
├── platforms/                      # ios.md, android.md, web.md, expo.md
├── mcps/manifest.json              # Portable mcpServers JSON
├── playbooks/                      # golden-path, visual-regression, a11y, flaky-debug
├── examples/                       # ios-swiftui, expo-rn, nextjs-web
├── .maestro/templates/             # Cross-platform Maestro starter flows
└── demo/                           # Self-contained sample app + recording script
```

---

## Compatibility matrix

| Harness | Skill format | Sub-agent | MCP install | Tested |
|---|---|---|---|---|
| Claude Code | `.claude/skills/ui-validation/SKILL.md` | `.claude/agents/qa-validator.md` | `claude mcp add` | ✅ |
| Codex CLI | `.agents/skills/ui-validation/SKILL.md` | `.codex/agents/qa-validator.toml` | `~/.codex/config.toml` | ✅ |
| Cursor | `.cursor/rules/ui-validation.mdc` | _(rules-only, no sub-agent)_ | `.cursor/mcp.json` | ✅ |
| Windsurf / Cline / Continue / Aider / Zed | `AGENTS.md` | _(varies)_ | per-harness MCP file | ⚠️ basic |

---

## Uninstall

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOUR-ORG/ui-validation-kit/main/install.sh) --uninstall
```

Removes skill files, sub-agent files, and MCP entries from any harness. Leaves your project's UI code alone.

---

## License

MIT — see [LICENSE](./LICENSE). Use it, fork it, ship it.

## Contributing

PRs welcome. New platform adapter? Add a file under `platforms/`. New playbook? Add to `playbooks/`. See [docs/contributing.md](./docs/contributing.md).
