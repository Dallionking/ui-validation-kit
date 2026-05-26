# Maestro Starter Pack

Three ready-to-customize Maestro flows for mobile apps. Drop-in starting point for cross-platform validation.

## Why Maestro?

- **Cross-platform** — one YAML runs on iOS Simulator AND Android emulator
- **Declarative** — easier to maintain than imperative XCUITest / Espresso
- **Accessibility-first** — works with `accessibilityLabel` / content-description, not pixel coords
- **CI-friendly** — easy to integrate with GitHub Actions, GitLab CI

## Setup

```bash
# Install
curl -Ls "https://get.maestro.mobile.dev" | bash

# Verify
maestro --version
```

## Files

| File | What it tests |
|---|---|
| `templates/login.yaml` | Login flow — email/password entry, submit, land on home |
| `templates/navigation.yaml` | Primary nav sweep — every top-level tab, return to home |
| `templates/settings.yaml` | Settings interactions — toggles, list selections, scroll |

## Customization

1. Copy a template to your project's `.maestro/` directory
2. Update `appId` to match your bundle ID / package name
3. Update tab labels, button IDs, and credentials
4. Run: `maestro test .maestro/login.yaml`

## Running on specific devices

```bash
# iOS
maestro test --device "iPhone 16" .maestro/login.yaml

# Android
maestro test --device emulator-5554 .maestro/login.yaml

# Auto-pick first available device
maestro test .maestro/login.yaml
```

## Environment variables

Templates use these env vars (with sensible defaults):

```bash
export MAESTRO_APP_ID=com.yourcompany.yourapp
export TEST_EMAIL=test@yourapp.com
export TEST_PASSWORD=YourTestPassword!

maestro test .maestro/login.yaml
```

## Continuous integration

Add to GitHub Actions (`.github/workflows/maestro.yml`):

```yaml
name: Maestro UI tests
on: [pull_request]
jobs:
  ios:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - run: curl -Ls 'https://get.maestro.mobile.dev' | bash
      - run: ~/.maestro/bin/maestro test .maestro/login.yaml
        env:
          TEST_EMAIL: ${{ secrets.TEST_EMAIL }}
          TEST_PASSWORD: ${{ secrets.TEST_PASSWORD }}
```

## When to use Maestro vs the kit's MCPs

- **Maestro** — when you want REPEATABLE flows that live in git, run in CI, and serve as regression tests
- **Kit MCPs** (ios-simulator-mcp, mobile-mcp) — when you want EXPLORATORY validation driven by an agent, with fix-in-flight capability

Use both. Maestro for the contract; MCPs for the conversation.

## See also

- [Maestro docs](https://docs.maestro.dev)
- [Maestro Studio](https://docs.maestro.dev/maestro-studio) — visual flow recorder
- `../playbooks/golden-path.md` — How the kit uses Maestro within a validation run
