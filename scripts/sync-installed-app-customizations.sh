#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

APP_PATH="/Applications/Paseo.app"
BUILD_WEB=1
OPEN_AFTER_SYNC=0

usage() {
  cat <<'EOF'
Usage: ./scripts/sync-installed-app-customizations.sh [options]

Options:
  --app-path <path>   Override the installed Paseo.app path
  --no-build-web      Reuse the existing packages/app/dist bundle
  --open              Open Paseo after syncing
  -h, --help          Show this help

What it does:
  1) Builds the current web bundle from this repo (unless --no-build-web)
  2) Stops the installed Paseo app if it is running
  3) Syncs packages/app/dist into Paseo.app/Contents/Resources/app-dist
  4) Relaunches the installed app if it was running before, or if --open is passed
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-path)
      APP_PATH="$2"
      shift 2
      ;;
    --no-build-web)
      BUILD_WEB=0
      shift
      ;;
    --open)
      OPEN_AFTER_SYNC=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

APP_RESOURCES_DIR="$APP_PATH/Contents/Resources"
SOURCE_APP_DIST="$REPO_ROOT/packages/app/dist"
TARGET_APP_DIST="$APP_RESOURCES_DIR/app-dist"

if [[ ! -d "$APP_PATH" ]]; then
  echo "[info] Installed app not found at $APP_PATH. Skipping installed app sync."
  exit 0
fi

if [[ "$BUILD_WEB" -eq 1 ]]; then
  echo "[info] Building current web bundle..."
  npm run build:web --workspace=@getpaseo/app
fi

if [[ ! -f "$SOURCE_APP_DIST/index.html" ]]; then
  echo "[error] Missing built web bundle at $SOURCE_APP_DIST. Run build:web first." >&2
  exit 1
fi

APP_WAS_RUNNING=0
if pgrep -f "$APP_PATH/Contents/MacOS/Paseo" >/dev/null 2>&1; then
  APP_WAS_RUNNING=1
fi

echo "[info] Stopping installed Paseo app..."
osascript -e 'quit app "Paseo"' >/dev/null 2>&1 || true
sleep 2
pkill -f "$APP_PATH/Contents/MacOS/Paseo" >/dev/null 2>&1 || true
sleep 1

echo "[info] Syncing customized app-dist into installed app..."
mkdir -p "$TARGET_APP_DIST"
rsync -a --delete "$SOURCE_APP_DIST/" "$TARGET_APP_DIST/"

if ! cmp -s "$SOURCE_APP_DIST/index.html" "$TARGET_APP_DIST/index.html"; then
  echo "[error] Installed app index.html does not match the local build after sync." >&2
  exit 1
fi

echo "[ok] Installed app now uses the current customized app-dist."

if [[ "$APP_WAS_RUNNING" -eq 1 || "$OPEN_AFTER_SYNC" -eq 1 ]]; then
  echo "[info] Reopening installed Paseo app..."
  open -a "$APP_PATH"
fi
