# Custom Desktop Workflow (Keep Local Customizations)

This project can ship a desktop app that includes local customizations (like image preview in composer) without requiring the Expo dev server.

## Build a desktop app from this repo (no dev server)

Run from repo root:

```bash
npm run typecheck
npm run build:desktop
```

This produces desktop artifacts from your local source code. You can install/use that build directly.

## Where desktop artifacts are written

Electron builder outputs into:

- `packages/desktop/release/`

Common artifact names include `.dmg` (macOS), `.exe` (Windows), and `.AppImage` (Linux), depending on platform/build settings.

## Keep customization when updating Paseo

Important: official auto-updates install official binaries and will not include your local custom patches unless those patches are merged upstream.

Use the one-command sync script:

```bash
npm run update:upstream:preserve
```

What it does:

1. Ensures clean `main`.
2. Fetches `origin` + `upstream`.
3. Rebases local `main` onto `origin/main`.
4. Merges `upstream/main`.
5. Preserves known customization files on conflict.
6. Runs:
   - `npm run verify:customizations`
   - `npm run build --workspace=@getpaseo/server`
   - `npm run typecheck`
7. Appends upstream sync history to `CUSTOM_CHANGELOG.md`.
8. Pushes to `origin/main`.

Useful variants:

```bash
# run update flow but do not push
npm run update:upstream:preserve:no-push

# direct script call options
./scripts/update-upstream-preserve-custom.sh --no-push --skip-typecheck
```

## Custom Changelog

Fork customization history is tracked in:

- `CUSTOM_CHANGELOG.md`

This is separate from upstream `CHANGELOG.md`, so your customization notes are not overwritten by upstream release notes.

## Practical rule

If you want to guarantee this customization stays, run your own custom-built desktop artifact after each update/rebase cycle.
