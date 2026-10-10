# Code conventions (GDScript, Godot 4.7)

Inferred from the existing code on 2026-10-10. Items marked `(unconfirmed)` were
inferred and need your OK.

## Naming
| Thing | Convention | Example |
|---|---|---|
| Classes | `class_name` PascalCase, one per file | `class_name Health` |
| Files | snake_case matching the class | `scripts/components/health.gd` |
| Functions / vars | snake_case | `resist_for`, `shattered_left` |
| Private helpers | leading underscore | `_thief`, `_nearest_free_prop` |
| Constants | UPPER_SNAKE | `LIMIT_S` |
| Ids | StringName literals | `&"thief_imp"` |
| Unit tests | `test_<behaviour_in_words>` | `test_late_parry_does_not_block` |
| Bots | `tests/bot/bot_<scope>.gd` + `.tscn` | `bot_m2` |

## Structure
- `scripts/<domain>/` by domain: brains, combat, components, core, fighters, levels,
  player, props, run, talismans, ui, camera.
- Data classes (`FighterData`, `PropData`, `AttackData`) are Resources. Values live in
  `.tres` under `data/`, not in code.
- Autoloads: `Inputs`, `Events` (signal bus), `Juice`, `Meta`, `Run`. Cross-system
  communication goes through `Events` signals, not direct references.

## Patterns
- Static typing everywhere: typed vars (`var hp := 0.0`), typed params and returns.
- `##` doc comment on every class (after `extends`) and on public functions.
  Comments explain *why*, often naming the bug that caused it.
- Brains decide, Fighters act: brains set `intent_move`, `facing` and call
  `request_*()`; they never move bodies directly. Possession = brain swap.
- Fighter state changes go through the Fighter state machine (`Fighter.State`).
- Gameplay reads button presses with `Inputs.just_pressed(action)`, not
  `Input.is_action_just_pressed`, so the press that closes a menu doesn't also act in game.
  Menus that unpause call `Inputs.release_gameplay()` first.
- New tunable numbers become `@export` vars or `FighterData` / `PropData` fields
  (unconfirmed - some AI numbers are still inline constants today).

## Formatting
- Tabs for indentation; two blank lines between functions.
- No linter configured (unconfirmed). Gate = clean import and boot with no new
  errors or warnings in the output.

## Never
- Never run `tools/build_data.gd`: it regenerates every `.tres` and wipes hand tuning.
- Never `add_child` a body before setting its position.
- Never reference autoloads (`Events`, `Juice`, ...) from a `-s` SceneTree script.
