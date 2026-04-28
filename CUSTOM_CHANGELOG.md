# CUSTOM_CHANGELOG.md

Fork-specific changelog for local customizations and sync history.
This file is intentionally separate from upstream `CHANGELOG.md`.

## Tracked Customizations

- Canonical preserved file list:
  - `scripts/customization-manifest.sh`
- Image attachment lightbox:
  - `packages/app/src/components/attachment-image-preview-modal.tsx`
  - `packages/app/src/components/message.tsx`
  - `packages/app/src/lib/overlay-root.ts`
- Orchestration behavior/config:
  - `AGENTS.md`
  - `orchestrate.json`
  - `LESSONS.md`
- Local maintenance utilities:
  - `scripts/verify-customizations.sh`
  - `scripts/update-upstream-preserve-custom.sh`
  - `scripts/update-upstream-install-app.sh`

## 2026-04-28 - One-Shot Latest-Version Installer

- Added `scripts/update-upstream-install-app.sh` and npm aliases:
  - `npm run update:latest:install`
  - `npm run update:latest:install:no-push`
- New workflow performs upstream sync + desktop rebuild + `/Applications/Paseo.app` replacement in one command, so About version updates in the same run.

## 2026-04-17 - Baseline Established

- Added one-command upstream sync script with customization-preserving conflict handling.
- Added dedicated fork changelog (`CUSTOM_CHANGELOG.md`) so custom history is not mixed with upstream app releases.

## 2026-04-23 - Upstream Sync (v0.1.61-beta.1)

- Synced local `main` with `upstream/main` (`ce6393a9`).
- Dropped `packages/app/src/components/message-input.tsx` from the fork-owned customization list because upstream now ships the composer attachment/lightbox stack natively.
- Kept the fork-owned user-message image preview overlay in `packages/app/src/components/message.tsx`, `packages/app/src/components/attachment-image-preview-modal.tsx`, and `packages/app/src/lib/overlay-root.ts`.
- Verification executed:
  - `npm run verify:customizations`
  - `npm run build --workspace=@getpaseo/server`
  - `npm run typecheck`

## 2026-04-23 - Removed Fork Message Image Preview Overlay

- Reverted `packages/app/src/components/message.tsx` back to upstream behavior so message image previews now match upstream exactly.
- Removed the fork-only `packages/app/src/components/attachment-image-preview-modal.tsx` overlay.
- Kept `packages/app/src/lib/overlay-root.ts` because it is still used by other overlay components.
  - `npm run build:web --workspace=@getpaseo/app`
  - `./scripts/sync-installed-app-customizations.sh --no-build-web`
