# Getting Started — Paste this to your agent

> Copy everything below the `---` line and paste it into your CLI agent (Claude Code, Codex, Cursor chat, etc.). The agent will install and configure everything for you.

---

You are installing the **UI Validation Kit** — a skill + QA sub-agent that lets you validate UIs by clicking through them, screenshotting, and reporting evidence. Works on iOS Simulator, Android emulator, and web.

## Your mission

1. **Detect the agent harness** you're running in (Claude Code, Codex CLI, Cursor, or generic AGENTS.md-based).
2. **Detect the project stack** (iOS native, Android native, Expo/React Native, web, or hybrid).
3. **Install only what's needed** — don't install Android tools for a pure iOS project.
4. **Register the skill and sub-agent** in the right place for the detected harness.
5. **Wire up the MCPs** using the harness's MCP install command.
6. **Run a smoke validation** to confirm the kit works.

## Step 1 — Clone or read the kit

If you have network + filesystem access, clone the repo:

```bash
git clone https://github.com/Dallionking/ui-validation-kit /tmp/ui-validation-kit
cd /tmp/ui-validation-kit
```

Otherwise, fetch the raw files you need from `https://raw.githubusercontent.com/Dallionking/ui-validation-kit/main/...`.

## Step 2 — Detect the harness

Check in this order:

| Signal | Harness |
|---|---|
| `~/.claude/` exists OR `command -v claude` | Claude Code |
| `~/.codex/` exists OR `command -v codex` | Codex CLI |
| `~/.cursor/` exists OR Cursor IDE detected | Cursor |
| `AGENTS.md` exists in project root | Generic (Windsurf/Cline/Continue/Aider/Zed) |

You may detect more than one. Install into all detected harnesses unless the user says otherwise.

## Step 3 — Detect the project stack

Read these files in the current project to identify the stack:

| File | What it tells you |
|---|---|
| `Package.swift` or `*.xcodeproj` | iOS native (SwiftUI/UIKit) |
| `build.gradle` or `build.gradle.kts` | Android native |
| `app.json` with `expo` key, `app.config.js` | Expo |
| `package.json` with `react-native` | React Native (non-Expo) |
| `package.json` with `next`/`react`/`vite`/`astro`/`remix` | Web |
| `pubspec.yaml` | Flutter (treat as mobile, recommend Maestro) |

Record what you found. You'll install only relevant MCPs.

## Step 4 — Install primary tools (CLIs, no MCP needed)

The primary tools are CLIs that any agent can call. No MCP registration required.

### Mobile / TV / desktop (if iOS / Android / Expo / RN / Flutter detected)

```bash
# 1. agent-device — primary mobile/TV/desktop CLI (Callstack)
npm install -g agent-device@latest
agent-device --version

# 2. Maestro + Maestro Viewer (declarative cross-platform flows)
command -v maestro || curl -Ls "https://get.maestro.mobile.dev" | bash
maestro --version  # should be >= 2.6.0 for Maestro Viewer

# 3. Platform prerequisites
# iOS
xcode-select -p || (echo "Install Xcode first" && exit 1)
xcrun simctl list devices | head -10

# Android
command -v adb || (echo "Install: brew install android-platform-tools" && exit 1)
adb devices
```

### Web (if detected)

```bash
# 1. agent-browser — primary web CLI (Vercel Labs)
npm install -g agent-browser || cargo install agent-browser || brew install agent-browser
agent-browser --version
```

## Step 5 — Register MCPs (fallback only, optional)

**The primary tools above are CLIs and need no MCP registration.** Skip this step unless you specifically need the fallback MCPs.

If you want the fallback MCPs (only useful if `agent-device` / `agent-browser` are unavailable or you want extra surface area like Playwright cross-browser):

### Claude Code

```bash
# Web fallback (cross-browser via Playwright; Chrome DevTools for perf diagnostics)
claude mcp add playwright --scope user -- npx -y @playwright/mcp@latest
claude mcp add chrome-devtools --scope user -- npx -y chrome-devtools-mcp

# Mobile fallback MCPs (only if agent-device unavailable)
# claude mcp add ios-simulator --scope user -- npx -y ios-simulator-mcp
# claude mcp add xcodebuild --scope user -- npx -y xcodebuildmcp@latest
# claude mcp add mobile-mcp --scope user -- npx -y @mobilenext/mobile-mcp
```

### Codex CLI

Append to `~/.codex/config.toml` (or `.codex/config.toml` for project scope):

```toml
# Web fallback
[mcp_servers.playwright]
command = "npx"
args = ["-y", "@playwright/mcp@latest"]

[mcp_servers.chrome-devtools]
command = "npx"
args = ["-y", "chrome-devtools-mcp"]

# Mobile fallback (only if agent-device unavailable)
# [mcp_servers.ios-simulator]
# command = "npx"
# args = ["-y", "ios-simulator-mcp"]
```

### Cursor

Merge into `~/.cursor/mcp.json` (or `.cursor/mcp.json` for project scope):

```json
{
  "mcpServers": {
    "playwright": { "command": "npx", "args": ["-y", "@playwright/mcp@latest"] },
    "chrome-devtools": { "command": "npx", "args": ["-y", "chrome-devtools-mcp"] }
  }
}
```

**Important:** Merge by key — never overwrite the existing `mcpServers` object. Use `python3 -c "import json; ..."` to do this idempotently.

## Step 6 — Register the skill

### Claude Code

```bash
# Project scope
mkdir -p .claude/skills/ui-validation
cp /tmp/ui-validation-kit/skill/SKILL.md .claude/skills/ui-validation/SKILL.md

# Sub-agent
mkdir -p .claude/agents
cp /tmp/ui-validation-kit/agent/qa-validator.md .claude/agents/qa-validator.md
```

### Codex CLI

```bash
mkdir -p .agents/skills/ui-validation
cp /tmp/ui-validation-kit/skill/SKILL.md .agents/skills/ui-validation/SKILL.md

# Sub-agent (TOML format)
mkdir -p .codex/agents
cp /tmp/ui-validation-kit/adapters/codex/agents/qa-validator.toml .codex/agents/qa-validator.toml
```

### Cursor

```bash
mkdir -p .cursor/rules
cp /tmp/ui-validation-kit/adapters/cursor/rules/ui-validation.mdc .cursor/rules/ui-validation.mdc
```

### Generic

```bash
# Append to project AGENTS.md (or create one)
cat /tmp/ui-validation-kit/adapters/generic/AGENTS.md >> AGENTS.md
```

## Step 7 — Smoke validation

Boot a simulator or open the web app, then run the smoke flow:

```
Use the ui-validation skill to do a smoke run on the current app. Take a screenshot of the home screen and confirm the primary nav buttons work.
```

You should see:
1. Agent picks the right platform tool
2. Boots simulator OR opens browser
3. Screenshots home state
4. Clicks each nav element, screenshots after
5. Returns a short PASS/FAIL report with evidence paths

## Step 8 — Report back

Tell the user:

```
Installed UI Validation Kit
- Detected harness(es): [list]
- Detected platform stack: [list]
- MCPs registered: [list]
- Skill location: [path]
- Sub-agent location: [path]
- Smoke run: PASS / FAIL [link to report]

Try it: "validate the home screen" or "click through every button on the settings page"
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| `agent-device` not found | npm install failed or not on PATH | `npm install -g agent-device@latest` then check `which agent-device` |
| `agent-browser` not found | Not on PATH | Reinstall via `npm install -g agent-browser`, check `which agent-browser` |
| Maestro can't find device | Simulator not booted | `xcrun simctl boot booted` or open Simulator.app |
| Maestro Viewer unavailable | Maestro < 2.6.0 | Upgrade: `curl -Ls 'https://get.maestro.mobile.dev' \| bash` |
| `ios-simulator-mcp` errors on launch (fallback only) | Facebook IDB missing | `brew install idb-companion` |
| Claude Code doesn't pick up skill | Cache | Restart Claude Code |
| Cursor doesn't see MCP | JSON syntax | Validate `.cursor/mcp.json` |

If something fails, **stop and report to the user** rather than retrying blindly. Include the exact command and error.

---

When you're done, the user should be able to say "validate the app" and get a real evidence-backed report. That's the bar.
