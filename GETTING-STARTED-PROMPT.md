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

## Step 4 — Install platform tooling

### iOS (if detected)

```bash
# 1. Verify Xcode + simulator are installed
xcode-select -p || (echo "Install Xcode first" && exit 1)
xcrun simctl list devices | head -20

# 2. Install Facebook IDB (required by ios-simulator-mcp)
brew tap facebook/fb 2>/dev/null || true
brew install idb-companion

# 3. Verify Maestro
command -v maestro || curl -Ls "https://get.maestro.mobile.dev" | bash
```

### Android (if detected)

```bash
# 1. Verify adb
command -v adb || (echo "Install Android Platform Tools" && exit 1)

# 2. List running emulators
adb devices

# 3. Verify Maestro (cross-platform)
command -v maestro || curl -Ls "https://get.maestro.mobile.dev" | bash
```

### Web (if detected)

```bash
# 1. Install agent-browser (primary)
npm install -g agent-browser || cargo install agent-browser || brew install agent-browser

# 2. Playwright (for cross-browser)
npx playwright install --with-deps chromium
```

## Step 5 — Register MCPs

Read `mcps/manifest.json` from the kit. It contains the portable `mcpServers` shape per platform.

### Claude Code

For each MCP in the manifest relevant to detected platforms:

```bash
claude mcp add ios-simulator --scope user -- npx -y ios-simulator-mcp
claude mcp add xcodebuild --scope user -- npx -y xcodebuildmcp@latest
claude mcp add mobile-mcp --scope user -- npx -y @mobilenext/mobile-mcp
claude mcp add playwright --scope user -- npx -y @playwright/mcp@latest
claude mcp add chrome-devtools --scope user -- npx -y chrome-devtools-mcp
```

### Codex CLI

Append to `~/.codex/config.toml`:

```toml
[mcp_servers.ios-simulator]
command = "npx"
args = ["-y", "ios-simulator-mcp"]

[mcp_servers.xcodebuild]
command = "npx"
args = ["-y", "xcodebuildmcp@latest"]

# ...etc per platform
```

### Cursor

Merge into `~/.cursor/mcp.json` (or `.cursor/mcp.json` for project scope):

```json
{
  "mcpServers": {
    "ios-simulator": { "command": "npx", "args": ["-y", "ios-simulator-mcp"] },
    "xcodebuild": { "command": "npx", "args": ["-y", "xcodebuildmcp@latest"] }
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
| `ios-simulator-mcp` errors on launch | Facebook IDB missing | `brew install idb-companion` |
| Maestro can't find device | Simulator not booted | `xcrun simctl boot booted` or open Simulator.app |
| `agent-browser` not found | Not on PATH | Reinstall, check `which agent-browser` |
| Claude Code doesn't pick up skill | Cache | Restart Claude Code |
| Cursor doesn't see MCP | JSON syntax | Validate `.cursor/mcp.json` |

If something fails, **stop and report to the user** rather than retrying blindly. Include the exact command and error.

---

When you're done, the user should be able to say "validate the app" and get a real evidence-backed report. That's the bar.
