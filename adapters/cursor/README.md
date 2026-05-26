# Cursor Adapter

How the UI Validation Kit installs into Cursor.

## What gets installed

| Component | Destination (project) | Destination (global) |
|---|---|---|
| Skill (as rule) | `.cursor/rules/ui-validation.mdc` | `~/.cursor/rules/ui-validation.mdc` |
| MCPs | `.cursor/mcp.json` `mcpServers` | `~/.cursor/mcp.json` `mcpServers` |

> **Note on sub-agents:** Cursor doesn't have first-class sub-agents like Claude Code or Codex. The `qa-validator` behavior is embedded in the rule itself, and the user invokes it by asking Cursor to "run the qa-validator workflow".

## Manual install

```bash
# 1. Rule
mkdir -p .cursor/rules
cp rules/ui-validation.mdc .cursor/rules/ui-validation.mdc

# 2. MCPs (merge — never overwrite)
python3 - <<'PYEOF'
import json, os
cfg = ".cursor/mcp.json"
os.makedirs(".cursor", exist_ok=True)
if os.path.exists(cfg):
    data = json.load(open(cfg))
else:
    data = {"mcpServers": {}}
with open("mcp.json.fragment") as f:
    new = json.load(f)
data.setdefault("mcpServers", {}).update(new["mcpServers"])
json.dump(data, open(cfg, "w"), indent=2)
print(f"Merged {len(new['mcpServers'])} MCP entries into {cfg}")
PYEOF
```

## Triggering the rule

Cursor rules with `description` are auto-attached based on context. The kit's rule triggers on UI-related phrases. Use `@ui-validation` in chat to attach explicitly:

```
@ui-validation validate the home screen
```

## One-click MCP install (Cursor 0.45+)

Cursor supports deeplink MCP installs. The canonical deeplink set is in the [root README](../../README.md#one-click-mcp-install-cursor-045--fallback-layer). Each link looks like:

```
cursor://install-mcp?name=ios-simulator&config=<base64-of-server-config>
```

Click the buttons in the root README to install each MCP directly into Cursor.

## Verification

Open Cursor, then in chat:

```
What rules are active in this project?
```

You should see `ui-validation`. Then:

```
@ui-validation screenshot the home screen.
```

## Uninstall

```bash
rm -f .cursor/rules/ui-validation.mdc
# Manually remove kit entries from .cursor/mcp.json (or re-run installer with --uninstall)
```
