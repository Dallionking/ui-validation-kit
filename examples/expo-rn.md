# Example: Validating an Expo / React Native App

Cross-platform Expo example. Runs the same flow on both iOS and Android via Maestro.

## Setup

```
.
├── app.json
├── package.json          # has "expo" and "react-native"
├── App.tsx
├── components/
│   ├── HomeScreen.tsx
│   └── SettingsScreen.tsx
└── .maestro/             # created if you adopt Maestro flows
```

## User prompt

```
Validate this Expo app on both iOS and Android. Click through home, dashboard, settings.
```

## What the agent does

### 1. Detect platform
```
$ cat app.json | grep '"expo"'
→ Platform detected: expo (will run iOS + Android)
```

### 2. Boot both simulators
```
# iOS
$ xcrun simctl boot "iPhone 16"
$ open -a Simulator

# Android
$ emulator @Pixel_8_API_34 &
$ adb wait-for-device
```

### 3. Start Expo
```
$ npx expo start --dev-client &
→ Metro bundler running on port 8081
```

### 4. Install on iOS
```
$ npx expo run:ios --device "iPhone 16"
→ Built, installed, launched
```

### 5. Install on Android
```
$ npx expo run:android --device emulator-5554
→ Built, installed, launched
```

### 6. Run Maestro cross-platform flow

The kit creates `.maestro/home-sweep.yaml`:

```yaml
appId: com.example.myexpo
---
- launchApp:
    clearState: true
- takeScreenshot: 00-home
- assertVisible: "Home"
- assertVisible: "Dashboard"
- tapOn: "Dashboard"
- waitForAnimationToEnd
- takeScreenshot: 01-dashboard
- assertVisible: "Stats"
- tapOn: "Create New"
- waitForAnimationToEnd
- takeScreenshot: 02-create-modal
- tapOn: "Cancel"
- back
- tapOn: "Settings"
- waitForAnimationToEnd
- takeScreenshot: 03-settings
- assertVisible: "Theme"
- tapOn: "Theme"
- waitForAnimationToEnd
- takeScreenshot: 04-theme-toggled
```

Run on iOS:
```bash
$ maestro test .maestro/home-sweep.yaml --device "iPhone 16"
→ ✅ All assertions passed
```

Run on Android:
```bash
$ maestro test .maestro/home-sweep.yaml --device emulator-5554
→ ❌ FAILED: "Theme toggle didn't update UI" at step 14
```

### 7. Triage the Android failure

```
[Read components/SettingsScreen.tsx]
→ ThemeToggle uses useColorScheme() but Android override path missing
→ Cost tier: cheap (single file)

[Edit components/SettingsScreen.tsx]
+ import { Appearance } from 'react-native';
  ...
  onPress={() => {
+   Appearance.setColorScheme(isDark ? 'light' : 'dark');
    setIsDark(!isDark);
  }}

[Reload via Expo dev menu — adb shell input keyevent 82, then 'r' 'r']
[Re-run Maestro flow on Android]
→ ✅ All assertions passed
```

## Output report

```markdown
# UI Validation Report

**Project:** MyExpo
**Platform:** expo (iOS + Android)
**Devices:** iPhone 16 (iOS 26.2), Pixel 8 (Android 14)
**Date:** 2026-05-26T15:43:00-04:00
**Recording (iOS):** `recordings/ios-2026-05-26-1543/run.mp4`
**Recording (Android):** `recordings/android-2026-05-26-1543/run.mp4`

## Verdict: **PASS WITH ONE FIX**

## Platform results
| Platform | First run | After fix |
|---|---|---|
| iOS | PASS | PASS |
| Android | FAIL (step 14) | PASS |

## Cross-platform finding
The theme toggle worked on iOS but not Android. Root cause: missing `Appearance.setColorScheme` call. This was a single-file React Native fix that affected both platforms (but only manifested on Android due to React Native's color scheme behavior differing from iOS).

## Fix
| # | File | Change | Affected |
|---|---|---|---|
| 1 | `components/SettingsScreen.tsx:18` | Added `Appearance.setColorScheme` | Android (broken) + iOS (no-op, was already working) |

## Maestro flow (committed)
`.maestro/home-sweep.yaml` — reusable in CI

## Remaining concerns
- The flow doesn't test the "Notifications" toggle in Settings — added to follow-up
- Web target (Expo Web) not validated in this run — recommend separate sweep
```

## What this example demonstrates

1. **Cross-platform Expo detection** — `"expo"` key in `app.json`
2. **Same Maestro flow runs on both platforms** — one YAML, two devices
3. **Cross-platform finding** — bug manifests on one platform but the fix is shared code
4. **Commit-worthy flow** — Maestro YAML stays in the repo as a regression test
5. **Reload via dev menu** — `adb shell input keyevent 82` + `r r`
