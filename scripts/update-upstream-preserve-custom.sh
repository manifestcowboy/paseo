#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

NO_PUSH=0
SKIP_TYPECHECK=0
SKIP_INSTALLED_APP_SYNC=0

usage() {
  cat <<'EOF'
Usage: ./scripts/update-upstream-preserve-custom.sh [options]

Options:
  --no-push          Do not push to origin/main after successful update
  --skip-typecheck   Skip npm run typecheck
  --skip-installed-app-sync  Do not patch /Applications/Paseo.app after update
  -h, --help         Show this help

Workflow:
  1) Ensures clean working tree on main
  2) Fetches origin + upstream
  3) Rebases local main onto origin/main
  4) Merges upstream/main
  5) Auto-resolves known customization conflicts in favor of local fork files
  6) Runs verification (customization checks, server build, typecheck)
  7) Builds the current app web bundle and patches the installed Paseo.app in place
  8) Appends an entry to CUSTOM_CHANGELOG.md when upstream was merged
  9) Pushes to origin/main (unless --no-push)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-push)
      NO_PUSH=1
      shift
      ;;
    --skip-typecheck)
      SKIP_TYPECHECK=1
      shift
      ;;
    --skip-installed-app-sync)
      SKIP_INSTALLED_APP_SYNC=1
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

if [[ "$(git rev-parse --abbrev-ref HEAD)" != "main" ]]; then
  echo "This script must be run on branch 'main'." >&2
  exit 1
fi

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Working tree is not clean. Commit/stash changes first." >&2
  exit 1
fi

if ! git remote get-url upstream >/dev/null 2>&1; then
  echo "Missing 'upstream' remote. Add it first:" >&2
  echo "  git remote add upstream https://github.com/getpaseo/paseo.git" >&2
  exit 1
fi

BEFORE_HEAD="$(git rev-parse --short HEAD)"
echo "[info] Starting from $BEFORE_HEAD"

echo "[info] Fetching remotes..."
git fetch origin --prune
git fetch upstream --tags --prune

echo "[info] Rebasing local main onto origin/main..."
git pull --rebase origin main

UPSTREAM_REF="upstream/main"
if git merge-base --is-ancestor "$UPSTREAM_REF" HEAD; then
  echo "[info] Local main already contains $UPSTREAM_REF."
  DID_UPSTREAM_MERGE=0
else
  DID_UPSTREAM_MERGE=1
fi

CUSTOM_FILES=(
  "LESSONS.md"
  "orchestrate.json"
  "CUSTOM_DESKTOP_WORKFLOW.md"
  "docs/CUSTOM_DESKTOP_WORKFLOW.md"
  "CUSTOM_CHANGELOG.md"
  "packages/app/src/components/attachment-image-preview-modal.tsx"
  "packages/app/src/components/message-input.tsx"
  "packages/app/src/components/message.tsx"
  "packages/app/src/lib/overlay-root.ts"
  "scripts/verify-customizations.sh"
  "pr-notes/PR_NOTES_IMAGE_LIGHTBOX_AND_OPENCODE_ANTIGRAVITY.md"
)

if [[ "$DID_UPSTREAM_MERGE" -eq 1 ]]; then
  echo "[info] Merging $UPSTREAM_REF into main..."
  set +e
  git merge --no-ff --no-edit "$UPSTREAM_REF"
  MERGE_EXIT=$?
  set -e

  if [[ "$MERGE_EXIT" -ne 0 ]]; then
    echo "[warn] Merge had conflicts. Auto-resolving known customization files..."
    for f in "${CUSTOM_FILES[@]}"; do
      if git ls-files -u -- "$f" | grep -q .; then
        git checkout --ours -- "$f"
        git add "$f"
        echo "  [resolved ours] $f"
      fi
    done

    # Keep upstream lock/hash metadata when it conflicts.
    if git ls-files -u -- "nix/package.nix" | grep -q .; then
      git checkout --theirs -- "nix/package.nix"
      git add "nix/package.nix"
      echo "  [resolved theirs] nix/package.nix"
    fi

    UNRESOLVED="$(git diff --name-only --diff-filter=U || true)"
    if [[ -n "$UNRESOLVED" ]]; then
      echo "[error] Unresolved merge conflicts remain:" >&2
      echo "$UNRESOLVED" >&2
      echo "Resolve them, then re-run verification + push manually." >&2
      exit 1
    fi

    git commit --no-edit
  fi
fi

echo "[info] Running customization verification..."
npm run verify:customizations

echo "[info] Rebuilding server dist snapshot..."
npm run build --workspace=@getpaseo/server

if [[ "$SKIP_TYPECHECK" -eq 0 ]]; then
  echo "[info] Running full typecheck..."
  npm run typecheck
else
  echo "[info] Skipping typecheck (--skip-typecheck)."
fi

echo "[info] Building current app web bundle..."
npm run build:web --workspace=@getpaseo/app

if [[ "$SKIP_INSTALLED_APP_SYNC" -eq 0 ]]; then
  echo "[info] Syncing customizations into the installed Paseo app..."
  ./scripts/sync-installed-app-customizations.sh --no-build-web
else
  echo "[info] Skipping installed app sync (--skip-installed-app-sync)."
fi

AFTER_HEAD="$(git rev-parse --short HEAD)"
UPSTREAM_SHORT="$(git rev-parse --short "$UPSTREAM_REF")"
UPSTREAM_TAG="$(git describe --tags --abbrev=0 "$UPSTREAM_REF" 2>/dev/null || echo "unreleased")"

if [[ "$DID_UPSTREAM_MERGE" -eq 1 ]]; then
  TODAY="$(date -u +%Y-%m-%d)"
  cat >> CUSTOM_CHANGELOG.md <<EOF

## ${TODAY} - Upstream Sync (${UPSTREAM_TAG})

- Synced \`main\` with \`$UPSTREAM_REF\` (\`${UPSTREAM_SHORT}\`)
- Preserved fork customizations (lightbox, LESSONS, orchestration config)
- Verification executed:
  - \`npm run verify:customizations\`
  - \`npm run build --workspace=@getpaseo/server\`
  - \`npm run typecheck\`
  - \`npm run build:web --workspace=@getpaseo/app\`
  - \`./scripts/sync-installed-app-customizations.sh --no-build-web\`
- Local head moved: \`${BEFORE_HEAD}\` -> \`${AFTER_HEAD}\`
EOF

  git add CUSTOM_CHANGELOG.md
  git commit -m "docs: record upstream sync ${UPSTREAM_TAG} in custom changelog"
  AFTER_HEAD="$(git rev-parse --short HEAD)"
fi

if [[ "$NO_PUSH" -eq 0 ]]; then
  echo "[info] Pushing main to origin..."
  git push origin main
else
  echo "[info] --no-push set; skipped pushing."
fi

echo "[done] Update complete."
echo "       HEAD: $AFTER_HEAD"
echo "       Upstream ref: $UPSTREAM_REF ($UPSTREAM_SHORT)"
