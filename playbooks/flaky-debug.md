# Playbook: Flaky UI Debugging

When a UI test fails intermittently — passes sometimes, fails others — use this playbook to find the root cause.

## Common flakiness sources

| Cause | Symptom | Detection |
|---|---|---|
| Race condition | Element not found ~30% of runs | Add wait, re-run |
| Animation timing | "Click before ready" | Sleep after navigation |
| Network non-determinism | API returns differently | Mock the API |
| Server-rendered hydration | Element exists but no event handler attached yet | Wait for hydration |
| Real time / random data | Different screenshots each run | Freeze time, seed RNG |
| Permission dialogs | Different first-vs-second run | Pre-grant or pre-dismiss |
| Cache state | Different first-vs-second run | Erase sim state, clear cache |
| Locale / timezone | Different localized strings | Set locale explicitly |
| Async cleanup leak | State leaks between tests | Test isolation |

## Reproduction strategy

### 1. Reproduce reliably first

Don't try to fix until you can reproduce. Run the test 10 times in a loop:

```bash
for i in {1..10}; do
  echo "Run $i"
  maestro test flow.yaml > "run-$i.log" 2>&1
done
grep -l "FAILED" run-*.log
```

Note the pass rate. 7/10 pass = "flaky". 1/10 = "almost broken". 9/10 = "watch for trend".

### 2. Increase observability

Add screenshots and console captures before and after the failing step:

```yaml
# Maestro
- launchApp
- tapOn: "Get Started"
- takeScreenshot: before-flaky-step      # NEW
- waitForAnimationToEnd                  # NEW
- tapOn: "Continue"
- takeScreenshot: after-flaky-step       # NEW
```

Look at the screenshots from failed vs passed runs. The difference tells you what's flaky.

### 3. Common fixes by symptom

#### "Element not found"

Add explicit wait:
```yaml
# Maestro
- waitFor:
    element: "Continue"
    timeout: 5000
- tapOn: "Continue"
```

Web (agent-browser):
```bash
agent-browser wait-for selector="button[name='Continue']"
agent-browser click @continue
```

#### "Click before ready"

Wait for animation:
```yaml
# Maestro
- tapOn: "Open Modal"
- waitForAnimationToEnd
- tapOn: "Confirm"
```

#### Hydration race (web SSR)

Wait for hydration signal:
```bash
agent-browser eval "
  return new Promise(resolve => {
    if (document.readyState === 'complete' && window.__NEXT_DATA__) resolve(true);
    else window.addEventListener('load', () => resolve(true));
  });
"
```

#### Time-dependent UI

Freeze the clock:
```javascript
// In Playwright test setup
await page.addInitScript(() => {
  const FROZEN = new Date('2026-01-15T12:00:00Z').getTime();
  Date.now = () => FROZEN;
});
```

iOS:
```bash
xcrun simctl status_bar booted override --time 9:41
```

#### Permission dialogs

Pre-grant:
```bash
xcrun simctl privacy booted grant camera com.example.app
adb shell pm grant com.example.app android.permission.CAMERA
```

Or dismiss in-flight via Maestro:
```yaml
- runFlow:
    when:
      visible: "Allow"
    commands:
      - tapOn: "Allow"
```

#### Cache state

Erase the sim before each run:
```bash
# iOS
xcrun simctl erase booted

# Android
adb shell pm clear com.example.app
```

#### Locale

```bash
# iOS
xcrun simctl launch --terminate-running-process booted com.example.app \
  -AppleLanguages '(en)' \
  -AppleLocale 'en_US'

# Android
adb shell setprop persist.sys.locale en-US
adb shell setprop persist.sys.timezone America/New_York
```

### 4. Isolate

Run the same test in isolation (no other tests before it). If it passes alone but fails in suite → state leak from a prior test.

### 5. Bisect

If the test used to pass and now fails:
```bash
git bisect start
git bisect bad HEAD
git bisect good <last-known-good-commit>
# git checks out commits; re-run test at each step
```

## Report format

```markdown
# Flaky Test Debug Report
**Test:** {test name}
**Failure rate:** 3/10 (30%)
**Date:** {iso}

## Symptoms
- Element "Continue" not found in 3 of 10 runs
- Screenshots from failing runs show modal still animating in

## Root cause
Modal open animation has variable duration (200-400ms depending on device load).
Test taps "Continue" inside the modal without waiting for animation.

## Fix
Added `waitForAnimationToEnd` after opening the modal.

## Verification
Re-ran 50 times: 50/50 pass.
```

## When to escalate

- Pass rate < 80% AND you've tried the fixes above → ask user; may need a deeper architectural fix
- Flakiness only on CI, not local → CI environment issue (machine speed, network, display)
- Flakiness only in one timezone → timezone-dependent logic in the app itself

## See also

- `playbooks/golden-path.md` — Golden path runs that should be 100% reliable
- [Maestro flakiness guide](https://docs.maestro.dev/advanced/flakiness)
