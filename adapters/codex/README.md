# Codex CLI Adapter

How the UI Validation Kit installs into Codex CLI.

## What gets installed

| Component | Destination (project) | Destination (global) |
|---|---|---|
| Skill | `.agents/skills/ui-validation/SKILL.md` | `~/.agents/skills/ui-validation/SKILL.md` |
| Sub-agent | `.codex/agents/qa-validator.toml` | `~/.codex/agents/qa-validator.toml` |
| MCPs | `.codex/config.toml` `[mcp_servers.X]` | `~/.codex/config.toml` `[mcp_servers.X]` |
| Project instructions | `AGENTS.md` appended | n/a |

Codex consumes the same Anthropic SKILL.md format — no conversion needed. The sub-agent uses Codex's TOML format (different from Claude Code's markdown frontmatter).

## Manual install

```bash
# 1. Skill (Anthropic format works as-is)
mkdir -p .agents/skills/ui-validation
cp ../../skill/SKILL.md .agents/skills/ui-validation/SKILL.md

# 2. Sub-agent (TOML)
mkdir -p .codex/agents
cp agents/qa-validator.toml .codex/agents/qa-validator.toml

# 3. Append MCP fragment to .codex/config.toml
cat config.toml.fragment >> .codex/config.toml

# 4. Add project instructions
cat AGENTS.md.fragment >> AGENTS.md

# 5. Verify
codex skills list
codex agents list
```

## Triggering the skill

Codex auto-loads skills based on the SKILL.md `description` field. Trigger with:

```
codex "Validate the home screen of this app."
```

## Dispatching the sub-agent

```
codex --agent qa-validator "Do a deep validation sweep of iOS and web."
```

Or via the `task` subcommand:

```
codex task assign qa-validator "Deep iOS validation, target home + dashboard + settings"
```

## File details

### `agents/qa-validator.toml`

Codex sub-agents use TOML, not markdown. See the file in this directory for the format. Key fields:

| Field | Value |
|---|---|
| `name` | `qa-validator` |
| `description` | Trigger description |
| `model` | `gpt-5.5` (or override) |
| `allowed_tools` | `["bash", "read", "write", "edit", "glob", "grep"]` |
| `skills` | `["ui-validation"]` |
| `system_prompt_file` | `.agents/skills/ui-validation/SKILL.md` |

### `config.toml.fragment`

MCP server entries appended to `~/.codex/config.toml`. The installer merges idempotently — never overwrites existing entries.

### `AGENTS.md.fragment`

Project-level instruction snippet that tells Codex about the kit. Appended to your project's `AGENTS.md`.

## Verification

```bash
codex
```

Then in the prompt:

```
What skills do you have available?
```

You should see `ui-validation`. Then:

```
Use ui-validation to screenshot the home screen.
```

## Uninstall

```bash
rm -rf .agents/skills/ui-validation
rm -f .codex/agents/qa-validator.toml
# Manually remove [mcp_servers.ios-simulator], etc. from .codex/config.toml
# Manually remove the kit's AGENTS.md section
```
