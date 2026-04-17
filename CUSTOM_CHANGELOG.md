# CUSTOM_CHANGELOG.md

Fork-specific changelog for local customizations and sync history.
This file is intentionally separate from upstream `CHANGELOG.md`.

## Tracked Customizations

- Image attachment lightbox:
  - `packages/app/src/components/attachment-image-preview-modal.tsx`
  - `packages/app/src/components/message-input.tsx`
  - `packages/app/src/components/message.tsx`
  - `packages/app/src/lib/overlay-root.ts`
- Orchestration behavior/config:
  - `orchestrate.json`
  - `LESSONS.md`
- Local maintenance utilities:
  - `scripts/verify-customizations.sh`
  - `scripts/update-upstream-preserve-custom.sh`

## 2026-04-17 - Baseline Established

- Added one-command upstream sync script with customization-preserving conflict handling.
- Added dedicated fork changelog (`CUSTOM_CHANGELOG.md`) so custom history is not mixed with upstream app releases.
