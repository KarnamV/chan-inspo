# design/

Planning artifacts for the game-dev skill pipeline (owned by `game-dev-index`).

**Plans, status and progress for this game live in one file: `plan.html`** (user decision 2026-10-10). It replaces the separate roadmap, status, asset plan and board. If a PRD or slices are added later, their tasks go into `plan.html` too.

## Layout

```
design/
  concept.md                 # game-brainstorm      → the chosen concept
  prototype-notes.md         # core-loop-prototype  → go/no-go on the fun
  prd.md                     # concept-to-prd       → requirements / GDD
  board.html                 # game-board (at prd)  → brief + Kanban renderer (open in browser)
  board.json                 # game-board           → live board data: tasks, sub-tasks, progress
  slices/
    horizontal.md            # prd-to-horizontal-slices  → epic map
    <epic>-vertical.md       # horizontal-to-vertical-slices → one file per epic
  playtests/
    YYYY-MM-DD.md            # playtest-capture     → one file per session
  CHANGELOG.md               # session-retro        → decisions + lessons log
```

## Vertical-slice schema

```md
### VS-<epic>-<n>: <short title>
- status: backlog | todo | doing | done   # slice-to-build updates this; mirrored on the board
- priority: must | should | could | wont   # set by scope-triage
- effort: S | M | L                  # set by scope-triage
- value: high | med | low            # set by scope-triage
- systems: [<system>, ...]           # which horizontal slices it touches
- assets: [<asset>, ...] | see asset-requirements
- outcome: <one player-facing, observable result>
- acceptance:
  - [ ] <testable criterion>
- verify: <how to run/observe it in the engine>
```
