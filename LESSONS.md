# Paseo Orchestration Lessons

Durable patterns and rules learned from real orchestration sessions. Read this before spawning agents or creating rooms.

---

## Room Mention Hygiene

**Rule**: A room's @mentions should only include agents spawned for that room's task. Never paste or reference old/archived agent IDs into a room.

**What went wrong**: An orchestrator posted context mentioning old agent IDs into a room. Paseo tagged those dead agents in the room's mention list. When new agents posted results, the room mixed current and stale agent references, causing confusion about which results were real.

**How to avoid**:
1. When creating a room, post only the objective — no old agent IDs.
2. When posting to a room, only @mention agents actively spawned for THIS task.
3. Never use @everyone in rooms that span multiple agent generations.
4. Room reuse for the same task is fine — mention discipline is what matters.
5. If a room has accumulated stale mentions, create a fresh room for the next round rather than trying to clean it up.

---

## Testing Agents Must Never Edit Code

**Rule**: Test agents (Gemini Flash, minimax, any cheap model) report PASS/FAIL only. They never edit source files.

**What went wrong**: A Gemini Flash agent was asked to test bulk operations. Instead of just reporting failures, it started editing backend source files to "fix" issues it found. The changes were low quality and had to be reverted.

**How to avoid**:
1. Always include "Do NOT edit any files" in test agent prompts.
2. Test agents run functions, check results, report PASS/FAIL with error details. Zero file edits.
3. Backend fixes → Codex only. UI fixes → Claude only.
4. If a test agent needs code changes to proceed, it stops and reports the blocker.

---

## Codex Rate Limit Recovery

**Rule**: Use the external Codex auto-recovery script first (it is not part of Paseo), then fall back to manual Paseo CLI recovery if the agent is still stalled.

**What went wrong**: Codex agents appeared stalled from low usage. Instead of resuming them, they were replaced, which lost useful context and interrupted ongoing work.

**How to avoid**:
1. When Codex usage drops below 10%, let the external script run first: it switches Codex account, reloads recently active Codex agents in Paseo (last ~10 minutes), and sends a follow-up resume message.
2. If the agent is still stalled after auto-recovery, run manual recovery with Paseo CLI:
   - `paseo agent reload <id>`
   - `paseo agent send <id> "Resume your work from where you left off."`
3. If you still want the same agent to continue the task, always send the resume message after reload; without it, work may not continue.
4. If the agent thread is too long and quality is dropping from context limits, launch a new agent and hand off the current task state.

---

## One Focused Task Per Agent

**Rule**: Each agent gets one clear task. Don't mix research and implementation, or testing and fixing, in the same agent.

**What went wrong**: An agent was given research + implementation + coding standards cleanup + task file creation in one prompt. Quality suffered across all tasks.

**How to avoid**:
1. Each agent prompt has one verb: "research", "implement", "test", "plan", or "fix".
2. If a task has multiple phases, use multiple agents or sequential messages to the same agent.
3. Keep the scope narrow enough that the agent can hold the full context in focus.

---

## Permission Modes Are Provider-Specific

**Rule**: `--mode bypassPermissions` only works for Claude. `--mode full-access` only works for Codex. OpenCode (Gemini, minimax) has NO mode flag — omit it entirely.

**What went wrong**: Launched Gemini Flash with `--mode bypassPermissions` twice. Both times it errored: "Agent not found: bypassPermissions. Available agents: build, design-review, explore, general, plan."

**Correct usage**:
- Claude: `paseo run --mode bypassPermissions --provider claude/opus`
- Codex: `paseo run --mode full-access --provider codex/gpt-5.4`
- OpenCode (Gemini/minimax): `paseo run --provider opencode/google/antigravity-gemini-3-flash` (NO --mode flag)

---

## Agent File Scope Isolation

**Rule**: When running parallel agents, assign non-overlapping file scopes to prevent merge conflicts.

**Example split**:
- Backend agent: `packages/server/`, `packages/cli/`, `packages/relay/` only
- UI agent: `packages/app/`, `packages/desktop/`, `packages/website/` only
- Research agent: `docs/`, `LESSONS.md`, `scripts/` only (no source code)

State this explicitly in each agent's prompt: "Do NOT touch files in X directory."

---

## Long Orchestrator Sessions Degrade Quality

**Rule**: Start a fresh orchestrator session after ~50 agent cycles or when context compression becomes visible. If an individual agent thread grows too long and quality drops, hand off and start a fresh agent.

**What went wrong**: After 20+ hours and 50+ agent spawns, the orchestrator was losing detail from earlier decisions, repeating mistakes (wrong --mode flags, wrong model choices), and the compressed context made it harder to reason about the full project state.

**How to avoid**:
1. Save all durable decisions to memory files (already done)
2. Update LESSONS.md and changelog before handoff
3. Create a fresh session with the orchestrator bootstrap prompt
4. The new session loads fresh project state instead of relying on compressed history

---

## Never Archive Agent Sessions You Didn't Spawn

**Rule**: Only archive agents that YOU (this orchestrator session) spawned. Never archive agents created by the user or other sessions.

**What went wrong**: The orchestrator bulk-archived "stale" agents that included the user's personal agent sessions (General Assistance, GAS Manager, etc.). These were not stale — they were the user's ongoing work in other contexts.

**How to avoid**:
1. Before archiving, check who spawned the agent — only archive agents from YOUR session
2. When cleaning up, filter by agent names you created (e.g., `impl-*`, `plan-*`, `verify-*`, `ui-*`, `audit-*`)
3. Never archive agents with generic names like "General Assistance" or names you don't recognize
4. If unsure, ask the user before archiving

---

## Compilation Pass ≠ Verified Working

**Rule**: Typecheck + build passing means the code compiles. It does NOT mean the feature works. Never report a feature as "done" or "verified" unless it was tested through actual UI interaction in a real browser.

**What went wrong**: Over a multi-phase overnight sprint, agents reported "PASS" based on `npm run typecheck` and `npm run build` succeeding. The orchestrator then told the user features were "complete" and "verified." When the user actually tested in the browser, many features were broken — translations not showing, tag selectors still plain text, speech generation still failing, etc.

**How to avoid**:
1. "Code done" and "verified working" are two completely different statuses. Use `implemented_not_verified` until browser-tested.
2. Never tell the user "X is fixed" unless you or an agent actually performed the action in a browser and saw the correct result.
3. If browser testing is blocked by environment or tooling, say so explicitly — don't report the feature as done.
4. Agent self-reports of "PASS" based on code review are worthless for functional verification. Require screenshot evidence or runtime output.
5. Keep explicit statuses in updates (`implemented_not_verified` vs `verified_working`) so verification state is always clear.

---

## Syncing with Upstream (Fork Maintenance)

**Rule**: Always run `npm run typecheck` and `npm run format:check` locally before pushing after an upstream merge. Never blindly keep HEAD for all conflicts.

**What went wrong**: Syncing upstream/main (v0.1.56) introduced 8+ typecheck failures and 2 format failures that broke CI. Root causes:
1. Keeping our stripped-down `use-settings.ts` blocked the upstream's expanded `AppSettings` type (`ThemeName`, `sendBehavior`) that `settings-screen.tsx` depended on
2. Keeping the reverted `opencode-agent.ts` left unresolved Promise type errors against updated server types
3. Two `IS_WEB` / `Platform.OS` references were missed during conflict resolution
4. Server package `dist/` was stale — `spawnProcess`/`execCommand` were in source but not in compiled types

**How to sync cleanly**:
```bash
git fetch upstream
git merge upstream/main
# For each conflict, read BOTH sides before deciding — don't blindly pick HEAD
# After resolving:
npm run build --workspace=@getpaseo/server   # rebuild dist types if server changed
npm run typecheck                             # must be zero errors
npm run format                               # auto-fix formatting
git add -A && git commit && git push origin main
```

**Conflict resolution heuristics**:
- If upstream changed a **type definition** (e.g. `AppSettings`, `ProviderSnapshotEntry`): take upstream — downstream files will depend on it
- If upstream changed a **large implementation file** (e.g. `opencode-agent.ts`): take upstream unless you have specific intentional changes to that file
- If the conflict is in a **file you added** (e.g. `attachment-image-preview-modal.tsx`): take yours
- If upstream renamed constants (e.g. `IS_WEB` → `isWeb`): take upstream and update your usage

---

## Our Customizations in This Fork

**What we've added**:

- The canonical preserved file list lives in `scripts/customization-manifest.sh`.
- Current fork-owned areas include:
  - image lightbox customization in `packages/app/src/components/*` and `packages/app/src/lib/overlay-root.ts`
  - local orchestration/config guidance in `orchestrate.json`, `AGENTS.md`, and `LESSONS.md`
  - installed-app maintenance flow in `CUSTOM_DESKTOP_WORKFLOW.md` and `scripts/sync-installed-app-customizations.sh`
  - fork history in `CUSTOM_CHANGELOG.md`
  - supporting PR notes in `pr-notes/`

**How to keep new customizations persistent**:
1. Add the owned file path(s) to `scripts/customization-manifest.sh`.
2. Update `CUSTOM_CHANGELOG.md`.
3. Extend `scripts/verify-customizations.sh` when the customization introduces behavior that should be checked automatically.
4. Run `npm run verify:customizations`.

**Files that are safe to take 100% from upstream** (no custom changes):
- `opencode-agent.ts` — we reverted a cherry-pick; upstream's full version is correct
- `settings-screen.tsx`, `_layout.tsx` — no custom changes

**Correction**:
- `use-settings.ts` is not automatically safe to take unchanged from upstream anymore.
- Upstream validation still needs to be checked against our persistence expectations and tests, especially when upstream expands theme options or adds new settings fields.

---

## Rebuild Server Dist After Upstream Sync

**Rule**: After syncing upstream, always rebuild the server package before typechecking. The committed `dist/` snapshot goes stale when exports change.

**Symptom**: Typecheck errors like `Module '@getpaseo/server' has no exported member 'spawnProcess'` even though `exports.ts` has the export.

**Fix**:
```bash
npm run build --workspace=@getpaseo/server
npm run typecheck   # should now be clean
```

**Why**: The server package's `dist/server/server/exports.d.ts` is committed to the repo as a snapshot. When upstream adds exports to `src/server/exports.ts`, the dist snapshot is stale until rebuilt. CI works because it always builds from scratch.

---

## Installed App Must Be Patched After Upstream Update

**Rule**: Updating the forked repo is not enough by itself. After upstream sync, patch the installed `/Applications/Paseo.app` from the current repo so the running app actually uses the customized renderer bundle.

**What went wrong**: The repo contained the lightbox customization, verification passed, and the fork was on the latest upstream version. But the installed app was still serving an older `app-dist` bundle inside `/Applications/Paseo.app`, so restarting Paseo did not show the customization.

**How to avoid**:
1. Treat repo sync and installed-app sync as two separate steps.
2. After upstream merge + verification, run the installed-app sync step:
   - `npm run sync:installed:app`
3. Prefer the one-command path for routine updates:
   - `npm run update:upstream:preserve`
4. If the app still looks upstream-clean after a restart, compare the installed app bundle timestamps before assuming the code merge failed.

---

## Upstream Theme Sets Can Invalidate "Invalid Theme" Tests

**Rule**: When testing sanitization logic for persisted enums, use a value that is definitely outside the current upstream enum set.

**What went wrong**: A test used `zinc` as the invalid persisted theme. Upstream now accepts `zinc` as a valid theme, so the test was no longer exercising invalid-value recovery and started failing after sync.

**How to avoid**:
1. Check the live enum source before picking an "invalid" fixture.
2. Prefer obviously invalid sentinel values like `sepia` instead of values that might later become valid product options.
3. If a sanitization test expects persistence, assert both the returned normalized value and the write-back to storage.

---

## Sanitizing Persisted Settings Must Write Back

**Rule**: If settings are repaired on read, persist the repaired value immediately so subsequent loads and tests see the normalized state.

**What went wrong**: `loadSettingsFromStorage()` corrected an invalid persisted theme in memory but did not write the corrected value back to `AsyncStorage`. The app test expected sanitization plus persistence, so it failed after the upstream sync.

**How to avoid**:
1. When normalizing stored config, track whether repair happened.
2. If repair happened, persist the normalized object before returning it.
3. Keep the default object complete so repaired writes include new upstream fields like `sendBehavior`.

---

## Direct-Route Playwright Tests Need a Real Origin First

**Rule**: If an E2E helper touches `localStorage`, navigate to the app origin before calling it. Do not evaluate storage on `about:blank`.

**What went wrong**: The failing workspace and terminal specs deep-linked straight into workspace routes. A first attempt to fix them called the storage seeding helper before any navigation, which threw `SecurityError: Failed to read the 'localStorage' property from 'Window'` because the page was still on `about:blank`.

**How to avoid**:
1. Reuse `gotoAppShell(page)` or navigate to `/` before any storage-based seeding helper.
2. Only deep-link after the app origin has been established and the test daemon registry is seeded.
3. For direct-route specs, separate "boot app shell safely" from "navigate to target route."

---

## Keep One Worktree, Not Five

**Rule**: Never accumulate multiple git worktrees of the same repo. Use one (`~/paseo` on `main`) and create temporary worktrees only when actively needed.

**What went wrong**: Five Paseo worktrees accumulated (`paseo`, `paseo-latest-lightbox`, `paseo-lightbox-recover`, `paseo-v053-lightbox`, `paseo-v054-lightbox`) — each with its own `node_modules`. Total waste: ~15 GB.

**How to avoid**:
1. All work happens in `~/paseo` on `main`
2. If you need an isolated branch for a task: `git worktree add ../paseo-temp feature/xyz`
3. Remove it when done: `git worktree remove ../paseo-temp`
4. Never let worktrees pile up — they each duplicate `node_modules`
