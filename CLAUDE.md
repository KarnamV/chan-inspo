# Demon Realm Escape (chan-inspo v2)

Godot 4.7 project in `game/`. Design docs in `design/`.

- Project context lives in `.claude/context/`. Start with `.claude/context/index.md`
  and load area files only as needed (the `loop-engineering:project-context` skill).
- Code features are built with the loop-engineering plugin: `/loop-engineering:build`.
  Its rules are in `program.md`; results go to `results.tsv`; checks live in `checks/`.
- Asset generation is not part of the loop: use the ai-gamedev-pipeline skill.
- Never run `game/tools/build_data.gd` (overwrites hand-tuned `.tres`).
- Before running any test in a fresh checkout or worktree:
  `cd game && godot --headless --path . --import`
- Latest session notes: `.claude/handover.md`.
