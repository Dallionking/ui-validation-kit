# Android Platform Reference

How the UI Validation Kit drives Android emulator. Read this when validating native Jetpack Compose / Views apps or Expo/RN running on Android.

## Tooling stack

| Tier | Tool | What it covers |
|---|---|---|
| **Primary** | [`agent-device`](https://github.com/callstackincubator/agent-device) (Callstack) | One CLI: taps, snapshots with `@eN` refs, screenshots, video, logs, network, replay scripts |
| Flow runner | [Maestro](https://maestro.dev) + [Maestro Viewer](https://maestro.dev) (CLI 2.6.0+) | Declarative YAML flows; Viewer puts a live device inside the agent |
| Raw | `adb` (Android Platform Tools) | Install, launch, logcat, screenrecord, permissions |
| Fallback MCP | [`mobile-next/mobile-mcp`](https://github.com/mobile-next/mobile-mcp) | Unified iOS + Android fallback |
| Fallback MCP | [`minhalvp/android-mcp-server`](https://github.com/minhalvp/android-mcp-server) | Pure adb wrapper fallback |
| Fallback MCP | [`srmorete/adb-mcp`](https://github.com/srmorete/adb-mcp) | TypeScript adb MCP fallback |

## Prerequisites

```bash
# 1. Android Platform Tools (adb)
brew install android-platform-tools

# 2. agent-device (primary — covers iOS + Android + TV + desktop)
npm install -g agent-device@latest
agent-device --version

# 3. Maestro (declarative flows + Maestro Viewer)
curl -Ls 'https://get.maestro.mobile.dev' | bash

# 4. An emulator (via Android Studio or sdkmanager)
sdkmanager --list | grep system-images

# 5. List running devices/emulators
adb devices
```

## `agent-device` cheat sheet (primary path)

Same CLI as iOS — see [`platforms/ios.md`](./ios.md) § agent-device cheat sheet. Swap `--platform ios` for `--platform android`.

```bash
agent-device apps --platform android
agent-device open SampleApp --platform android
agent-device snapshot -i
agent-device tap @e2
agent-device screenshot ./artifacts/home.png
agent-device logs --platform android
agent-device close
```

For everything agent-device can't do (pre-grant permissions, FCM push tests, sdcard pulls), drop down to `adb` below.

## `adb` cheat sheet

```bash
# Discover
adb devices                                  # list connected
adb -s <serial> shell                        # target specific device

# Lifecycle
emulator -list-avds                          # list AVDs
emulator @Pixel_8_API_34 &                   # boot one
adb reboot                                   # restart current

# App lifecycle
adb install -r app-debug.apk
adb uninstall com.example.app
adb shell am start -n com.example/.MainActivity
adb shell am force-stop com.example.app
adb shell pm clear com.example.app           # clear app data

# Capture
adb exec-out screencap -p > screen.png
adb shell screenrecord /sdcard/run.mp4       # ^C to stop, then pull
adb pull /sdcard/run.mp4

# Logs (filter by app)
adb logcat -d --pid=$(adb shell pidof -s com.example.app)

# Permissions
adb shell pm grant com.example.app android.permission.CAMERA
adb shell pm grant com.example.app android.permission.ACCESS_FINE_LOCATION

# Deep links (DO NOT use for navigation during validation — only for launch)
adb shell am start -W -a android.intent.action.VIEW \
  -d "myapp://home" com.example.app

# Push notifications via FCM
# (use Maestro or Firebase test endpoint — adb can't directly fire FCM)
```

## Interaction patterns

### Tap by accessibility label

Use `mobile-mcp.snapshot` to get accessibility-tree refs, then `mobile-mcp.tap`. **Never** brute-force pixel coordinates.

```
mobile_mcp.snapshot()
→ returns labeled tree like:
   [@a1] Button "Sign In"
   [@a2] EditText "Email"
   [@a3] EditText "Password"

mobile_mcp.tap("@a1")
mobile_mcp.input("@a2", "user@example.com")
```

### Wait for state change

Compose recomposition is fast (<50ms typical), but if you're animating with `animateContentSize` or `AnimatedVisibility`, default duration is 300ms. Sleep at least 500ms after a tap.

### Handle dialogs

Android dialogs (AlertDialog, ModalBottomSheet) are separate windows in the accessibility tree. Re-snapshot after one appears.

### Permissions dialogs

Two strategies:
1. **Pre-grant** via `adb shell pm grant` before launch (clean)
2. **Tap through** in the validation run (realistic)

Pre-grant for golden path. Tap through for full validation.

### Keyboard

```
mobile_mcp.input("@a2", "hello world")
```

Or via adb:
```bash
adb shell input text "hello%sworld"          # %s = space
adb shell input keyevent KEYCODE_ENTER
```

## Common gotchas

| Symptom | Cause | Fix |
|---|---|---|
| `adb devices` shows nothing | USB debugging off / device locked | Unlock device, enable USB debugging |
| Multiple emulators — wrong target | adb picks first | Use `adb -s <serial>` |
| `INSTALL_FAILED_VERSION_DOWNGRADE` | Older APK | `adb uninstall <pkg>` first |
| `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | Signature mismatch | Same as above |
| Screenshot is black | Surface flinger not ready | Wait 2s after launch |
| Accessibility refs missing | App has poor a11y | Flag as a finding; fall back to coordinate taps as last resort |
| Emulator slow / laggy | Software rendering | Enable hardware acceleration in AVD; allocate more RAM |
| Network access fails | DNS issue | `adb shell settings put global captive_portal_mode 0` |

## Build + run from source

For native Gradle projects:

```bash
./gradlew installDebug
adb shell am start -n com.example/.MainActivity
```

For Maestro flows:

```bash
maestro test flow.yaml --device emulator-5554
```

## Expo / React Native on Android

```bash
npx expo start --android       # boots emulator, installs Expo Go, opens
npx expo run:android           # dev client build

# Or with RN CLI
npx react-native run-android
```

Expo dev menu shortcuts:
- `r` — reload
- `m` — toggle dev menu
- Shake device or `⌘M` (`Ctrl+M` on Linux) — opens menu

## Multi-device sweep

For responsive testing across phone / tablet:

```bash
for avd in Pixel_8_API_34 Pixel_Tablet_API_34 Small_Phone_API_30; do
  adb -s emulator-5554 emu kill 2>/dev/null
  emulator @$avd -no-snapshot-load &
  sleep 15
  adb wait-for-device
  ./gradlew installDebug
  adb shell am start -n com.example/.MainActivity
  sleep 3
  adb exec-out screencap -p > "recordings/${avd}.png"
done
```

## See also

- `platforms/expo.md` — Expo-specific notes
- `playbooks/golden-path.md` — Canonical golden-path flow
- `mcps/manifest.json` — MCP registry
