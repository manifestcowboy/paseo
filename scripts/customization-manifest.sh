#!/usr/bin/env bash

# Canonical list of fork-owned files that must survive upstream syncs.
# Keep this list narrow and intentional.
#
# When adding a new fork-only customization:
# 1) Add every owned file path here.
# 2) Update CUSTOM_CHANGELOG.md with the customization/change.
# 3) Extend scripts/verify-customizations.sh if new behavior needs explicit checks.

CUSTOM_FILES=(
  "AGENTS.md"
  "LESSONS.md"
  "orchestrate.json"
  "CUSTOM_DESKTOP_WORKFLOW.md"
  "CUSTOM_CHANGELOG.md"
  "packages/app/src/components/attachment-image-preview-modal.tsx"
  "packages/app/src/components/message-input.tsx"
  "packages/app/src/components/message.tsx"
  "packages/app/src/lib/overlay-root.ts"
  "scripts/customization-manifest.sh"
  "scripts/verify-customizations.sh"
  "scripts/sync-installed-app-customizations.sh"
  "pr-notes/PR_NOTES_IMAGE_LIGHTBOX_AND_OPENCODE_ANTIGRAVITY.md"
)
