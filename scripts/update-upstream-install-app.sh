#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

APP_PATH="/Applications/Paseo.app"
NO_PUSH=0

usage() {
  cat <<'EOF'
Usage: ./scripts/update-upstream-install-app.sh [options]

Options:
  --no-push   Do not push to origin/main after successful update
  -h, --help  Show this help

Workflow:
  1) Ensure dev dependencies are installed (required by upstream tooling)
  2) Run upstream-preserving fork update
  3) Build desktop app from current repo state
  4) Replace installed /Applications/Paseo.app with the freshly built app
  5) Reopen app and print installed version
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-push)
      NO_PUSH=1
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

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "[error] This one-shot installer currently supports macOS only." >&2
  echo "        Use npm run update:upstream:preserve on other platforms." >&2
  exit 1
fi

echo "[info] Installing dependencies with dev tools included..."
npm install --include=dev --workspaces --include-workspace-root --ignore-scripts

if [[ "$NO_PUSH" -eq 0 ]]; then
  echo "[info] Updating fork from upstream and pushing..."
  npm run update:upstream:preserve -- --skip-installed-app-sync
else
  echo "[info] Updating fork from upstream without pushing..."
  npm run update:upstream:preserve -- --no-push --skip-installed-app-sync
fi

echo "[info] Building desktop app..."
npm run build:desktop

SOURCE_APP="$REPO_ROOT/packages/desktop/release/mac-arm64/Paseo.app"
if [[ ! -d "$SOURCE_APP" ]]; then
  echo "[error] Missing built app at $SOURCE_APP" >&2
  exit 1
fi

echo "[info] Replacing installed app at $APP_PATH..."
osascript -e 'quit app "Paseo"' >/dev/null 2>&1 || true
sleep 2
rm -rf "$APP_PATH"
cp -R "$SOURCE_APP" "$APP_PATH"

echo "[info] Verifying installed app version..."
INSTALLED_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist")"
echo "[ok] Installed Paseo version: $INSTALLED_VERSION"

echo "[info] Launching updated app..."
open -a "$APP_PATH"
