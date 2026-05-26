#!/usr/bin/env bash
# Records a real UI Validation Kit run against the bundled demo/sample-app.
# Produces demo/demo.gif (or .webm) showing the kit driving the demo app
# click-through, screenshotting, and reporting.
#
# Requirements:
#   - agent-browser   (npm i -g agent-browser  OR  brew install agent-browser)
#   - python3         (for http.server)
#   - ffmpeg          (for WebM → GIF conversion)
#
# Usage:
#   bash demo/record/record-demo.sh
#
# Output:
#   demo/demo.webm   (raw recording)
#   demo/demo.gif    (compressed for README embed)
#   demo/screenshots/*.png

set -eo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DIR="$REPO_ROOT/demo/sample-app"
OUT_DIR="$REPO_ROOT/demo"
SHOTS_DIR="$OUT_DIR/screenshots"
PORT="${DEMO_PORT:-8765}"

mkdir -p "$SHOTS_DIR"

# Tools check
command -v agent-browser >/dev/null || { echo "agent-browser not installed"; exit 1; }
command -v python3 >/dev/null || { echo "python3 not installed"; exit 1; }

# 1. Start the sample app server
echo "▸ Starting sample app on port $PORT"
( cd "$APP_DIR" && python3 -m http.server "$PORT" >/dev/null 2>&1 ) &
SERVER_PID=$!
trap "kill $SERVER_PID 2>/dev/null" EXIT
sleep 1

# 2. Open browser, start recording
echo "▸ Opening browser, starting recording"
agent-browser open "http://localhost:$PORT"
agent-browser set viewport 1280 720
agent-browser record start "$OUT_DIR/demo.webm"
sleep 1

# 3. Click-through demo
echo "▸ Click-through demo flow"
agent-browser screenshot "$SHOTS_DIR/01-home.png"
sleep 1

agent-browser snapshot -i
agent-browser click 'a[data-route="dashboard"]'
sleep 1
agent-browser screenshot "$SHOTS_DIR/02-dashboard.png"

agent-browser click '#create-new'
sleep 1
agent-browser screenshot "$SHOTS_DIR/03-modal-open.png"

agent-browser click '.modal button.primary'
sleep 1
agent-browser screenshot "$SHOTS_DIR/04-modal-closed.png"

agent-browser click 'a[data-route="settings"]'
sleep 1
agent-browser screenshot "$SHOTS_DIR/05-settings.png"

agent-browser click '#theme-toggle'
sleep 1
agent-browser screenshot "$SHOTS_DIR/06-toggled.png"

agent-browser click 'a[data-route="home"]'
sleep 1
agent-browser screenshot "$SHOTS_DIR/07-back-home.png"

# 4. Stop recording
echo "▸ Stopping recording"
agent-browser record stop
agent-browser close

# 5. Convert WebM → GIF
if command -v ffmpeg >/dev/null; then
  echo "▸ Converting WebM → GIF"
  ffmpeg -y -i "$OUT_DIR/demo.webm" \
    -vf "fps=12,scale=720:-1:flags=lanczos" \
    -loop 0 "$OUT_DIR/demo.gif" 2>&1 | tail -5
  echo "✓ GIF: $OUT_DIR/demo.gif ($(du -h "$OUT_DIR/demo.gif" | cut -f1))"
else
  echo "ffmpeg not installed, skipping GIF conversion"
fi

echo "▸ Done. Screenshots in $SHOTS_DIR, video at $OUT_DIR/demo.webm"
