# Custom Desktop Workflow (Keep Local Customizations)

This project keeps a few local customizations on top of upstream Paseo. The goal is simple: update upstream, retain those files, and patch the installed `/Applications/Paseo.app` automatically.

## Normal update flow

Run from repo root:

```bash
npm run update:upstream:preserve
```

This is the normal path. It now:

1. Updates your fork from `origin` and `upstream`
2. Preserves the known customization files
3. Verifies the custom code is still present
4. Rebuilds the current web bundle from this repo
5. Patches the installed `/Applications/Paseo.app` in place

No DMG install step is required for routine updates.

## What gets retained

The update flow is intentionally narrow. It keeps the files that matter:

- `packages/app/src/components/attachment-image-preview-modal.tsx`
- `packages/app/src/components/message-input.tsx`
- `packages/app/src/components/message.tsx`
- `packages/app/src/lib/overlay-root.ts`
- `orchestrate.json`
- `LESSONS.md`
- `CUSTOM_CHANGELOG.md`
- `CUSTOM_DESKTOP_WORKFLOW.md`

## Keep customization when updating Paseo

The important distinction is:

- Upstream auto-updates replace the installed app with upstream bits
- Our custom flow reapplies the local renderer customization into the installed app after the code update

Useful variants:

```bash
# run update flow but do not push
npm run update:upstream:preserve:no-push

# skip installed app patching if you only want the repo updated
./scripts/update-upstream-preserve-custom.sh --skip-installed-app-sync

# patch the installed app directly from the current repo state
npm run sync:installed:app
```

## Custom Changelog

Fork customization history is tracked in:

- `CUSTOM_CHANGELOG.md`

This is separate from upstream `CHANGELOG.md`, so your customization notes are not overwritten by upstream release notes.

## DMG artifacts

Desktop artifacts in `packages/desktop/release/` are only for fresh installs or explicit packaging work. They are not required for the normal update flow.

## Practical rule

If the installed app ever looks upstream-clean after an update, run `npm run sync:installed:app`. That reapplies the current repo customizations to `/Applications/Paseo.app` directly.
