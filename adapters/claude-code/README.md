# Claude Code Adapter

How the UI Validation Kit installs into Claude Code.

## What gets installed

| Component | Destination (project scope) | Destination (global scope) |
|---|---|---|
| Skill | `.claude/skills/ui-validation/SKILL.md` | `~/.claude/skills/ui-validation/SKILL.md` |
| Sub-agent | `.claude/agents/qa-validator.md` | `~/.claude/agents/qa-validator.md` |
| MCPs | `claude mcp add ... --scope project` | `claude mcp add ... --scope user` |
| (Optional) hooks | `.claude/settings.json` merged | `~/.claude/settings.json` merged |

## Manual install (if you don't want the bootstrap)

```bash
# 1. Skill
mkdir -p .claude/skills/ui-validation
cp ../../skill/SKILL.md .claude/skills/ui-validation/SKILL.md

# 2. Sub-agent
mkdir -p .claude/agents
cp ../../agent/qa-validator.md .claude/agents/qa-validator.md

# 3. Primary tools (CLIs — no MCP registration needed)
npm install -g agent-device@latest         # mobile / TV / desktop
npm install -g agent-browser               # web
command -v maestro || curl -Ls 'https://get.maestro.mobile.dev' | bash   # cross-platform flows

# 4. Optional MCPs (only register fallback MCPs if you specifically want them)
#    The primary tools above are CLIs that Claude Code can shell-out to directly.
#    Register the lines below ONLY if you want extra surface area:

# Web (Playwright cross-browser + Chrome DevTools for perf):
claude mcp add playwright --scope project -- npx -y @playwright/mcp@latest
claude mcp add chrome-devtools --scope project -- npx -y chrome-devtools-mcp

# Mobile fallback MCPs (commented out — only register if agent-device unavailable):
# claude mcp add ios-simulator --scope project -- npx -y ios-simulator-mcp
# claude mcp add xcodebuild --scope project -- npx -y xcodebuildmcp@latest
# claude mcp add mobile-mcp --scope project -- npx -y @mobilenext/mobile-mcp

# 5. Verify
claude mcp list
```

## Triggering the skill

The skill auto-loads on these triggers (from SKILL.md `description` field):

- "validate the app"
- "click through"
- "screenshot the UI"
- "test buttons work"
- "run a UI smoke test"
- "verify the screen renders"

## Dispatching the sub-agent

For full validation runs, dispatch via the Agent tool:

```
"Use the qa-validator sub-agent to do a deep validation sweep of iOS + web."
```

Or explicitly:

```
Agent({
  subagent_type: "qa-validator",
  description: "Deep iOS + web validation",
  prompt: "Run a deep sweep on iOS Simulator and Chrome. Target the home, dashboard, and settings screens. Use the cost-tier triage rules from agent/qa-validator.md."
})
```

## Hook integration (optional)

If you want to auto-run validation after UI file changes, add a PostToolUse hook to `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "filePatterns": ["**/*.tsx", "**/*.swift", "**/*.kt", "**/*.css"],
        "command": "echo 'UI file changed — consider running ui-validation'"
      }
    ]
  }
}
```

See `settings.template.json` in this directory for a copy-pasteable starter.

## Verification

After install, test it works:

```bash
claude
```

Then in the Claude prompt:

```
What skills do you have available?
```

You should see `ui-validation` in the list. Then:

```
Use the ui-validation skill to take a screenshot of the home screen of this app.
```

## Uninstall

```bash
rm -rf .claude/skills/ui-validation
rm -f .claude/agents/qa-validator.md
claude mcp remove ios-simulator
claude mcp remove xcodebuild
claude mcp remove mobile-mcp
claude mcp remove playwright
claude mcp remove chrome-devtools
```
