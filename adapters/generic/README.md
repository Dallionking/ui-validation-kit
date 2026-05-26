# Generic Adapter

For any agent that reads `AGENTS.md` as its project-instructions file. This covers Windsurf, Cline, Continue, Aider, Zed, and other AGENTS.md-compatible agents.

## What gets installed

| Component | Destination |
|---|---|
| Project instructions | `AGENTS.md` appended |
| Skill (as inline rules) | Embedded in `AGENTS.md` |
| MCPs | Per-harness MCP file (you wire manually) |

## Manual install

```bash
# Append the kit's instructions to your AGENTS.md
cat AGENTS.md >> ../../AGENTS.md      # if your project already has AGENTS.md
# OR
cp AGENTS.md ../../AGENTS.md          # if not
```

For MCPs, see your harness's specific config file:

| Harness | MCP config file |
|---|---|
| Windsurf | `~/.codeium/windsurf/mcp_config.json` |
| Cline | `.clinerules/mcp.json` |
| Continue | `~/.continue/config.yaml` (`mcpServers` block) |
| Aider | Aider doesn't have MCP — use the `CONVENTIONS.md` file (point it at the kit) |
| Zed | `~/.config/zed/settings.json` (`context_servers`) |
| Gemini CLI | `~/.gemini/settings.json` |

The `mcpServers` JSON shape from `mcps/manifest.json` translates directly into all of these — just paste the relevant entries.

## Triggering

Once `AGENTS.md` is in place, the agent will auto-load the kit's rules. Test:

```
Validate the home screen of this app.
```

The agent should ask which platform (if ambiguous) or just run the validation for the detected stack.

## Aider

Aider reads `CONVENTIONS.md` for project conventions. Append the kit's rules:

```bash
cat AGENTS.md >> CONVENTIONS.md
```

Aider doesn't drive simulators natively, but it can guide an agent's reasoning about validation work.

## Verification

Open your agent and ask:

```
What are this project's rules about UI validation?
```

It should describe the click-through philosophy, cost-tier triage, and evidence-based reporting.

## Uninstall

```bash
# Remove the "UI Validation Kit" section from AGENTS.md
# (the section is clearly delimited with "## UI Validation Kit" header)
```
