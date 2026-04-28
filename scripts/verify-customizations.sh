#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

MANIFEST_PATH="$REPO_ROOT/scripts/customization-manifest.sh"
if [[ ! -f "$MANIFEST_PATH" ]]; then
  echo "[missing] customization manifest ($MANIFEST_PATH)"
  exit 1
fi
source "$MANIFEST_PATH"

missing=0

check_contains() {
  local file="$1"
  local pattern="$2"
  local label="$3"

  if ! rg -q "$pattern" "$file"; then
    echo "[missing] $label ($file)"
    missing=1
  else
    echo "[ok] $label"
  fi
}

for file in "${CUSTOM_FILES[@]}"; do
  if [[ ! -e "$file" ]]; then
    echo "[missing] manifest file entry ($file)"
    missing=1
  else
    echo "[ok] manifest file entry: $file"
  fi
done

check_contains "AGENTS.md" "update:upstream:preserve" "agents file documents one-command fork update"
check_contains "AGENTS.md" "scripts/customization-manifest.sh" "agents file points to canonical customization manifest"
check_contains "LESSONS.md" "## Our Customizations in This Fork" "lessons file keeps customization playbook"
check_contains "LESSONS.md" "## Installed App Must Be Patched After Upstream Update" "lessons file keeps installed app sync rule"
check_contains "LESSONS.md" "## \"Latest Version\" Needs Binary Replace, Not Only app-dist Sync" "lessons file keeps app version replacement rule"
check_contains "LESSONS.md" "## Rebuild Server Dist After Upstream Sync" "lessons file keeps sync rebuild rule"
check_contains "CUSTOM_CHANGELOG.md" "# CUSTOM_CHANGELOG.md" "custom changelog exists"
check_contains "CUSTOM_CHANGELOG.md" "## Tracked Customizations" "custom changelog tracks fork scope"
check_contains "CUSTOM_DESKTOP_WORKFLOW.md" "scripts/customization-manifest.sh" "workflow doc points to canonical customization manifest"
check_contains "package.json" "\"sync:installed:app\"" "package scripts include installed app sync command"
check_contains "package.json" "\"update:latest:install\"" "package scripts include one-shot installed version updater"
check_contains "scripts/sync-installed-app-customizations.sh" "rsync -a --delete" "installed app sync script patches app-dist in place"
check_contains "scripts/update-upstream-install-app.sh" "npm run build:desktop" "one-shot updater rebuilds desktop app"
check_contains "scripts/update-upstream-install-app.sh" 'cp -R "\$SOURCE_APP" "\$APP_PATH"' "one-shot updater replaces installed app bundle"

if [[ "$missing" -ne 0 ]]; then
  echo ""
  echo "Customization verification failed."
  exit 1
fi

echo ""
echo "Customization verification passed."
