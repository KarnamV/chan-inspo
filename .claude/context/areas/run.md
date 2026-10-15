# Run loop, hub, rewards, meta, UI

## What it does
The game opens on a story intro (once per save, `Meta.seen`), then the tea-house hub.
A run starts in the hub, goes through realm 1 (10 rooms: combat, 2 helper
story rooms, shop, shrine/vault, elite, Butcher King) via reward doors, then returns
to the hub. Meta progress (shards, boss ledger) saves to `user://meta.json`.

## Pages / routes / entry points -> files
| Entry point | Files |
|---|---|
| Story intro (main scene) | `game/scenes/run/intro.tscn`, `game/scripts/ui/story_intro.gd` |
| Hub | `game/scenes/run/hub.tscn`, `game/scripts/run/hub.gd`, `npc.gd` |
| Room scene | `game/scenes/run/room.tscn`, `game/scripts/run/run_room.gd` (extends Arena) |
| Run state (autoload `Run`) - room list, doors, waves | `game/scripts/run/run_state.gd` |
| Doors (built in code: sealed at room start, `unlock` on clear, leaves swing open near the hero) | `game/scripts/run/door.gd` |
| Scene fades (autoload `Fade`), asset cache (autoload `AssetCache`) | `game/scripts/core/fade.gd`, `game/scripts/core/asset_cache.gd` |
| Rewards, shop, shrine | `game/scripts/run/rewards.gd` |
| Boons (12) | `game/scripts/run/boons.gd` |
| Meta save (autoload `Meta`) | `game/scripts/run/meta.gd` |
| UI | `game/scripts/ui/choice_panel.gd`, `dialogue_panel.gd`, `hud.gd`, `boss_bar.gd` |

## Conventions
- One-time boon effects in `apply_once`; behaviour hooks re-equipped per room.
- `ChoicePanel` is modal and pauses the tree.
- The first room always rewards a talisman (`pending_reward` in `start_run`).
- Enemies spawn spread out via `RunRoom._spawn_spot` (>= 7 m from the hero, >= 3 m apart).
- The hub has no talisman picker; shards buy unlocks only.

## What to avoid
- Change scenes with `Fade.to_scene`, not `change_scene_to_file` (no fade, and the room build shows as a frozen frame).
- Don't drop `AssetCache`: without it every room re-reads all models from disk (3-5 s freeze).
- Panels pause the tree: bots driving UI need `process_mode = ALWAYS`.
- Boon rewards were double-counted once; reward changes need a bot check.

## How to verify
| Kind | Command |
|---|---|
| Unit | No run/reward unit tests yet. |
| Gameplay | `res://tests/bot/bot_run.tscn` (10 checks, full run) |

## Last verified
52d9040 on 2026-10-10
