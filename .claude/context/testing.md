# Testing

All commands run from `game/`. `godot` must be on PATH (Godot 4.7).

## Setup in a fresh checkout or worktree (required)
`.godot/` (the import cache) is gitignored, so a new git worktree has none. Run this
once before any test, or tests fail or crawl:

```
godot --headless --path . --import
```

## Stack
| Kind | Framework | Location | Command |
|---|---|---|---|
| Unit | GUT 9.7.1 | `tests/unit/test_*.gd` | `godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit` |
| Gameplay (integration) | Bot scenes | `tests/bot/bot_*.tscn` | `godot --headless --path . --fixed-fps 60 res://tests/bot/<bot>.tscn` |
| Boot | Godot | - | `godot --headless --path . --quit-after 300` |

Bot pass = process exit code 0. Each bot prints `PASS`/`FAIL` lines and a
`BOT RESULT:` line.

## Run one test
- One file: `godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit -gtest=res://tests/unit/test_health.gd`
- One test: add `-gunit_test_name=test_invulnerable_takes_nothing`

## Bots
| Bot | Covers | Approx. time |
|---|---|---|
| `bot_m1` | Core loop: grab, break, knockdown, possess, host hits, release, kill | short |
| `bot_m2` | Combat arena waves, all 6 demon types, parry/chi/props | up to 300 s limit |
| `bot_m3` | All 12 talismans (19 checks) | medium |
| `bot_run` | Full realm-1 run: 10 rooms, helpers, shop, shrine, boss, hub | longest |

## Full suite
1. Import (above)
2. Unit tests
3. Boot check
4. `bot_m1`, `bot_m2`, `bot_m3`, `bot_run`, each exit 0

## Gates for the loop
| Gate | When | Rule |
|---|---|---|
| Feature unit tests | every attempt | all pass |
| Relevant bot(s) | every attempt | exit 0 **3 runs in a row** (bots are timing sensitive) |
| All unit tests + boot | every attempt | pass, no new errors in output |
| All 4 bots | before merge only | each exit 0 |

## Unit vs gameplay boundary
- **Unit (GUT)**: one class or a small group, logic and numbers. Build nodes in
  `before_each`, free with `add_child_autofree`. No `current_scene` in GUT; use a
  `level_root` Node3D when code needs one.
- **Gameplay (bot)**: real scene, physics and AI over time. A bot drives a `Brain`
  subclass and checks outcomes. Bots that drive UI set `process_mode = ALWAYS`
  (panels pause the tree).
- **Human**: fun, feel, balance, readability, art. Bots run with god-mode HP and
  3x damage, so they never prove balance.

## Writing tests first (TDD) in GDScript
- A test that references a class or method that does not exist yet fails to
  **parse**, which is failing for the wrong reason. Before proving red, add stubs:
  the `class_name` script with the new methods, each body `push_error("TODO <id>")`
  and returning a wrong default, so tests fail on assertions.
- New bot checks for a feature go in a new bot scene (`tests/bot/bot_<feature>.tscn`)
  or a new check in an existing bot. Record which in `checks/manifest.json`.
- Name tests by behaviour, one behaviour per test.

## Godot test traps
- Set a body's position before `add_child` (spawning at origin makes bodies pop).
- `-s` scripts compile before autoloads exist; anything touching `Events`/`Juice`
  must be a scene (that is why bots are scenes).
- After adding a new `class_name`, re-run import so the class cache picks it up.
