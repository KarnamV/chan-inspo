# Talismans, player controller, possession

## What it does
The player starts with no talismans and collects them from rewards; nothing is ever
replaced. Actives run on cooldowns and fill 4 slots (talisman modifier + light, heavy,
grab or dodge); spirit (chi) only pays for chi moves. `PlayerController` owns non-body
state: spirit meter, collected talismans, boons, which Fighter is controlled, camera target.
Sheep = possession for 10 s (brain + team swap; Jackie's body lies vulnerable). Tiger splits
Yin/Yang, Monkey becomes a killed boss (BossKit), Rat/Dog use ally AI.

## Pages / routes / entry points -> files
| Entry point | Files |
|---|---|
| Collect / active slots | `game/scripts/player/player_controller.gd` (`collect`, `actives`, `ACTIVE_SLOTS`) |
| Talisman offers (skip actives when slots full; Monkey only with a boss ledger) | `game/scripts/run/rewards.gd` (`_talisman_offers`) |
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
- Talisman cooldowns and Sheep duration are tuned deliberately (see decisions.md); do
  not add spirit costs back.
- Possession must keep Jackie's body hittable (body hit snaps back with a penalty).

## How to verify
| Kind | Command |
|---|---|
| Unit | `... -gtest=res://tests/unit/test_talismans.gd`, `test_possession.gd` |
| Gameplay | `res://tests/bot/bot_m3.tscn` (19 checks) |

## Last verified
52d9040 on 2026-10-10
