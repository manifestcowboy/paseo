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

check_contains "packages/app/src/components/message-input.tsx" "AttachmentImagePreviewModal" "composer imports lightbox modal"
check_contains "packages/app/src/components/message-input.tsx" "previewedImageIndex" "composer tracks preview image state"
check_contains "packages/app/src/components/message.tsx" "AttachmentImagePreviewModal" "message renderer imports lightbox modal"
check_contains "packages/app/src/components/message.tsx" "setPreviewedImageIndex" "message renderer opens image preview"
check_contains "packages/app/src/components/attachment-image-preview-modal.tsx" "getOverlayRoot" "lightbox renders via overlay root"
check_contains "AGENTS.md" "update:upstream:preserve" "agents file documents one-command fork update"
check_contains "AGENTS.md" "scripts/customization-manifest.sh" "agents file points to canonical customization manifest"
check_contains "LESSONS.md" "## Our Customizations in This Fork" "lessons file keeps customization playbook"
check_contains "LESSONS.md" "## Installed App Must Be Patched After Upstream Update" "lessons file keeps installed app sync rule"
check_contains "LESSONS.md" "## Rebuild Server Dist After Upstream Sync" "lessons file keeps sync rebuild rule"
check_contains "CUSTOM_CHANGELOG.md" "# CUSTOM_CHANGELOG.md" "custom changelog exists"
check_contains "CUSTOM_CHANGELOG.md" "## Tracked Customizations" "custom changelog tracks fork scope"
check_contains "CUSTOM_DESKTOP_WORKFLOW.md" "scripts/customization-manifest.sh" "workflow doc points to canonical customization manifest"
check_contains "package.json" "\"sync:installed:app\"" "package scripts include installed app sync command"
check_contains "scripts/sync-installed-app-customizations.sh" "rsync -a --delete" "installed app sync script patches app-dist in place"

if [[ "$missing" -ne 0 ]]; then
  echo ""
  echo "Customization verification failed."
  exit 1
fi

echo ""
echo "Customization verification passed."
