# Playbook: Golden Path

The minimum-viable validation flow. Run after every UI change. Should complete in under 2 minutes for a small app.

## What it covers

- App boots / loads
- Home screen renders with no console / logcat errors
- Primary nav (top tabs / bottom tabs / sidebar) all reachable
- One representative interaction per main screen
- Responsive at 3 device/viewport sizes

## What it doesn't cover

- Edge cases (empty states, error states, loading states)
- Auth flows beyond the smoke check
- Backend integrations under load
- Visual regression / pixel diff

Use `playbooks/deep-sweep.md` for full coverage. Golden path is for "ship-with-confidence" speed.

## Flow

### 1. Detect + boot (15s)

```
- Detect platform from project files
- Boot simulator/emulator/browser
- Install + launch app
- Wait for first paint
- Screenshot: 00-launch.png
```

### 2. Home check (10s)

```
- Screenshot: 01-home.png
- Snapshot interactive elements
- Read console/logcat — no errors expected
- Pass if: home renders, primary nav visible, no errors
```

### 3. Primary nav sweep (30-60s)

For each top-level nav element (tabs, sidebar links):
```
- Tap/click the nav element
- Wait for transition (500ms mobile, 200ms web)
- Screenshot: 02-{section}.png
- Snapshot — verify expected elements present
- Read console — no new errors
- Tap back / home to return
```

### 4. One representative interaction per section (15s each)

For each section visited, do ONE interaction that proves the section is functional:
- Dashboard → tap the primary CTA button
- Settings → toggle one switch
- Profile → tap an editable field

Don't go deeper. Just prove the section isn't dead.

### 5. Responsive sweep (30s)

Re-screenshot the home at 3 sizes:

| Platform | Sizes |
|---|---|
| Web | 375x667, 768x1024, 1280x720 |
| iOS | iPhone SE, iPhone 16, iPad Pro |
| Android | Pixel 4a, Pixel 8, Pixel Tablet |

### 6. Report

```markdown
# Golden Path Report
**Date:** {iso}
**Platform:** {ios | android | web}
**Duration:** {seconds}

## Verdict: PASS / FAIL

### Home
- Rendered: ✅ (01-home.png)
- Errors: 0
- Primary nav visible: ✅

### Primary nav sweep
| Section | Reached | Errors | Evidence |
|---|---|---|---|
| Dashboard | ✅ | 0 | 02-dashboard.png |
| Settings | ✅ | 0 | 02-settings.png |
| Profile | ✅ | 0 | 02-profile.png |

### Interactions
| Section | Action | Result |
|---|---|---|
| Dashboard | Tap "Create New" | Modal opened |
| Settings | Toggle theme | UI updated |
| Profile | Tap edit name | Keyboard appeared |

### Responsive
| Size | Layout | Issues |
|---|---|---|
| 375x667 | ✅ | None |
| 768x1024 | ✅ | None |
| 1280x720 | ✅ | None |
```

## Failure modes

| Failure | Likely cause | Triage |
|---|---|---|
| App doesn't launch | Build error / missing deps | STOP — report to user, don't try to fix |
| Home shows blank | JS error / network fail | Read console; if cheap fix (1 file), fix; else escalate |
| Nav element missing | Style hidden / wrong rendering | Snapshot to confirm; if missing in DOM, cheap fix |
| Console error on home | Real bug | Triage cheap vs expensive; fix or escalate |
| Layout breaks at 375px | Missing responsive styles | Cheap fix (CSS); fix in-flight |

## When to escalate from golden path to deep sweep

- Any FAIL in golden path → don't run deep sweep until golden is green
- Major UI rewrite (>10 file UI diff) → run deep sweep instead of golden
- Pre-release / pre-merge to main → run deep sweep
