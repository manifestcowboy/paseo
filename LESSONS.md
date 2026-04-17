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

**What went wrong**: A Gemini Flash agent was asked to test bulk operations. Instead of just reporting failures, it started editing Convex backend files to "fix" issues it found. The changes were low quality and had to be reverted.

**How to avoid**:
1. Always include "Do NOT edit any files" in test agent prompts.
2. Test agents run functions, check results, report PASS/FAIL with error details. Zero file edits.
3. Backend fixes → Codex only. UI fixes → Claude only.
4. If a test agent needs code changes to proceed, it stops and reports the blocker.

---

## Codex Rate Limit Recovery

**Rule**: When a Codex agent stalls, reload it — never archive it.

**What went wrong**: Codex agents hit rate limits and appeared stuck. The orchestrator archived them and launched fresh agents, losing all accumulated context.

**How to avoid**:
1. Never archive a stalled Codex agent — this destroys context permanently.
2. Send a resume message: `paseo send <id> "Resume your work from where you left off."`
3. The automatic account switcher rotates Codex accounts when usage drops below 10%. Reloading picks up the new account.
4. Only archive after 3+ failed reload attempts AND the agent is truly dead.

---

## Model Selection by Task Type

**Rule**: Use the right model for each job. Don't waste expensive models on cheap work.

| Task Type | Model | Why |
|---|---|---|
| Functional testing (routes, data, APIs) | Gemini Flash / minimax | Cheap, just checking results |
| Visual UI testing (layout, screenshots) | Claude Sonnet + Chrome | Needs rendering + design eye |
| UI/UX design and styling | Claude Opus | Creative judgment |
| Implementation (React logic, backend) | Codex 5.3 | Mechanical code |
| Debugging, deep investigation | Codex 5.4 | Deep reasoning |
| Planning, architecture | Codex 5.4 | Complex tradeoffs |
| Notion updates | minimax / Gemini | Simple structured writes |

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
- Backend agent: `convex/`, `lib/server/`, `app/api/` only
- UI agent: `app/(dashboard)/`, `components/`, `features/`, `contexts/` only
- Research agent: `tasks/` only (no source code)

State this explicitly in each agent's prompt: "Do NOT touch files in X directory."

---

## Gemini Flash Stalls on Complex Multi-Step Tasks

**Rule**: Gemini Flash 3 (Antigravity) works for simple tasks but consistently stalls on complex multi-step browser testing. Use Sonnet for browser-based testing.

**What went wrong**: Gemini Flash was launched 4 times for browser testing. Each time it loaded skills/context but never started executing tool calls. The agent appeared "running" but UpdatedAt stopped advancing.

**How to avoid**:
1. Simple functional checks (does this route exist, does this API respond) → Gemini Flash is fine
2. Multi-step browser testing (login → navigate → click → verify → screenshot → report) → Use Sonnet
3. If Gemini stalls for 15+ minutes with no tool calls, switch to Sonnet — don't keep retrying

---

## CLI Testing Fails on Admin-Gated Functions

**Rule**: `convex run` from CLI cannot pass Better Auth sessions. All `requireAdmin`-gated functions fail with "Unauthenticated" when called via CLI.

**What went wrong**: Test agents tried to verify bulk operations via `convex run` CLI. Every test returned "Unauthenticated" — not because the code was broken, but because CLI has no auth context.

**How to avoid**:
1. Test admin-gated functions through the browser UI (Chrome engine), not CLI
2. CLI is only useful for non-auth-gated queries or internal mutations
3. If a query is needed before auth resolves (like voice list for player), remove `requireAdmin` from it

---

## Restart Dev Server After Branch Merges

**Rule**: After merging new routes/pages to main, restart the Next.js dev server. New routes return 404 until the server picks them up.

**What went wrong**: The live globe expansion page was merged to main but returned 404 during verification. The dev server was still running on the pre-merge code.

**How to avoid**: Kill and restart the dev server after every branch merge that adds new routes.

---

## Long Orchestrator Sessions Degrade Quality

**Rule**: Start a fresh orchestrator session after ~50 agent cycles or when context compression becomes visible. Use memory system + handoff prompt for continuity.

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
3. If browser testing fails (agent-browser broken, Playwright auth issues), say so explicitly — don't report the feature as done.
4. Agent self-reports of "PASS" based on code review are worthless for functional verification. Require screenshot evidence or runtime output.
5. When in doubt, use the content-pipeline-status.md status levels: `verified_working` requires actual testing, not just compilation.

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

**What we've added** (protect these during upstream syncs):

| File | What it does |
|---|---|
| `packages/app/src/components/attachment-image-preview-modal.tsx` | Full-screen image lightbox — new file, no upstream conflict |
| `packages/app/src/components/message-input.tsx` | Tap thumbnail to preview; separate remove button; uses lightbox modal |
| `packages/app/src/components/message.tsx` | Wired to lightbox in user message image display |
| `packages/app/src/lib/overlay-root.ts` | 1-line addition for portal root |
| `orchestrate.json` | Agent orchestration config (root of repo) |
| `LESSONS.md` | This file |
| `CUSTOM_DESKTOP_WORKFLOW.md` | Custom desktop workflow notes |
| `pr-notes/` | PR documentation |

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

## GitHub Failure Notifications Can Be Stale

**Rule**: Before fixing "current CI failures," check the latest completed GitHub Actions run instead of trusting delayed mobile notifications or an earlier summary.

**What went wrong**: The phone notifications said `server-tests` and `cli-tests` were failing. On the latest `main` workflow run, those jobs were already green. The real remaining failures were `app-tests` and `playwright`.

**How to avoid**:
1. Check the latest workflow run first.
2. Compare the exact failed jobs on that run against local reproduction.
3. Treat old notifications as hints, not source of truth.

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

## Playwright CI Should Not Hard-Fail On Missing Speech Backends

**Rule**: App E2E global setup must not crash the whole Playwright suite just because OpenAI speech and local speech models are both unavailable, unless the suite explicitly needs dictation or voice coverage.

**What went wrong**: GitHub Actions `playwright` failed before any tests ran. `packages/app/e2e/global-setup.ts` probed `OPENAI_API_KEY`, then fell back to `~/.paseo/models/local-speech`, and threw when neither was available. That made unrelated browser tests fail even though they do not exercise dictation.

**How to avoid**:
1. In global setup, treat speech as optional for non-dictation suites.
2. If OpenAI speech is unavailable and local speech models are missing, continue with:
   - `PASEO_DICTATION_ENABLED=0`
   - `PASEO_VOICE_MODE_ENABLED=0`
3. Only enable local speech providers when local models are actually present.
4. Reserve hard failures for suites that explicitly verify dictation or voice features.
5. When reproducing CI locally, simulate the runner with no speech backend by clearing `OPENAI_API_KEY` and pointing `HOME` at a temp directory.

---

## Keep One Worktree, Not Five

**Rule**: Never accumulate multiple git worktrees of the same repo. Use one (`~/paseo` on `main`) and create temporary worktrees only when actively needed.

**What went wrong**: Five Paseo worktrees accumulated (`paseo`, `paseo-latest-lightbox`, `paseo-lightbox-recover`, `paseo-v053-lightbox`, `paseo-v054-lightbox`) — each with its own `node_modules`. Total waste: ~15 GB.

**How to avoid**:
1. All work happens in `~/paseo` on `main`
2. If you need an isolated branch for a task: `git worktree add ../paseo-temp feature/xyz`
3. Remove it when done: `git worktree remove ../paseo-temp`
4. Never let worktrees pile up — they each duplicate `node_modules`

---

## Browser Testing Is Unreliable via Subagents

**Rule**: agent-browser interactive commands and Playwright via Paseo subagents are currently unreliable. Plan for this.

**What went wrong**: Multiple Sonnet agents were launched for browser testing. All failed — agent-browser daemon hangs on interactive commands, Playwright in subagents can't authenticate through the password gate. Hours of tokens burned with zero test results.

**How to avoid**:
1. Don't launch browser test agents as the primary verification strategy
2. Use Lightpanda for functional/DOM checks (does the route return 200, does the HTML contain expected elements)
3. For visual/interaction testing, ask the user to do a manual check or use a headed browser session
4. If you must automate, use Playwright from the orchestrator context (not a subagent) with the Chrome executablePath approach — but expect auth issues on localhost

---

## Always Push Convex Functions After Code Changes

**Rule**: After editing files in `convex/`, always run `npx convex dev --once` (or `./node_modules/.bin/convex dev --once`) to deploy the functions to the Convex runtime. Git push does NOT deploy Convex functions.

**What went wrong**: Added a `requireAdmin` bypass in `convex/auth.ts`, committed and pushed to git, but never ran `convex dev --once`. The deployed Convex functions were still the old version without the bypass. Spent hours debugging why the bypass "wasn't working" when it simply wasn't deployed.

**How to avoid**:
1. After ANY change to `convex/*.ts` files, run `npx convex dev --once`
2. This is separate from `git push` — Convex has its own deployment
3. Verify with `convex status` or check the Convex dashboard
