
---

## UI Validation Kit

This project uses the [UI Validation Kit](https://github.com/Dallionking/ui-validation-kit) for click-through UI validation across iOS Simulator, Android emulator, and web.

### When to invoke

Whenever the user asks to:
- "validate the app" / "QA the app" / "click through"
- "screenshot the UI" / "test buttons work"
- "end-to-end UI test" / "deep validation sweep"
- After any UI change, to confirm nothing regressed

### Core rules

1. **Click-through only.** Start at the app's root state. Tap/click visible elements to navigate. **Never** type URL paths after initial launch.

2. **Fix-before-moving-on, cost-tiered.** Cheap fixes (single file, CSS/JSX, missing handler) → fix in-flight, max 3 attempts, 90s wall-clock per attempt. Expensive fixes (native rebuild >30s, cross-file, build config) → escalate to findings, do not fix.

3. **Record everything.** Screenshot every state change. Save to `recordings/{platform}-{timestamp}/`. Video record where the platform supports it.

4. **Evidence-based reporting.** Every PASS/FAIL cites a screenshot path or video timestamp. No naked verdicts.

### Platform detection

| File present | Platform |
|---|---|
| `Package.swift` / `*.xcodeproj` | iOS native |
| `build.gradle` / `build.gradle.kts` | Android native |
| `app.json` with `"expo"` | Expo |
| `package.json` with `react-native` | React Native |
| `package.json` with `next`/`vite`/`astro`/`remix`/`svelte`/`solid` | Web |

### Tools by platform

| Platform | Primary | Optional / fallback |
|---|---|---|
| iOS / Android / tvOS / desktop | [`agent-device`](https://github.com/callstackincubator/agent-device) (Callstack) — one CLI, `@eN` refs | `xcrun simctl`, `adb`, ios-simulator-mcp, XcodeBuildMCP, mobile-mcp |
| Web | [`agent-browser`](https://github.com/vercel-labs/agent-browser) (Vercel Labs) — `@eN` refs, Web Vitals, React DevTools | Playwright MCP, Chrome DevTools MCP |
| Cross-platform declarative flows | [Maestro](https://maestro.dev) + Maestro Viewer (CLI 2.6.0+) | — |

### Workflow

1. **Detect** platform from project files
2. **Boot** simulator/emulator/browser
3. **Install + launch** the app (mobile) or open dev URL (web)
4. **Screenshot** initial state
5. **Snapshot** interactive elements (accessibility tree, not pixels)
6. **For each nav element:** tap → wait → check errors → screenshot → re-snapshot → test interactive children
7. **Triage failures** using cost tiers
8. **Responsive sweep** at 3 viewport/device sizes
9. **Generate report:** structured Markdown with verdict + evidence

### Cost-tier triage

Follow the **canonical triage rules in the kit's `skill/SKILL.md` and `agent/qa-validator.md`**. The headline policy:

**CHEAP — fix in-flight (max 3 attempts, 90s wall-clock each):**
- Single-file changes (CSS/JSX/SwiftUI modifier/Compose attribute)
- Missing `onPress` / `onClick` handler
- Style typos
- Missing `accessibilityLabel` / `aria-label`
- Wrong import paths

**EXPENSIVE — escalate to findings, do not fix:**
- Native module rebuild required
- Cross-file refactor (>1 file)
- Build config / dependency changes
- New native permissions

> See `skill/SKILL.md` § Cost-tier triage for the authoritative rubric. If the user has filled in the TODO in `agent/qa-validator.md`, those rules take precedence over the summary above.

### Report format

```markdown
# UI Validation Report
Platform: {ios | android | web | expo}
Device: {name}
Date: {iso timestamp}
Recording: {path}

## Verdict
PASS | FAIL | PASS WITH CAVEATS

## Navigation paths tested
| # | From → To | Method | Result | Evidence |

## Interactive elements
| Screen | Element | Action | Result | Evidence |

## Fixes applied (cheap, in-flight)
| # | File | Change | Reason |

## Findings (escalated, not fixed)
| # | Screen | Issue | Suggested fix |

## Remaining concerns
```

### Negative boundaries

- Never type URL paths after initial launch
- Never skip a broken interaction without recording why
- Never report PASS without evidence
- Never modify non-UI files unless the fix directly addresses a UI bug
- Never auto-fix above the cheap tier
- Never brute-force pixel coordinates when accessibility refs are available
