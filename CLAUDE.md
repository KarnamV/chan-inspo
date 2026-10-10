# chan-inspo (Demon Realm Escape v2)

**All plans, status and progress live in one file: [`design/plan.html`](design/plan.html).** Read its "Now" section at the start of every session to know what's happening, and keep it current:

- Tick tasks (`<li class="done">`), add new tasks to the right milestone, rewrite "Now", and bump `data-updated` on `<body>` whenever progress changes. Progress bars recompute from the task lists.
- Don't create other plan, status, roadmap or board files. Decisions and lessons go to `design/CHANGELOG.md` (history).
- Reference docs (not plans): `design/concept.md` (game design + story), `design/art-bible.md`, `design/tech.md` (architecture, gotchas, how to run checks).
- The user plays the standalone exe, not the editor: after any gameplay/art change run `build_exe.bat` → `build/windows/DemonRealmEscape.exe`.
- Game project: `game/` (Godot 4.7). Assets: `assets/manifest.csv` + the ai-gamedev-pipeline skill (not part of the build loop).

## Build loop (loop-engineering plugin)

- Code context lives in `.claude/context/`. Start with `.claude/context/index.md` and load area files only as needed (the `loop-engineering:project-context` skill).
- Code features are built with `/loop-engineering:build`. Its rules are in `program.md`; results go to `results.tsv`; checks live in `checks/`.
- Never run `game/tools/build_data.gd` (overwrites hand-tuned `.tres`).
- Before running any test in a fresh checkout or worktree: `cd game && godot --headless --path . --import`
