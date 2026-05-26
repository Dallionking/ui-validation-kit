# Contributing

PRs welcome. Below is the contributor map for the most common changes.

## Quick contributions

### Add a new platform

1. Add `platforms/<name>.md` with the same structure as existing platform files
2. Add detection logic to `skill/SKILL.md` § Detect platform
3. Add MCP entries to `mcps/manifest.json` under `platforms.<name>`
4. Add CLI tool entries to `mcps/manifest.json` under `cli_tools.<name>`
5. Add install steps to `install.sh` `install_<name>_tooling()` function
6. Add an example: `examples/<platform>-<framework>.md`
7. Update `README.md` compatibility matrix

### Add a new harness

1. Create `adapters/<harness>/` directory
2. Add `adapters/<harness>/README.md` with manual install steps
3. Add harness detection to `install.sh` `<harness>_detected()` function
4. Add `register_mcp_<harness>` and `install_skill_<harness>` functions
5. Update `README.md` compatibility matrix

### Add a new playbook

1. Create `playbooks/<name>.md` with this structure:
   - **What it covers** — bullets
   - **What it doesn't cover** — bullets
   - **Flow** — numbered steps
   - **Report format** — Markdown example
   - **Failure modes** — table
   - **See also** — cross-refs

2. Link from `skill/SKILL.md` § See also

### Add a new MCP

1. Add to `mcps/manifest.json` `mcpServers.<name>` with command + args
2. Add to relevant `platforms.<platform>` arrays in the same file
3. Update README's "What gets installed" table
4. Add a brief description in the relevant `platforms/<name>.md` tooling table

## Code standards

- **Shell scripts** — pass `shellcheck` with severity ≥ warning
- **Markdown** — frontmatter required for skill + sub-agent files (`name`, `description`)
- **JSON** — valid via `jq empty` — no trailing commas, no comments
- **TOML** — valid via `python3 -c "import tomllib; tomllib.load(open(file, 'rb'))"`
- **Markdown links** — relative within the repo, absolute for external

## Testing your contribution

```bash
# Dry-run the installer with your changes
bash install.sh --dry-run

# Run CI checks locally
npm test                          # validates manifest + lints install.sh

# Test a specific harness install
bash install.sh --target=claude --dry-run
bash install.sh --target=codex --dry-run
bash install.sh --target=cursor --dry-run
```

## PR checklist

- [ ] Did you update README's compatibility matrix?
- [ ] Did you update `skill/SKILL.md` § See also with any new platform/playbook?
- [ ] Did you add an example in `examples/`?
- [ ] Did you test the installer at least in `--dry-run`?
- [ ] Did you preserve idempotency in any new install operation?
- [ ] Did you avoid duplicating content from `skill/SKILL.md` in adapters?

## Single source of truth — don't duplicate

The most common mistake in PRs: copying skill logic into an adapter or playbook. Don't.

- The **skill** says what to do (click-through, cost-tier, evidence)
- **Adapters** say how to install the skill into a harness
- **Playbooks** say named workflows that use the skill
- **Platforms** say which tools the skill uses for each OS

Each file owns its concern. If you find yourself copy-pasting between them, refactor instead.

## License

By contributing, you agree your contributions are licensed under MIT.
