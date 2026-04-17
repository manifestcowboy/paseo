#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

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

check_contains "packages/app/src/components/message-input.tsx" "AttachmentImagePreviewModal" "composer imports lightbox modal"
check_contains "packages/app/src/components/message-input.tsx" "previewedImageIndex" "composer tracks preview image state"
check_contains "packages/app/src/components/message.tsx" "AttachmentImagePreviewModal" "message renderer imports lightbox modal"
check_contains "packages/app/src/components/message.tsx" "setPreviewedImageIndex" "message renderer opens image preview"
check_contains "packages/app/src/components/attachment-image-preview-modal.tsx" "getOverlayRoot" "lightbox renders via overlay root"
check_contains "LESSONS.md" "## Our Customizations in This Fork" "lessons file keeps customization playbook"
check_contains "LESSONS.md" "## Rebuild Server Dist After Upstream Sync" "lessons file keeps sync rebuild rule"

if [[ "$missing" -ne 0 ]]; then
  echo ""
  echo "Customization verification failed."
  exit 1
fi

echo ""
echo "Customization verification passed."
