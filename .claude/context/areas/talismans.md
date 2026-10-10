# Talismans, player controller, possession

## What it does
The player equips 3 of 12 zodiac talismans. `PlayerController` owns non-body state:
spirit meter, equipped talismans, boons, which Fighter is controlled, camera target.
Sheep = possession (brain + team swap; Jackie's body lies vulnerable). Tiger splits
Yin/Yang, Monkey becomes a killed boss (BossKit), Rat/Dog use ally AI.

## Pages / routes / entry points -> files
| Entry point | Files |
|---|---|
| Player state, spirit, chi | `game/scripts/player/player_controller.gd` |
| Talisman base (equip/unequip/activate/tick/on_controlled_changed/on_room_cleared) | `game/scripts/talismans/talisman.gd` |
| All 12 talismans (`Zodiac.make(id)`) | `game/scripts/talismans/zodiac.gd` |
| Monkey boss forms | `game/scripts/fighters/boss_kit.gd` |
| Signals (possession, tiger, monkey, dog...) | `game/scripts/core/events.gd` |
| Talisman test keys | arenas: keys 1-0, -, = swap talismans |

## Conventions
- Talisman effects hook through the base-class callbacks; per-room behaviour is
  re-equipped each room.
- Spirit changes emit `Events.spirit_changed`.

## What to avoid
- Sheep economy is tuned deliberately (see decisions.md); do not change costs in code.
- Possession must keep Jackie's body hittable (body hit snaps back with a penalty).

## How to verify
| Kind | Command |
|---|---|
| Unit | `... -gtest=res://tests/unit/test_talismans.gd`, `test_possession.gd` |
| Gameplay | `res://tests/bot/bot_m3.tscn` (19 checks) |

## Last verified
2c1cee6 on 2026-10-10
