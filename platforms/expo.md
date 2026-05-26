# Expo / React Native Platform Reference

How the UI Validation Kit drives Expo and bare React Native apps.

**Primary tool:** [`agent-device`](https://github.com/callstackincubator/agent-device) covers Expo, React Native, Flutter, and native iOS/Android — all from one CLI. The patterns below are mostly about the Expo dev loop (build, hot reload, dev menu) since the validation calls are identical to native iOS/Android.

Most of the iOS and Android patterns apply directly — this file covers what's different about Expo.

## Detection

```bash
# Expo
[[ -f "app.json" ]] && grep -q '"expo"' app.json
[[ -f "app.config.js" ]] || [[ -f "app.config.ts" ]]

# Bare React Native (no Expo)
[[ -f "package.json" ]] && grep -q '"react-native"' package.json && ! grep -q '"expo"' app.json 2>/dev/null
```

## Stack flavors

| Flavor | Detection | Validation approach |
|---|---|---|
| **Expo Go** | `app.json` `"expo": {}` + no custom native code | `npx expo start --ios` / `--android`; treat as standard iOS/Android validation |
| **Expo dev client** | `expo-dev-client` in dependencies | `npx expo run:ios` / `run:android`; same validation, but rebuilds are expensive |
| **Expo Router** | `expo-router` in dependencies | File-based routing — capture screen titles from route names |
| **Bare RN (Pure)** | No Expo deps, `react-native` only | `npx react-native run-ios` / `run-android` |
| **Expo Web** | `app.json` has `"web": {...}` | Treat as web validation — use agent-browser |

## Bootstrap

### Expo (managed)

```bash
# iOS
npx expo start --ios            # boots simulator, installs Expo Go, opens app

# Android
npx expo start --android        # boots emulator, installs Expo Go, opens app

# Web
npx expo start --web            # opens browser at localhost:8081
```

### Expo (dev client)

```bash
# iOS (first time builds native)
npx expo run:ios                # 60-120s first build, then ~5s subsequent

# Android (first time builds native)
npx expo run:android            # similar timing
```

> Dev client rebuilds are the most common "expensive" fix tier on Expo. Don't trigger them as in-flight fixes.

### Bare React Native

```bash
npx react-native run-ios
npx react-native run-android
```

## Expo dev menu

When validating, you may need to toggle the dev menu:

| Action | iOS Simulator | Android Emulator |
|---|---|---|
| Open dev menu | `⌘D` | `⌘M` (Mac) / `Ctrl+M` |
| Reload | `r` (twice) in dev menu | `r` (twice) in dev menu |
| Toggle Element Inspector | "Show Element Inspector" | "Show Element Inspector" |
| Toggle Performance Monitor | "Show Perf Monitor" | "Show Perf Monitor" |

Programmatic dev menu (iOS):
```bash
xcrun simctl spawn booted notifyutil -p "host.exp.Exponent.DevMenu"
```

Programmatic reload (Android):
```bash
adb shell input keyevent 82                 # opens menu
adb shell input text "rr"                   # double-tap reload
```

## Validation differences from native

| Concern | Native iOS / Android | Expo / RN |
|---|---|---|
| Accessibility | Native a11y trees | Same trees — RN forwards `accessibilityLabel` correctly |
| Hot reload | N/A | Reloading is FAST (<2s); use it for fixes |
| Native rebuild | N/A | Only needed for native module changes (45s-120s) |
| Bundle ID detection | `Info.plist` / build settings | `app.json` `ios.bundleIdentifier` / `android.package` |
| Permissions | Pre-grant via `simctl` / `adb` | Same |
| Push notifications | APNS / FCM | Expo push tokens (use `expo push:send` for tests) |

## Reading `app.json` / `app.config.{js,ts}`

The kit pulls these fields:

```json
{
  "expo": {
    "name": "MyApp",
    "slug": "myapp",
    "ios": { "bundleIdentifier": "com.example.myapp" },
    "android": { "package": "com.example.myapp" },
    "web": { "bundler": "metro" },
    "scheme": "myapp"
  }
}
```

For dynamic config:
```bash
npx expo config --json | jq '.expo.ios.bundleIdentifier'
```

## Triage notes for Expo

Common fix tiers for Expo projects:

| Issue | Tier | Notes |
|---|---|---|
| Button has no `onPress` | cheap | Single file, add handler, hot reload |
| Style typo (`width` vs `with`) | cheap | Hot reload picks up immediately |
| Missing prop on a custom component | cheap | Single file |
| `accessibilityLabel` missing | cheap | Single file |
| Wrong import path | cheap | Single file |
| Native module missing | EXPENSIVE | Requires `expo prebuild` + rebuild |
| New native permission | EXPENSIVE | Requires native rebuild (Info.plist / AndroidManifest changes) |
| Expo SDK upgrade | EXPENSIVE | Cross-cutting |
| EAS Build config | OUT OF SCOPE | Don't touch CI config in-flight |

## Common gotchas

| Symptom | Cause | Fix |
|---|---|---|
| `Unable to load script` | Metro not running | Restart `npx expo start` |
| `RedBox` on launch | JS error | Read error stack, fix source, hot reload |
| Hot reload not picking up changes | File watcher hiccup | `r` twice in dev menu |
| Expo Go shows old version | Cache | Force-quit Expo Go, restart |
| Accessibility refs missing | RN components without `accessible={true}` | Flag as a11y finding |
| Web target broken | Metro/web bundler issue | Check `app.json` `"web"` config |

## Maestro for Expo

Maestro works great for Expo since it's accessibility-tree based:

```yaml
# flow.yaml
appId: com.example.myapp
---
- launchApp
- tapOn: "Sign In"
- inputText: "test@example.com"
- assertVisible: "Welcome back"
- takeScreenshot: home
```

Run:
```bash
maestro test flow.yaml
maestro test flow.yaml --device emulator-5554     # specific Android
maestro test flow.yaml --device "iPhone 16"        # specific iOS
```

Maestro is **the** recommended cross-platform tool for Expo — write the flow once, runs on iOS and Android.

## See also

- `platforms/ios.md` — Underlying iOS Simulator tools
- `platforms/android.md` — Underlying Android emulator tools
- `playbooks/golden-path.md` — Canonical flow
- `mcps/manifest.json` — MCP registry
