# Example: Validating an iOS SwiftUI App

A real-world example of the kit running against a SwiftUI app. Shows what the input prompt, tool calls, and output report look like.

## Setup

```
.
├── Package.swift
├── MyApp.xcodeproj/
├── MyApp/
│   ├── ContentView.swift
│   ├── DashboardView.swift
│   └── SettingsView.swift
└── recordings/        # created by the kit
```

## User prompt

```
Validate the home screen of MyApp and click through to dashboard and settings.
```

## What the agent does

### 1. Detect platform
```
$ ls *.xcodeproj 2>/dev/null
MyApp.xcodeproj
→ Platform detected: ios-native
```

### 2. Boot simulator
```
$ xcrun simctl list devices | grep -i booted
→ No simulator booted

$ open -a Simulator
$ xcrun simctl boot "iPhone 16 Pro"
→ Simulator booted
```

### 3. Build + install
```
$ xcodebuild -project MyApp.xcodeproj -scheme MyApp \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
    -derivedDataPath /tmp/derived build
→ ✅ Build succeeded

$ APP=$(find /tmp/derived/Build/Products -name "MyApp.app" | head -1)
$ xcrun simctl install booted "$APP"
$ xcrun simctl launch booted com.example.MyApp
→ App launched
```

### 4. Capture initial state
```
$ mkdir -p recordings/ios-native-2026-05-26-1543
$ xcrun simctl status_bar booted override --time 9:41 --batteryLevel 100
$ xcrun simctl io booted screenshot recordings/ios-native-2026-05-26-1543/00-home.png
$ xcrun simctl io booted recordVideo recordings/ios-native-2026-05-26-1543/run.mp4 &
```

### 5. Snapshot home
```
[ios-simulator-mcp.ui_find_element]
{
  "elements": [
    { "ref": "@e1", "type": "Button", "label": "Dashboard" },
    { "ref": "@e2", "type": "Button", "label": "Settings" },
    { "ref": "@e3", "type": "Button", "label": "Profile" }
  ]
}
```

### 6. Click-through Dashboard
```
[ios-simulator-mcp.ui_tap("@e1")]
→ ✅ Tapped Dashboard

[sleep 0.6]
[xcrun simctl io booted screenshot recordings/.../01-dashboard.png]
[ios-simulator-mcp.ui_find_element]
→ Dashboard screen loaded with stats card, "Create New" button
```

### 7. Test Dashboard interaction
```
[ios-simulator-mcp.ui_tap("Create New")]
→ Modal opened
[screenshot: 02-create-modal.png]
[ios-simulator-mcp.ui_tap("Cancel")]
→ Modal dismissed
```

### 8. Back to home, click Settings
```
[ios-simulator-mcp.ui_tap back gesture]
[sleep 0.6]
[ui_tap("@e2")]
→ Settings screen loaded

[screenshot: 03-settings.png]
[ui_find_element]
→ Theme toggle, Notifications toggle, About link
```

### 9. Test theme toggle
```
[ui_tap("Theme")]
→ ❌ NOTHING HAPPENED
```

### 10. Triage
```
[Read SettingsView.swift]
→ ThemeToggle component exists, has @State binding but no onChange handler
→ Cost tier: CHEAP (single file, add handler)

[Edit SettingsView.swift:42]
+ .onChange(of: isDarkMode) { _, new in
+   colorScheme = new ? .dark : .light
+ }

[Reload via Xcode preview or rebuild]
[ui_tap("Theme")]
→ ✅ Theme toggled
```

### 11. Wrap up
```
[xcrun simctl io booted recordVideo stop]
[xcrun simctl status_bar booted clear]
```

## Output report

```markdown
# UI Validation Report

**Project:** MyApp
**Platform:** ios-native
**Device:** iPhone 16 Pro (iOS 26.2)
**Date:** 2026-05-26T15:43:00-04:00
**Recording:** `recordings/ios-native-2026-05-26-1543/run.mp4`

## Verdict: **PASS WITH ONE FIX**

## Navigation Paths Tested
| # | From → To | Method | Result | Evidence |
|---|---|---|---|---|
| 1 | Launch → Home | App launch | PASS | `00-home.png` |
| 2 | Home → Dashboard | Tap "Dashboard" button | PASS | `01-dashboard.png` |
| 3 | Dashboard → Modal | Tap "Create New" | PASS | `02-create-modal.png` |
| 4 | Home → Settings | Tap "Settings" button | PASS | `03-settings.png` |

## Interactive Elements
| Screen | Element | Action | Result |
|---|---|---|---|
| Dashboard | "Create New" button | Tap | PASS — modal opened |
| Settings | Theme toggle | Tap | FAIL → FIXED |

## Fixes Applied In-Flight
| # | File | Change | Tier | Reason |
|---|---|---|---|---|
| 1 | `MyApp/SettingsView.swift:42` | Added `.onChange` handler to ThemeToggle | cheap | State binding existed but no side effect |

## Console Errors
None detected.

## Responsive
| Device | Layout | Issues |
|---|---|---|
| iPhone 16 Pro | PASS | None |
| iPhone SE (3rd gen) | PASS | None |
| iPad Pro 12.9 | PASS WITH CAVEATS | Settings list has unused right space — consider split view |

## Remaining Concerns
- Settings screen could use NavigationSplitView on iPad for better space usage (not fixed — design decision)
```

## Time

- Total run: ~90 seconds
- Build: 45s
- Validation: 35s
- Report generation: 10s

## What this example demonstrates

1. **Platform detection** — `.xcodeproj` present → iOS native path
2. **Status bar override** — clean screenshots with 9:41 time
3. **Cheap fix in-flight** — single-file SwiftUI handler addition
4. **Click-through discipline** — every navigation via tap, never deep-link
5. **Responsive sweep** — iPhone SE / 16 Pro / iPad Pro
6. **Caveat reporting** — iPad layout flagged but not auto-fixed (design decision)
