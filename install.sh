#!/usr/bin/env bash
# UI Validation Kit — installer
#
# Auto-detects your agent harness (Claude Code, Codex CLI, Cursor) and
# project platform stack (iOS, Android, Expo, RN, web), then installs:
#   - The ui-validation skill
#   - The qa-validator sub-agent
#   - Platform-appropriate MCPs and CLI tools
#
# Usage:
#   bash install.sh                  # auto-detect everything, project scope
#   bash install.sh --global         # user scope (~/.claude, ~/.codex, ~/.cursor)
#   bash install.sh --target=claude  # only install for one harness
#   bash install.sh --dry-run        # show what would happen
#   bash install.sh --uninstall      # remove everything
#   bash install.sh --force          # skip prompts
#
# Env:
#   INSTALL_TARGET=auto|claude|codex|cursor|all  (default: auto)
#   KIT_REPO_URL=https://...                     (override clone source)

set -eo pipefail
# Note: we deliberately omit `-u` because empty arrays + bash 3.2 trigger spurious unbound errors.

# ───────────────────────────────────────────────────────────────────────
# Config
# ───────────────────────────────────────────────────────────────────────

KIT_VERSION="0.1.0"
KIT_REPO_URL="${KIT_REPO_URL:-https://github.com/Dallionking/ui-validation-kit}"
KIT_BRANCH="${KIT_BRANCH:-main}"
INSTALL_TARGET="${INSTALL_TARGET:-auto}"

SCOPE="project"
DRY_RUN=0
UNINSTALL=0
FORCE=0
INSTALL_FALLBACK_MCPS="${INSTALL_FALLBACK_MCPS:-0}"
KIT_DIR=""

# ───────────────────────────────────────────────────────────────────────
# Logging
# ───────────────────────────────────────────────────────────────────────

C_RESET="\033[0m"; C_DIM="\033[2m"; C_BOLD="\033[1m"
C_GREEN="\033[32m"; C_YELLOW="\033[33m"; C_RED="\033[31m"; C_BLUE="\033[34m"

log()   { printf "${C_DIM}[ui-kit]${C_RESET} %s\n" "$*"; }
info()  { printf "${C_BLUE}[i]${C_RESET} %s\n" "$*"; }
ok()    { printf "${C_GREEN}[✓]${C_RESET} %s\n" "$*"; }
warn()  { printf "${C_YELLOW}[!]${C_RESET} %s\n" "$*"; }
err()   { printf "${C_RED}[✗]${C_RESET} %s\n" "$*" >&2; }
step()  { printf "\n${C_BOLD}▸ %s${C_RESET}\n" "$*"; }

run() {
  if [[ $DRY_RUN -eq 1 ]]; then
    printf "${C_DIM}[dry-run]${C_RESET} %s\n" "$*"
  else
    eval "$@"
  fi
}

# ───────────────────────────────────────────────────────────────────────
# Arg parsing
# ───────────────────────────────────────────────────────────────────────

for arg in "$@"; do
  case "$arg" in
    --global)            SCOPE="global" ;;
    --project)           SCOPE="project" ;;
    --dry-run)           DRY_RUN=1 ;;
    --uninstall)         UNINSTALL=1 ;;
    --force)             FORCE=1 ;;
    --target=*)          INSTALL_TARGET="${arg#--target=}" ;;
    --include-fallback-mcps) INSTALL_FALLBACK_MCPS=1 ;;
    -h|--help)
      sed -n '2,20p' "$0"; exit 0 ;;
    *)
      err "Unknown flag: $arg"; exit 1 ;;
  esac
done

# ───────────────────────────────────────────────────────────────────────
# Harness detection
# ───────────────────────────────────────────────────────────────────────

claude_detected() { command -v claude >/dev/null 2>&1 || [[ -d "$HOME/.claude" ]]; }
codex_detected()  { command -v codex  >/dev/null 2>&1 || [[ -d "$HOME/.codex"  ]]; }
cursor_detected() { [[ -d "$HOME/.cursor" ]] || [[ -d "$HOME/Library/Application Support/Cursor" ]]; }

declare -a TARGETS=()
if [[ "$INSTALL_TARGET" == "auto" ]]; then
  claude_detected && TARGETS+=("claude")
  codex_detected  && TARGETS+=("codex")
  cursor_detected && TARGETS+=("cursor")
elif [[ "$INSTALL_TARGET" == "all" ]]; then
  TARGETS=("claude" "codex" "cursor" "generic")
else
  IFS=',' read -ra TARGETS <<< "$INSTALL_TARGET"
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  warn "No supported agent harness detected. Falling back to generic AGENTS.md install."
  TARGETS=("generic")
fi

# ───────────────────────────────────────────────────────────────────────
# Platform detection
# ───────────────────────────────────────────────────────────────────────

detect_platforms() {
  local platforms=()

  # iOS native
  if compgen -G "*.xcodeproj" > /dev/null || [[ -f "Package.swift" ]]; then
    platforms+=("ios")
  fi

  # Android native
  if [[ -f "build.gradle" ]] || [[ -f "build.gradle.kts" ]] || [[ -f "settings.gradle" ]]; then
    platforms+=("android")
  fi

  # Expo
  if [[ -f "app.json" ]] && grep -q '"expo"' app.json 2>/dev/null; then
    platforms+=("expo")
  elif [[ -f "app.config.js" ]] || [[ -f "app.config.ts" ]]; then
    platforms+=("expo")
  fi

  # React Native (non-Expo)
  if [[ -f "package.json" ]] && grep -q '"react-native"' package.json 2>/dev/null; then
    if [[ ! " ${platforms[*]} " =~ " expo " ]]; then
      platforms+=("react-native")
    fi
  fi

  # Web
  if [[ -f "package.json" ]] && grep -qE '"(next|react|vite|astro|remix|svelte|solid|nuxt|@angular)"' package.json 2>/dev/null; then
    platforms+=("web")
  fi

  printf "%s\n" "${platforms[@]}"
}

declare -a PLATFORMS=()
# Portable replacement for mapfile (not available on macOS bash 3.2)
while IFS= read -r line; do
  [[ -n "$line" ]] && PLATFORMS+=("$line")
done < <(detect_platforms)

if [[ ${#PLATFORMS[@]} -eq 0 ]]; then
  warn "No project platform detected. Installing all platform docs anyway — the agent will detect at runtime."
  PLATFORMS=("ios" "android" "web" "expo")
fi

# ───────────────────────────────────────────────────────────────────────
# Resolve kit source
# ───────────────────────────────────────────────────────────────────────

resolve_kit_dir() {
  # If we're already inside a checkout of the kit, use it
  if [[ -f "skill/SKILL.md" && -f "agent/qa-validator.md" && -f "install.sh" ]]; then
    KIT_DIR="$(pwd)"
    return
  fi

  # Otherwise, clone to a temp dir. In dry-run mode, don't create the tmp dir
  # or clone — just print what would happen and exit.
  if [[ $DRY_RUN -eq 1 ]]; then
    log "DRY RUN: would clone $KIT_REPO_URL → \$(mktemp -d) and use that as kit source."
    log "DRY RUN: To see realistic dry-run output, run from inside a kit checkout."
    exit 0
  fi

  local tmp; tmp="$(mktemp -d -t ui-validation-kit.XXXXXX)"
  log "Cloning $KIT_REPO_URL → $tmp"
  git clone --depth 1 --branch "$KIT_BRANCH" "$KIT_REPO_URL" "$tmp" >/dev/null 2>&1 \
    || { err "Failed to clone kit. Set KIT_REPO_URL or run from inside a checkout."; exit 1; }
  KIT_DIR="$tmp"
}

# ───────────────────────────────────────────────────────────────────────
# Platform tooling install
# ───────────────────────────────────────────────────────────────────────

install_agent_device() {
  if ! command -v agent-device >/dev/null 2>&1; then
    info "Installing agent-device (primary mobile/TV/desktop CLI — Callstack)"
    if command -v npm >/dev/null 2>&1; then
      run "npm install -g agent-device@latest"
    else
      warn "npm not found. Install agent-device manually: npm i -g agent-device"
    fi
  else
    ok "agent-device already installed ($(agent-device --version 2>/dev/null || echo 'version unknown'))"
  fi
}

install_ios_tooling() {
  step "Installing iOS tooling"

  # agent-device and Maestro are platform-agnostic — install them first so an
  # Android-only Expo/RN setup still gets them even when Xcode is missing.
  install_agent_device

  if ! command -v maestro >/dev/null 2>&1; then
    info "Installing Maestro (cross-platform declarative flows + Maestro Viewer)"
    run "curl -Ls 'https://get.maestro.mobile.dev' | bash"
  else
    ok "Maestro already installed"
  fi

  if ! command -v xcode-select >/dev/null 2>&1; then
    warn "Xcode command-line tools not found. iOS-specific control (simctl) unavailable. Run: xcode-select --install"
    return 0
  fi
  ok "Xcode command-line tools available"
}

install_android_tooling() {
  step "Installing Android tooling"

  # Platform-agnostic tools first
  install_agent_device

  if ! command -v maestro >/dev/null 2>&1; then
    info "Installing Maestro"
    run "curl -Ls 'https://get.maestro.mobile.dev' | bash"
  else
    ok "Maestro already installed"
  fi

  if ! command -v adb >/dev/null 2>&1; then
    warn "adb not found. Android-specific control unavailable. Install with: brew install android-platform-tools"
    return 0
  fi
  ok "adb available"
}

install_web_tooling() {
  step "Installing web tooling"
  if ! command -v agent-browser >/dev/null 2>&1; then
    info "Installing agent-browser (Vercel Labs)"
    if command -v npm >/dev/null 2>&1; then
      run "npm install -g agent-browser"
    elif command -v cargo >/dev/null 2>&1; then
      run "cargo install agent-browser"
    else
      warn "Neither npm nor cargo found. Install agent-browser manually: https://github.com/vercel-labs/agent-browser"
    fi
  else
    ok "agent-browser already installed"
  fi
}

# ───────────────────────────────────────────────────────────────────────
# MCP registration
# ───────────────────────────────────────────────────────────────────────

# Reads mcps/manifest.json and returns the relevant MCP entries for a given platform.
# Honors INSTALL_FALLBACK_MCPS — when set, also includes fallback MCPs (e.g. mobile MCPs
# normally not registered because agent-device is primary).
get_mcps_for_platform() {
  local platform="$1"
  python3 - "$KIT_DIR/mcps/manifest.json" "$platform" "$INSTALL_FALLBACK_MCPS" <<'PYEOF'
import json, sys
manifest = json.load(open(sys.argv[1]))
platform, include_fallback = sys.argv[2], sys.argv[3] == "1"
mcps = list(manifest.get("platforms", {}).get(platform, []))
if include_fallback:
    mcps += manifest.get("fallback_mcps", {}).get(platform, [])
for name in mcps:
    if name.startswith("_"):
        continue
    spec = manifest["mcpServers"].get(name)
    if spec:
        # Strip private _-prefixed keys before serializing
        clean = {k: v for k, v in spec.items() if not k.startswith("_")}
        print(f"{name}\t{json.dumps(clean)}")
PYEOF
}

register_mcp_claude() {
  local name="$1"; local spec="$2"
  local cmd; cmd="$(python3 -c "import json,sys; s=json.loads(sys.argv[1]); print(' '.join([s['command']] + s.get('args', [])))" "$spec")"
  if [[ "$SCOPE" == "global" ]]; then
    run "claude mcp add '$name' --scope user -- $cmd"
  else
    run "claude mcp add '$name' --scope project -- $cmd"
  fi
}

register_mcp_codex() {
  local name="$1"; local spec="$2"
  local config="$HOME/.codex/config.toml"
  [[ "$SCOPE" == "project" ]] && config=".codex/config.toml"

  if [[ $DRY_RUN -eq 1 ]]; then
    printf "${C_DIM}[dry-run]${C_RESET} would register Codex MCP '%s' in %s\n" "$name" "$config"
    return
  fi

  mkdir -p "$(dirname "$config")"
  touch "$config"

  # Idempotent append: skip if [mcp_servers.NAME] already present
  if grep -q "^\[mcp_servers\.$name\]" "$config" 2>/dev/null; then
    ok "Codex MCP '$name' already registered"
    return
  fi

  python3 - "$config" "$name" "$spec" <<'PYEOF'
import json, sys
cfg, name, spec_json = sys.argv[1], sys.argv[2], sys.argv[3]
spec = json.loads(spec_json)
with open(cfg, 'a') as f:
    f.write(f"\n[mcp_servers.{name}]\n")
    f.write(f'command = "{spec["command"]}"\n')
    if "args" in spec:
        args_repr = ", ".join(f'"{a}"' for a in spec["args"])
        f.write(f"args = [{args_repr}]\n")
    if "env" in spec:
        f.write(f"env = {json.dumps(spec['env'])}\n")
PYEOF
  ok "Registered Codex MCP: $name"
}

register_mcp_cursor() {
  local name="$1"; local spec="$2"
  local cfg="$HOME/.cursor/mcp.json"
  [[ "$SCOPE" == "project" ]] && cfg=".cursor/mcp.json"

  if [[ $DRY_RUN -eq 1 ]]; then
    printf "${C_DIM}[dry-run]${C_RESET} would register Cursor MCP '%s' in %s\n" "$name" "$cfg"
    return
  fi

  mkdir -p "$(dirname "$cfg")"
  [[ -f "$cfg" ]] || echo '{"mcpServers":{}}' > "$cfg"

  python3 - "$cfg" "$name" "$spec" <<'PYEOF'
import json, sys
path, name, spec_json = sys.argv[1], sys.argv[2], sys.argv[3]
data = json.load(open(path))
data.setdefault("mcpServers", {})[name] = json.loads(spec_json)
json.dump(data, open(path, "w"), indent=2)
PYEOF
  ok "Registered Cursor MCP: $name"
}

# ───────────────────────────────────────────────────────────────────────
# Skill + sub-agent install
# ───────────────────────────────────────────────────────────────────────

install_skill_claude() {
  local base="$HOME/.claude"
  [[ "$SCOPE" == "project" ]] && base=".claude"
  run "mkdir -p '$base/skills/ui-validation' '$base/agents'"
  run "cp '$KIT_DIR/skill/SKILL.md' '$base/skills/ui-validation/SKILL.md'"
  run "cp '$KIT_DIR/agent/qa-validator.md' '$base/agents/qa-validator.md'"
  ok "Claude Code: skill + sub-agent installed to $base"
}

install_skill_codex() {
  local base="."
  [[ "$SCOPE" == "global" ]] && base="$HOME"
  run "mkdir -p '$base/.agents/skills/ui-validation' '$base/.codex/agents'"
  run "cp '$KIT_DIR/skill/SKILL.md' '$base/.agents/skills/ui-validation/SKILL.md'"
  if [[ -f "$KIT_DIR/adapters/codex/agents/qa-validator.toml" ]]; then
    run "cp '$KIT_DIR/adapters/codex/agents/qa-validator.toml' '$base/.codex/agents/qa-validator.toml'"
  fi
  ok "Codex: skill + sub-agent installed to $base/.agents/ and $base/.codex/"
}

install_skill_cursor() {
  local base="."
  [[ "$SCOPE" == "global" ]] && base="$HOME"
  run "mkdir -p '$base/.cursor/rules'"
  if [[ -f "$KIT_DIR/adapters/cursor/rules/ui-validation.mdc" ]]; then
    run "cp '$KIT_DIR/adapters/cursor/rules/ui-validation.mdc' '$base/.cursor/rules/ui-validation.mdc'"
  else
    # Fallback: copy SKILL.md as a rule
    run "cp '$KIT_DIR/skill/SKILL.md' '$base/.cursor/rules/ui-validation.mdc'"
  fi
  ok "Cursor: rule installed to $base/.cursor/rules/"
}

install_skill_generic() {
  if [[ -f "AGENTS.md" ]]; then
    run "cat '$KIT_DIR/adapters/generic/AGENTS.md' >> AGENTS.md"
  else
    run "cp '$KIT_DIR/adapters/generic/AGENTS.md' AGENTS.md"
  fi
  ok "Generic: AGENTS.md updated"
}

# ───────────────────────────────────────────────────────────────────────
# Uninstall
# ───────────────────────────────────────────────────────────────────────

unregister_mcp_claude() {
  local name="$1"
  if [[ "$SCOPE" == "global" ]]; then
    run "claude mcp remove '$name' --scope user 2>/dev/null || true"
  else
    run "claude mcp remove '$name' --scope project 2>/dev/null || true"
  fi
}

unregister_mcp_codex() {
  local name="$1"
  local config="$HOME/.codex/config.toml"
  [[ "$SCOPE" == "project" ]] && config=".codex/config.toml"
  [[ -f "$config" ]] || return 0

  if [[ $DRY_RUN -eq 1 ]]; then
    printf "${C_DIM}[dry-run]${C_RESET} would remove [mcp_servers.%s] from %s\n" "$name" "$config"
    return
  fi

  python3 - "$config" "$name" <<'PYEOF'
import sys, re
cfg, name = sys.argv[1], sys.argv[2]
content = open(cfg).read()
# Strip the block [mcp_servers.NAME] plus its key=value lines until next [ or EOF
pattern = re.compile(r'(^\[mcp_servers\.' + re.escape(name) + r'\][^\[]*?)(?=^\[|\Z)', re.MULTILINE | re.DOTALL)
new = pattern.sub('', content).rstrip() + '\n'
open(cfg, 'w').write(new)
PYEOF
}

unregister_mcp_cursor() {
  local name="$1"
  local cfg="$HOME/.cursor/mcp.json"
  [[ "$SCOPE" == "project" ]] && cfg=".cursor/mcp.json"
  [[ -f "$cfg" ]] || return 0

  if [[ $DRY_RUN -eq 1 ]]; then
    printf "${C_DIM}[dry-run]${C_RESET} would remove '%s' from mcpServers in %s\n" "$name" "$cfg"
    return
  fi

  python3 - "$cfg" "$name" <<'PYEOF'
import json, sys
cfg, name = sys.argv[1], sys.argv[2]
data = json.load(open(cfg))
data.get("mcpServers", {}).pop(name, None)
json.dump(data, open(cfg, "w"), indent=2)
PYEOF
}

do_uninstall() {
  step "Uninstalling UI Validation Kit"

  # All MCP names the kit might have registered
  local mcps=(ios-simulator xcodebuild mobile-mcp playwright chrome-devtools)

  for target in "${TARGETS[@]}"; do
    case "$target" in
      claude)
        local base="$HOME/.claude"; [[ "$SCOPE" == "project" ]] && base=".claude"
        run "rm -rf '$base/skills/ui-validation' '$base/agents/qa-validator.md'"
        for m in "${mcps[@]}"; do unregister_mcp_claude "$m"; done
        ok "Claude Code: skill, sub-agent, and MCP entries removed"
        ;;
      codex)
        local base="."; [[ "$SCOPE" == "global" ]] && base="$HOME"
        run "rm -rf '$base/.agents/skills/ui-validation' '$base/.codex/agents/qa-validator.toml'"
        for m in "${mcps[@]}"; do unregister_mcp_codex "$m"; done
        ok "Codex: skill, sub-agent, and MCP entries removed"
        ;;
      cursor)
        local base="."; [[ "$SCOPE" == "global" ]] && base="$HOME"
        run "rm -f '$base/.cursor/rules/ui-validation.mdc'"
        for m in "${mcps[@]}"; do unregister_mcp_cursor "$m"; done
        ok "Cursor: rule and MCP entries removed"
        ;;
      generic)
        warn "Generic install only appends to AGENTS.md — remove the '## UI Validation Kit' section manually"
        ;;
    esac
  done
  ok "Uninstall complete."
  exit 0
}

# ───────────────────────────────────────────────────────────────────────
# Main
# ───────────────────────────────────────────────────────────────────────

main() {
  printf "${C_BOLD}UI Validation Kit v%s${C_RESET}\n" "$KIT_VERSION"
  log "Targets: ${TARGETS[*]}"
  log "Platforms detected: ${PLATFORMS[*]}"
  log "Scope: $SCOPE"
  [[ $DRY_RUN -eq 1 ]] && warn "DRY RUN — no changes will be made"

  resolve_kit_dir
  log "Kit source: $KIT_DIR"

  [[ $UNINSTALL -eq 1 ]] && do_uninstall

  # Install platform tooling — Expo/RN can target iOS AND Android, install both.
  # Portable dedup (bash 3.2 has no associative arrays — use a space-delimited string).
  local _seen=" "
  for platform in "${PLATFORMS[@]}"; do
    case "$platform" in
      ios)
        case "$_seen" in *" ios "*) ;; *) install_ios_tooling; _seen="$_seen ios " ;; esac
        ;;
      android)
        case "$_seen" in *" android "*) ;; *) install_android_tooling; _seen="$_seen android " ;; esac
        ;;
      expo|react-native|flutter)
        case "$_seen" in *" ios "*) ;; *) install_ios_tooling; _seen="$_seen ios " ;; esac
        case "$_seen" in *" android "*) ;; *) install_android_tooling; _seen="$_seen android " ;; esac
        ;;
      web)
        case "$_seen" in *" web "*) ;; *) install_web_tooling; _seen="$_seen web " ;; esac
        ;;
    esac
  done

  # Register MCPs per platform per target
  step "Registering MCPs"
  for platform in "${PLATFORMS[@]}"; do
    while IFS=$'\t' read -r name spec; do
      [[ -z "$name" ]] && continue
      for target in "${TARGETS[@]}"; do
        case "$target" in
          claude)  register_mcp_claude "$name" "$spec" ;;
          codex)   register_mcp_codex  "$name" "$spec" ;;
          cursor)  register_mcp_cursor "$name" "$spec" ;;
        esac
      done
    done < <(get_mcps_for_platform "$platform")
  done

  # Install skill + sub-agent per target
  step "Installing skill and sub-agent"
  for target in "${TARGETS[@]}"; do
    case "$target" in
      claude)  install_skill_claude ;;
      codex)   install_skill_codex ;;
      cursor)  install_skill_cursor ;;
      generic) install_skill_generic ;;
    esac
  done

  # Summary
  step "Done"
  ok "UI Validation Kit installed for: ${TARGETS[*]}"
  ok "Platforms covered: ${PLATFORMS[*]}"
  echo
  printf "Try it:\n"
  printf "  ${C_BOLD}\"Validate the home screen of this app.\"${C_RESET}\n"
  printf "  ${C_BOLD}\"Click through every button on settings and screenshot each state.\"${C_RESET}\n"
  printf "  ${C_BOLD}\"Run the qa-validator sub-agent in deep mode.\"${C_RESET}\n"
  echo
  printf "Uninstall:\n"
  printf "  ${C_DIM}bash %s --uninstall${C_RESET}\n" "$0"
}

main "$@"
