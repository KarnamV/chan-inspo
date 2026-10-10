# Brains (player input, enemy AI, allies, boss)

## What it does
Decides what a `Fighter` does each physics frame. `PlayerBrain` reads input; `AIBrain`
runs the three demon behaviours (melee, thief, ranged) behind an awareness gate (demons
wander until they see or hear you); `AllyBrain` drives Tiger/Rat/Dog
allies; `BossBrain` uses `BossKit` signature moves. Possession swaps a fighter's brain.

## Pages / routes / entry points -> files
| Entry point | Files |
|---|---|
| Base class (`think(f, delta)`) | `game/scripts/brains/brain.gd` |
| Player control | `game/scripts/brains/player_brain.gd`, `game/scripts/core/inputs.gd` |
| Awareness: sight/hear, "!" marker, alerting others, wandering | `game/scripts/brains/ai_brain.gd` (`notice`, `_alert_others`, `_wander`; `SIGHT`, `HEAR`, `ALERT_RADIUS`) |
| Attack turn-taking (max 2 per target, others circle) | `game/scripts/brains/ai_brain.gd` (`_may_attack`, `_wait_turn`, `MAX_ATTACKERS`) |
| Player input buffer (0.25 s), talisman modifier buttons | `game/scripts/brains/player_brain.gd` |
| Melee demons (brute, shield, wraith, ghoul) | `game/scripts/brains/ai_brain.gd` (`think`, `_turn`, `_melee`) |
| Thief imp (`AiKind.THIEF`) | `game/scripts/brains/ai_brain.gd` (`_thief`), `game/data/fighters/thief_imp.tres` |
| Archer (`AiKind.RANGED`) | `game/scripts/brains/ai_brain.gd` (`_ranged`), `game/data/fighters/archer_demon.tres` |
| Allies | `game/scripts/brains/ally_brain.gd` |
| Boss (Butcher King) | `game/scripts/brains/boss_brain.gd`, `game/scripts/fighters/boss_kit.gd` |
| AI kind / tuning fields | `game/scripts/fighters/fighter_data.gd` (`AiKind`, `aggro_range`, `attack_range`, `attack_cooldown`, `keep_distance`) |

## Conventions
- Brains only set `f.intent_move`, `f.facing` and call `f.request_*()`. Never move or
  damage directly.
- Turning goes through `_turn()` (turn rate), not by assigning `facing`, for melee AI.
- Target re-pick runs every 0.4 s (`think_t`), not every frame.

## What to avoid
- Thief must never flee forever: with nothing to steal it fights (`_melee`). Keep that
  fallback in any thief change.
- `_thief` counts `carry_t += 0.016` per think instead of using `delta`, so the 5 s loot
  timer depends on frame rate. Use `delta` in new timers.
- Shield demon must not snap-face the player (flanking must work).
- Demons must not attack before they notice the player (playtest 2). New AI kinds go
  through `notice` too.
- AI numbers inside `ai_brain.gd` (12.0 steal radius, 7.0 corner bounds, 5.0 carry
  time, 0.7 loot speed) are inline. New tunables go to `FighterData`.

## How to verify
| Kind | Command |
|---|---|
| Unit | No AIBrain unit tests yet. Add `tests/unit/test_ai_brain.gd`. |
| Gameplay | `godot --headless --path . --fixed-fps 60 res://tests/bot/bot_m2.tscn` (all 6 demon types) |

## Last verified
52d9040 on 2026-10-10
