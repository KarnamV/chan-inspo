# program.md

Instruction set for the loop-engineering build loop on Demon Realm Escape. The human
edits this file to steer the loop; the agent reads it in full at the start of every
run and never writes results here. Results go to `results.tsv`.

## Setup

To start a new batch, work with the user to:

1. **Agree on a batch tag**: e.g. `b-2026-10-11a`.
2. **Confirm the integration branch**: `main`. Work never lands anywhere else.
3. **Read the in-scope files**:
   - `.claude/context/index.md`, `conventions.md`, `testing.md`, `decisions.md`
   - `.claude/context/areas/<area>.md` for the areas this batch touches only
   - `checks/features.md`
   - The design doc section for the feature (`design/concept.md`, `design/plan.html`)
     when the feature is new gameplay.
4. **Establish the baseline** (from `game/`): import, all unit tests, boot check, and
   all 4 bots. Everything must pass before anything starts.
5. **Confirm and go**: once the plan table is agreed, start the loop.

## What the loop does

Each feature is one experiment. Its checks are written and locked first; a builder
then makes them pass in an isolated worktree; the orchestrator re-runs every gate and
keeps or discards the result.

**What you CAN do:**
- Change GDScript, scenes (`.tscn`) and data resources (`.tres`) inside the
  feature's expected footprint.
- Add new unit tests (`game/tests/unit/test_*.gd`) and new bot scenes
  (`game/tests/bot/bot_*.tscn` + `.gd`).
- Add new `FighterData` / `PropData` fields for new tunables.
- Propose updates to project context in the builder result.

**What you CANNOT do:**
- Modify, delete, skip or weaken any locked check (`checks/` and every path in
  `checks/locked.txt`). This is the fixed evaluation.
- Run `game/tools/build_data.gd` (wipes hand-tuned `.tres`).
- Generate, edit or replace assets: `.glb`, textures, `art/`, `assets/`,
  `assets/manifest.csv`, `tools/sync_assets.py`. Asset work goes through the
  ai-gamedev-pipeline skill, never the loop.
- Change balance numbers that `decisions.md` marks as deliberate (Sheep economy,
  shield turn rate) unless the feature says so.
- Add Godot addons or plugins other than GUT.
- Edit `design/`, `program.md`, `results.tsv` or `.claude/context/` from a builder.
- Push to GitHub.

**The goal:** every locked check for the feature passes, the full suite stays green,
conventions are followed, and the diff is as small as it can be. Simpler is better.

## Limits

- Max parallel builders: `1` (raise to `2` after the first clean batch; each builder
  runs a headless Godot import plus bots)
- Attempt budget per feature: `3` full gate runs after the first
- Time budget per feature: `45` minutes (import + bots are slow)
- Stop the batch if: the same feature is discarded twice, the baseline goes red, or
  more than half the batch is discarded.

## Gates (keep / discard)

Run from `game/` in the builder's branch. A result is `keep` only if all hold, as
verified by the orchestrator:

0. Fresh worktree setup: `godot --headless --path . --import` (not a gate, required first)
1. Checks guard passes (no locked file changed).
2. Feature unit tests pass: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit -gtest=<feature test file>`
3. Feature bot(s) exit 0, **3 runs in a row**: `godot --headless --path . --fixed-fps 60 <bot scene>`
4. All unit tests pass and the boot check shows no new errors:
   `godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit` and
   `godot --headless --path . --quit-after 300`
5. Before merge only: `bot_m1`, `bot_m2`, `bot_m3`, `bot_run` each exit 0.

Anything else is `discard` (branch deleted) or `crash`. `blocked` waits for a human.
Fun, feel and balance are never gates: they are human checks.

## Output format

Each builder ends with a single JSON object (see the feature-builder agent). The
orchestrator turns it into one row in `results.tsv`.

## Logging results

`results.tsv` is tab-separated, append-only, one row per attempt:

```
timestamp	batch	feature	attempt	branch	commit	status	unit	integration	suite	human	description
```

- `unit` = GUT `passed/total` for the feature's tests
- `integration` = bot runs passed out of 3, e.g. `3/3`
- `suite` = `pass` / `fail` (all unit + boot, plus all bots before merge)
- `status` = `keep`, `discard`, `crash`, `blocked`, `discard (merge)`, `human-pass`,
  `human-fail`, `human-partial`
- `human` = `pending`, `pass`, `fail`, `n/a`

## The loop

LOOP over the planned lanes:

1. Write and commit the checks for the batch (`write-checks`): GUT tests with stubs
   so they fail on assertions, bot checks, human checks. Prove red.
2. Fan out one feature-builder per independent lane, each in its own worktree,
   starting from the checks commit. First step in every worktree: import.
3. For each result: run every gate yourself. Do not trust the builder's claim.
4. Append a row to `results.tsv`.
5. `keep`: merge into `main`, re-run the full suite including all 4 bots.
   `discard` / `crash`: delete the branch; re-brief only if the failure looks fixable.
6. After the batch: merge context updates (`project-context update`), list pending
   human checks, and report.

Keep going through the batch without asking whether to continue, except at the stop
conditions. When the batch is done, stop: the human plays the build and runs
`human-review`, then the next batch starts.
