# iOS Platform Reference

How the UI Validation Kit drives iOS Simulator. Read this when validating native SwiftUI/UIKit apps or Expo/RN running on iOS.

## Tooling stack

| Tier | Tool | What it covers |
|---|---|---|
| **Primary** | [`agent-device`](https://github.com/callstackincubator/agent-device) (Callstack) | One CLI: taps, snapshots with `@eN` refs, screenshots, video, logs, network, replay scripts |
| Flow runner | [Maestro](https://maestro.dev) + [Maestro Viewer](https://maestro.dev) (CLI 2.6.0+) | Declarative YAML flows; Viewer puts a live device inside the agent |
| Raw | `xcrun simctl` (built-in with Xcode) | Status bar override, push, permissions, addmedia, boot/install/launch |
| Fallback MCP | [`joshuayoes/ios-simulator-mcp`](https://github.com/joshuayoes/ios-simulator-mcp) | If agent-device unavailable. Requires Facebook IDB. |
| Fallback MCP | [`cameroncooke/XcodeBuildMCP`](https://github.com/cameroncooke/XcodeBuildMCP) | Build/install/launch fallback when agent-device's session can't bootstrap |
| Fallback MCP | [`mobile-next/mobile-mcp`](https://github.com/mobile-next/mobile-mcp) | Unified iOS + Android fallback |

## Prerequisites

```bash
# 1. Xcode + command-line tools
xcode-select -p || xcode-select --install

# 2. agent-device (primary — covers iOS + Android + TV + desktop)
npm install -g agent-device@latest
agent-device --version

# 3. Maestro (declarative flows + Maestro Viewer for live device-in-agent)
curl -Ls 'https://get.maestro.mobile.dev' | bash

# 4. List available simulators
xcrun simctl list devices available

# 5. (Fallback only) Facebook IDB — required by ios-simulator-mcp
# brew tap facebook/fb && brew install idb-companion
```

## `agent-device` cheat sheet (primary path)

```bash
# Discover and open
agent-device apps --platform ios               # list installable apps
agent-device open SampleApp --platform ios     # open on simulator

# Inspect (token-efficient, returns @eN refs)
agent-device snapshot -i                       # interactive elements only

# Interact
agent-device tap @e2
agent-device fill @e3 "test@example.com"
agent-device swipe up
agent-device wait 1000

# Capture evidence
agent-device screenshot ./artifacts/home.png
agent-device record start ./artifacts/run.mp4
agent-device record stop
agent-device logs --since 30s

# Replay
agent-device record session > flow.ad          # records a session as .ad script
agent-device replay flow.ad                    # replays it (CI-friendly)

# React Native introspection
agent-device react components @e2              # inspect props/state

# Session lifecycle
agent-device close
```

For everything `agent-device` can't do (status bar override, push notifications, pre-grant permissions), drop down to `xcrun simctl` below.

## `xcrun simctl` cheat sheet

The literal string `booted` always targets the currently-booted simulator. Use it instead of UDIDs.

```bash
# Lifecycle
xcrun simctl list devices               # enumerate
xcrun simctl boot <UDID>                # boot specific
xcrun simctl shutdown booted            # shut down current
xcrun simctl erase booted               # factory reset

# App lifecycle
xcrun simctl install booted /path/App.app
xcrun simctl uninstall booted com.example.app
xcrun simctl launch booted com.example.app
xcrun simctl terminate booted com.example.app

# Capture
xcrun simctl io booted screenshot out.png
xcrun simctl io booted recordVideo out.mp4   # ^C to stop

# Useful for clean screenshots
xcrun simctl status_bar booted override \
  --time 9:41 --batteryLevel 100 --cellularBars 4 --wifiBars 3

# Seed photo library, contacts, etc
xcrun simctl addmedia booted ./test-image.png

# Test push notifications
xcrun simctl push booted com.example.app apns.json

# Grant permissions (no prompt)
xcrun simctl privacy booted grant camera com.example.app
xcrun simctl privacy booted grant photos com.example.app
xcrun simctl privacy booted grant location com.example.app

# Logs (filter by app)
xcrun simctl spawn booted log show --predicate \
  'process == "MyApp"' --last 30s --info
```

## Interaction patterns

### Tap a button by accessibility label

Use `ios-simulator-mcp.ui_find_element` to get the ref, then `ui_tap`. **Never** brute-force pixel coordinates — accessibility refs are token-efficient and stable across screen sizes.

### Find elements

```
ios_simulator.ui_find_element({
  type: "Button",
  label: "Sign In"
})
→ returns ref like "@e3"

ios_simulator.ui_tap("@e3")
```

### Wait for state change

Native iOS animations take 250–400ms (default timing curves) plus your own delays. Sleep at least 500ms after a tap before re-snapshotting.

```bash
sleep 0.6
xcrun simctl io booted screenshot after-tap.png
```

### Handle modals + sheets

iOS sheets are a separate accessibility scope. Re-snapshot after a sheet appears — your previous element refs may be stale.

### Permissions dialogs

Two strategies:
1. **Pre-grant** with `xcrun simctl privacy booted grant` before launch (clean, deterministic)
2. **Tap through** in the validation run (more realistic, slower)

Choose pre-grant for golden-path runs. Tap through for full validation.

### Keyboard

```
ios_simulator.ui_type("hello world")     # types into focused field
ios_simulator.ui_key("return")            # submit
```

Or via simctl:
```bash
xcrun simctl io booted input keyboard "hello world"
```

## Common gotchas

| Symptom | Cause | Fix |
|---|---|---|
| Simulator doesn't boot | Stuck simulator process | `killall Simulator; xcrun simctl shutdown all` |
| `ios-simulator-mcp` errors on launch | IDB missing | `brew install idb-companion` |
| Screenshot is black | App still loading / display sleep | Wait 1s after launch; ensure simulator window is open |
| Accessibility refs change between runs | View hierarchy rebuilt | Snapshot fresh after each navigation |
| App crashes silently | Check device console | `xcrun simctl spawn booted log show --last 1m` |
| Push notifications don't fire | Wrong bundle ID in apns.json | Bundle ID must match exactly |
| Status bar shows real time | Not overridden | Run `status_bar override --time 9:41` after boot |

## Build + run from source

For native Xcode projects:

```bash
# Build to simulator
xcodebuild -project MyApp.xcodeproj \
  -scheme MyApp \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -derivedDataPath /tmp/derived \
  build

# Find the .app
APP=$(find /tmp/derived/Build/Products -name "MyApp.app" | head -1)

# Install + launch
xcrun simctl install booted "$APP"
xcrun simctl launch booted com.example.MyApp
```

Or use XcodeBuildMCP's `xcodebuild_build` + `install` tools — they handle path resolution.

## Expo / React Native on iOS

Expo handles install + launch automatically:

```bash
npx expo start --ios          # boots sim, installs Expo Go, opens app
# OR for a dev client
npx expo run:ios
```

The kit treats Expo iOS runs the same as native iOS for validation — same `simctl` commands, same MCP tools, same accessibility queries.

Expo dev menu shortcuts (when shaking device or `⌘D` in simulator):
- `r` — reload
- `i` — toggle Element Inspector
- `m` — toggle dev menu

## Multi-device sweep

For responsive testing, boot multiple simulators in sequence:

```bash
for device in "iPhone SE (3rd generation)" "iPhone 16" "iPhone 16 Pro Max" "iPad Pro (12.9-inch) (6th generation)"; do
  xcrun simctl shutdown booted 2>/dev/null
  UDID=$(xcrun simctl list devices available | grep "$device" | head -1 | grep -oE '[0-9A-F-]{36}')
  xcrun simctl boot "$UDID"
  open -a Simulator
  sleep 5
  xcrun simctl install booted "$APP"
  xcrun simctl launch booted com.example.MyApp
  sleep 2
  xcrun simctl io booted screenshot "recordings/${device// /-}.png"
done
```

## See also

- `platforms/expo.md` — Expo-specific dev client notes
- `playbooks/golden-path.md` — Canonical golden-path flow
- `mcps/manifest.json` — MCP registry
