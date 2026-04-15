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

Use this flow to keep your custom behavior:

1. Keep custom work on a dedicated branch (example: `custom/image-preview`).
2. Sync latest upstream code into `main`.
3. Rebase your custom branch on top of updated `main`.
4. Resolve conflicts.
5. Rebuild desktop from source with `npm run build:desktop`.

Recommended commands:

```bash
# one-time: add upstream remote if needed
git remote add upstream https://github.com/getpaseo/paseo.git

# sync latest upstream into local main
git fetch upstream --tags
git checkout main
git rebase upstream/main

# rebase your customization branch on latest main
git checkout custom/image-preview
git rebase main

# verify + rebuild custom desktop app
npm run typecheck
npm run build:desktop
```

## Practical rule

If you want to guarantee this customization stays, run your own custom-built desktop artifact after each update/rebase cycle.
