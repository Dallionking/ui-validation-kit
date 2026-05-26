# Architecture

How the kit is organized and why.

## Design principles

1. **Single source of truth.** `skill/SKILL.md` is canonical. Every harness adapter references it — no content duplication.
2. **Anthropic SKILL.md format.** Same file works in Claude Code (`.claude/skills/`) and Codex (`.agents/skills/`). Anthropic's format is the de-facto standard.
3. **Platform-aware install.** Don't install Android tools for an iOS project. Detect the stack, install only what's needed.
4. **Idempotent merging.** Every install operation can be re-run safely. JSON configs merged by key, never overwritten.
5. **Harness-portable MCP shape.** The `mcpServers` JSON shape is consumed by Claude Code, Codex, Cursor, Windsurf, Cline, Continue. We use it as the portable manifest.
6. **No vendor lock-in.** All tools are OSS. No required cloud accounts. Optional cloud features (Maestro Cloud, Argos) are clearly optional.

## File layout rationale

```
ui-validation-kit/
├── skill/SKILL.md              ← canonical skill (Anthropic format)
├── agent/qa-validator.md       ← canonical sub-agent (Claude Code format)
├── adapters/                   ← per-harness shims, point at canonical
├── platforms/                  ← per-platform tool reference
├── mcps/manifest.json          ← portable mcpServers shape
├── playbooks/                  ← reusable validation flows
├── examples/                   ← real-world demonstrations
└── install.sh                  ← entry point
```

### Why `skill/SKILL.md` is the source of truth

- Anthropic's SKILL.md format is the most widely-adopted standard (141k stars on `anthropics/skills`)
- Codex consumes the exact same format via `.agents/skills/`
- For Cursor, we extract the body into a `.mdc` rule (frontmatter format differs but content is the same)
- For generic AGENTS.md, we embed the body inline

This means: **update `skill/SKILL.md` once, all harnesses get the update.** The adapters only contain harness-specific config (paths, install commands, frontmatter conversions) — never duplicated skill logic.

### Why `agent/qa-validator.md` uses Claude Code format

- Claude Code is the most expressive sub-agent format (YAML frontmatter with `name`, `description`, `tools`, `model`, `skills`, `mcpServers`, `hooks`, etc.)
- Codex's TOML format is a strict subset — we convert via `adapters/codex/agents/qa-validator.toml`
- Cursor doesn't have first-class sub-agents — we embed the agent's behavior in the rule itself

### Why platforms are separate files

- iOS, Android, and web have different tool stacks. A unified doc would be 4× longer and harder to navigate.
- Each platforms file is self-contained — the agent reads only the file for the detected platform.
- Easier to contribute new platforms (Windows? macOS? VR?) without touching the core skill.

### Why playbooks are separate from the skill

- The skill defines **what to do** (click-through, fix-cost-tier, evidence-based reporting).
- Playbooks define **named workflows** for specific scenarios (golden path, visual regression, a11y audit, flaky-debug).
- Users can ask "run the accessibility audit playbook" without the skill needing to enumerate every possible flow.

## Install flow

```
┌────────────────┐
│  install.sh    │
└────┬───────────┘
     │
     ├──→ Detect harnesses (claude / codex / cursor / generic)
     │
     ├──→ Detect platforms (ios / android / expo / web)
     │
     ├──→ For each detected platform:
     │      └──→ Install CLI tools (Maestro, IDB, adb, agent-browser)
     │
     ├──→ For each detected harness:
     │      ├──→ Copy skill/SKILL.md to harness location
     │      ├──→ Copy agent/qa-validator.md (converted if needed)
     │      └──→ Register MCPs from manifest.json
     │
     └──→ Print summary + verification command
```

## Why JSON merging is idempotent

We use `python3` for `settings.json` / `mcp.json` edits, never `sed` / `awk`:

```python
data = json.load(open(cfg))
data.setdefault("mcpServers", {})[name] = spec
json.dump(data, open(cfg, "w"), indent=2)
```

This:
- Preserves existing entries
- Updates existing keys (no duplicates)
- Survives concurrent edits between runs
- Handles missing files (`.setdefault`)

For TOML (`config.toml`), we use grep-then-append:

```bash
if grep -q "^\[mcp_servers\.$name\]" "$config"; then
  : # already present
else
  cat >> "$config" <<EOF
[mcp_servers.$name]
command = "..."
args = [...]
EOF
fi
```

Less elegant than JSON, but matches Codex's expected format.

## Why we ship multiple MCPs per platform

For iOS, we ship `ios-simulator-mcp`, `xcodebuild` (XcodeBuildMCP), and `mobile-mcp`. Why not just one?

- **`ios-simulator-mcp`** (joshuayoes/ios-simulator-mcp): focused, taps + screenshots + a11y queries. Best for UI driving.
- **`xcodebuild` (XcodeBuildMCP)**: build, install, launch, log capture. Best for the "make and run" half.
- **`mobile-mcp` (mobile-next/mobile-mcp)**: cross-platform iOS + Android. Useful when you want one MCP for both, or as a fallback if the others break.

The skill picks the best tool per task. Multiple MCPs registered ≠ all called every time.

## Sub-agent vs skill — when each is right

| Use case | Skill | Sub-agent |
|---|---|---|
| Quick smoke check | ✅ in-line | overkill |
| Full validation sweep | possible | ✅ delegate |
| Single-platform validation | ✅ | overkill |
| Multi-platform parallel sweep | possible | ✅ delegate |
| Just need a screenshot | ✅ | overkill |
| Need cost-tier triage decisions | ✅ has rules | ✅ enforces rules |

Rule of thumb: if the user says "validate" → skill. If they say "QA" or "deep validation" → sub-agent.

## Comparing to existing OSS

| Project | Coverage | Format | Role in this kit |
|---|---|---|---|
| [vercel-labs/agent-browser](https://github.com/vercel-labs/agent-browser) | Web | CLI | **Primary web tool.** `@eN` refs, video, React DevTools, Web Vitals |
| [callstackincubator/agent-device](https://github.com/callstackincubator/agent-device) | iOS + Android + tvOS + macOS + Linux | CLI | **Primary mobile/TV/desktop tool.** Same `@eN` ref convention as agent-browser |
| [Maestro](https://maestro.dev) | iOS + Android + web | CLI + YAML | **Declarative flows.** Maestro Viewer (CLI 2.6.0+) puts a live device inside the agent |
| [joshuayoes/ios-simulator-mcp](https://github.com/joshuayoes/ios-simulator-mcp) | iOS | MCP | Fallback if agent-device unavailable |
| [mobile-next/mobile-mcp](https://github.com/mobile-next/mobile-mcp) | iOS + Android | MCP | Fallback if agent-device unavailable |
| [cameroncooke/XcodeBuildMCP](https://github.com/cameroncooke/XcodeBuildMCP) | iOS build | MCP | Fallback for build/install when agent-device session can't bootstrap |
| [SUPER-DESIGN](https://github.com/Eldergenix/SUPER-DESIGN) | Design skills | Cross-CLI installer | Inspiration for installer pattern (single-source-of-truth, shims) |
| [taskmaster-ai](https://github.com/blader/taskmaster) | Task mgmt | Cross-CLI installer | Inspiration for idempotent JSON merge via python3 |

**This kit's gap-filling contribution:** the integration layer. `agent-device` and `agent-browser` are siblings (both use `@eN` refs), but until this kit existed, no skill knew to switch between them based on platform detection. Cross-CLI install (Claude Code / Codex / Cursor / generic AGENTS.md) and a QA sub-agent with cost-tier triage are also kit-original.

## Future work

- v0.2.0 — Windows app support (UI Automation, FlaUI)
- v0.2.0 — One-click Cursor MCP deeplinks in README
- v0.3.0 — Vision-LLM intent diff as a first-class playbook with built-in prompts
- v0.3.0 — CI templates (GitHub Actions, GitLab CI) for visual regression
- v0.4.0 — Plugin marketplace listing (Claude Code's `claude plugin add ui-validation-kit`)
