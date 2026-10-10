# Run loop, hub, rewards, meta, UI

## What it does
A run starts in the tea-house hub, goes through realm 1 (10 rooms: combat, 2 helper
story rooms, shop, shrine/vault, elite, Butcher King) via reward doors, then returns
to the hub. Meta progress (shards, boss ledger) saves to `user://meta.json`.

## Pages / routes / entry points -> files
| Entry point | Files |
|---|---|
| Hub (main scene) | `game/scenes/run/hub.tscn`, `game/scripts/run/hub.gd`, `npc.gd` |
| Room scene | `game/scenes/run/room.tscn`, `game/scripts/run/run_room.gd` (extends Arena) |
| Run state (autoload `Run`) - room list, doors, waves | `game/scripts/run/run_state.gd` |
| Doors | `game/scripts/run/door.gd` |
| Rewards, shop, shrine | `game/scripts/run/rewards.gd` |
| Boons (12) | `game/scripts/run/boons.gd` |
| Meta save (autoload `Meta`) | `game/scripts/run/meta.gd` |
| UI | `game/scripts/ui/choice_panel.gd`, `dialogue_panel.gd`, `hud.gd`, `boss_bar.gd` |

## Conventions
- One-time boon effects in `apply_once`; behaviour hooks re-equipped per room.
- `ChoicePanel` is modal and pauses the tree.

## What to avoid
- Panels pause the tree: bots driving UI need `process_mode = ALWAYS`.
- Boon rewards were double-counted once; reward changes need a bot check.

## How to verify
| Kind | Command |
|---|---|
| Unit | No run/reward unit tests yet. |
| Gameplay | `res://tests/bot/bot_run.tscn` (10 checks, full run) |

## Last verified
2c1cee6 on 2026-10-10
