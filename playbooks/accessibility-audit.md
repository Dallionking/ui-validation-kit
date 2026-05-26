# Playbook: Accessibility Audit

Sweep the app for accessibility issues using the same accessibility-tree refs that the validation skill already relies on. This playbook surfaces a11y findings as a structured report.

## What this catches

- Missing accessibility labels on interactive elements
- Insufficient color contrast (web only — auto-tooling)
- Heading hierarchy violations (web)
- Missing alt text on images
- Focus order issues (keyboard nav, screen reader nav)
- Touch target size < 44pt (iOS) / 48dp (Android)
- Missing `accessibilityRole` / `accessibilityHint` on custom components

## What this doesn't catch

- Cognitive accessibility (language complexity, layout clarity)
- Animation triggers seizures (flashing checks — out of scope)
- Real screen-reader testing (manual VoiceOver / TalkBack sweep needed)

## Tooling by platform

### iOS

```bash
# Snapshot accessibility tree
ios_simulator.snapshot()

# Filter for elements missing labels
# Use ios-simulator-mcp.ui_find_element with type filters,
# then check each returned element for a non-empty accessibility label
```

For real-device testing, use Xcode's **Accessibility Inspector** (Xcode → Open Developer Tool → Accessibility Inspector).

### Android

```bash
# Snapshot
mobile_mcp.snapshot()

# Or use Accessibility Scanner (Google's app):
adb install -r AccessibilityScanner.apk
# Then in-app, scan each screen
```

### Web

```bash
# axe-core via Playwright
npx @axe-core/cli http://localhost:3000

# Or with agent-browser
agent-browser eval "
  const axe = await import('https://cdn.jsdelivr.net/npm/axe-core/+esm');
  return axe.run();
"
```

## Flow

### 1. For each screen in the app

```
1. Navigate to the screen (click-through, per kit rules)
2. Capture the accessibility tree
3. Audit each interactive element:
   - Has accessibilityLabel? (mobile)
   - Has aria-label / accessible name? (web)
   - Has accessibilityRole? (mobile)
   - Has accessibilityHint? (mobile, if action isn't obvious)
4. Audit each image:
   - Has alt text? (web)
   - Has accessibilityLabel? (mobile)
5. Check touch target sizes (mobile):
   - Tap targets >= 44pt (iOS) / 48dp (Android)
6. Check color contrast (web):
   - Body text: 4.5:1 against background
   - Large text (18pt+): 3:1
```

### 2. Heading hierarchy (web)

```bash
agent-browser eval "
  return [...document.querySelectorAll('h1,h2,h3,h4,h5,h6')]
    .map(h => ({ tag: h.tagName, text: h.textContent.trim().slice(0, 50) }));
"
```

Verify:
- Exactly one `<h1>` per page
- Heading levels don't skip (h1 → h3 is bad)
- Headings describe the section content

### 3. Focus order (web + mobile)

```bash
# Web: tab through every interactive element
agent-browser keyboard tab tab tab tab
# Screenshot each focus state; verify order matches visual order
```

### 4. Touch target sizes (mobile)

```bash
# iOS - inspect frame of each interactive element
# Use Xcode Accessibility Inspector or manual measurement
```

Flag any tappable element smaller than 44×44 points (iOS) or 48×48 dp (Android).

## Report format

```markdown
# Accessibility Audit Report
**Platform:** {ios | android | web}
**Date:** {iso}
**Standard:** WCAG 2.2 Level AA (web), Apple HIG (iOS), Material Design (Android)

## Summary
- Screens audited: 8
- Findings: 12 (3 critical, 6 serious, 3 minor)
- Pass rate: 83%

## Critical findings
| # | Screen | Element | Issue | WCAG / HIG ref |
|---|---|---|---|---|
| 1 | Settings | Theme toggle | No accessibilityLabel | WCAG 1.3.1 / HIG Labels |
| 2 | Home | Hero image | Missing alt text | WCAG 1.1.1 |

## Serious findings
| # | Screen | Element | Issue | Fix |
|---|---|---|---|---|
| 3 | Profile | Avatar tap target | 32×32, needs 44×44 | Increase padding |

## Minor findings
| # | Screen | Element | Issue |
|---|---|---|---|
| 9 | Dashboard | "Submit" button | Missing accessibilityHint |

## Heading hierarchy (web)
- /dashboard: ✅ valid
- /settings: ⚠️ skips h2 → h4
- /profile: ✅ valid
```

## Triage

Most a11y fixes are **cheap** (single-file additions of `accessibilityLabel` / `aria-label`). Fix in-flight.

Exceptions:
- Touch target size fixes that require layout changes → may be cross-file → escalate if so
- Heading hierarchy fixes that require component refactor → escalate

## See also

- [WCAG 2.2 quick reference](https://www.w3.org/WAI/WCAG22/quickref/)
- [Apple Accessibility HIG](https://developer.apple.com/design/human-interface-guidelines/accessibility)
- [Android Accessibility Best Practices](https://developer.android.com/guide/topics/ui/accessibility/principles)
- `platforms/{ios,android,web}.md` — Platform-specific a11y APIs
