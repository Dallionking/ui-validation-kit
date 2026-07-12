<!-- gitnexus:start -->
# GitNexus — Code Intelligence

This project is indexed by GitNexus as **ui-validation-kit** (607 symbols, 594 relationships, 0 execution flows). Use the GitNexus MCP tools to understand code, assess impact, and navigate safely.

> If any GitNexus tool warns the index is stale, run `npx gitnexus analyze` in terminal first.

## Task tracking & execution (Standard Workflow — 2026-07-12)
- Tasks live in **Linear** (workspace dallion-king, project Dev Tools, team DAL); GitHub is the PR/code loop. New persistent task → Linear issue (wave-labeled).
- Builds run through **Orca**: pull the Linear task → `orca status` → orchestrator session (Fable/Claude side or Sol/Codex side per model lanes) → `~/.local/bin/orca-dispatch-task` per task (worktree waves, depth-1 workers) → gates (Greptile review + Codex cross-model + coordinator) → PR → merge → cleanup per the ownership ledger.
- Loop spec: `~/.claude/references/loop-registry.md` (Core-5: BUILD, TICK+TIMER, CLEANUP, PR-SWEEP, GAP). Constitution: `~/AGENTS.md`.

## Always Do

- **MUST run impact analysis before editing any symbol.** Before modifying a function, class, or method, run `gitnexus_impact({target: "symbolName", direction: "upstream"})` and report the blast radius (direct callers, affected processes, risk level) to the user.
- **MUST run `gitnexus_detect_changes()` before committing** to verify your changes only affect expected symbols and execution flows.
- **MUST warn the user** if impact analysis returns HIGH or CRITICAL risk before proceeding with edits.
- When exploring unfamiliar code, use `gitnexus_query({query: "concept"})` to find execution flows instead of grepping. It returns process-grouped results ranked by relevance.
- When you need full context on a specific symbol — callers, callees, which execution flows it participates in — use `gitnexus_context({name: "symbolName"})`.

## Never Do

- NEVER edit a function, class, or method without first running `gitnexus_impact` on it.
- NEVER ignore HIGH or CRITICAL risk warnings from impact analysis.
- NEVER rename symbols with find-and-replace — use `gitnexus_rename` which understands the call graph.
- NEVER commit changes without running `gitnexus_detect_changes()` to check affected scope.

## Resources

| Resource | Use for |
|----------|---------|
| `gitnexus://repo/ui-validation-kit/context` | Codebase overview, check index freshness |
| `gitnexus://repo/ui-validation-kit/clusters` | All functional areas |
| `gitnexus://repo/ui-validation-kit/processes` | All execution flows |
| `gitnexus://repo/ui-validation-kit/process/{name}` | Step-by-step execution trace |

## CLI

| Task | Read this skill file |
|------|---------------------|
| Understand architecture / "How does X work?" | `.claude/skills/gitnexus/gitnexus-exploring/SKILL.md` |
| Blast radius / "What breaks if I change X?" | `.claude/skills/gitnexus/gitnexus-impact-analysis/SKILL.md` |
| Trace bugs / "Why is X failing?" | `.claude/skills/gitnexus/gitnexus-debugging/SKILL.md` |
| Rename / extract / split / refactor | `.claude/skills/gitnexus/gitnexus-refactoring/SKILL.md` |
| Tools, resources, schema reference | `.claude/skills/gitnexus/gitnexus-guide/SKILL.md` |
| Index, status, clean, wiki CLI commands | `.claude/skills/gitnexus/gitnexus-cli/SKILL.md` |

<!-- gitnexus:end -->