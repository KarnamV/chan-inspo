# Fighters and combat

## What it does
One `Fighter` (CharacterBody3D) for Jackie and every demon, with a state machine
(IDLE, ATTACK, DODGE, STAGGER, KNOCKDOWN, GETUP, DEAD, BODY, PICKUP, THROW). Attacks
open `Hitbox`es that hit `Hurtbox`es once per activation; `Health` applies physical or
magic resistances, shatter, parry, shield block and elements.

## Pages / routes / entry points -> files
| Entry point | Files |
|---|---|
| Fighter body + states + `receive_hit` | `game/scripts/fighters/fighter.gd` |
| Fighter stats / attacks data | `game/scripts/fighters/fighter_data.gd`, `game/data/fighters/*.tres` |
| Animations (clip names, fallbacks) | `game/scripts/fighters/anim_driver.gd` |
| Attack timing data | `game/scripts/combat/attack_data.gd` |
| Damage payload | `game/scripts/combat/damage_info.gd` |
| Projectiles (knives, thrown) | `game/scripts/combat/projectile.gd` |
| Hit / hurt / HP / status | `game/scripts/components/hitbox.gd`, `hurtbox.gd`, `health.gd`, `status_fx.gd` |
| Hitstop, shake | `game/scripts/core/juice.gd` |
| Test arenas | `game/scenes/levels/test_room.tscn`, `combat_arena.tscn`, `game/scripts/levels/arena.gd` |

## Conventions
- `Health.take()` returns damage actually taken; emits `damaged`, `died` once.
- Hit reactions go through `Fighter.receive_hit`, not by editing HP directly.
- Element and damage-type rules live in `DamageInfo` / `Health`, not in attackers.

## What to avoid
- Spawning: set `position` before `add_child`.
- Heavy and throw clips are procedural placeholders; do not tune feel against them.
- Knockdown/getup reuse the death clip forwards/backwards (`AnimDriver` fallback).

## How to verify
| Kind | Command |
|---|---|
| Unit | `godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit -gtest=res://tests/unit/test_fighter.gd` (also `test_health.gd`, `test_m2_combat.gd`) |
| Gameplay | `res://tests/bot/bot_m1.tscn`, `res://tests/bot/bot_m2.tscn` |

## Last verified
2c1cee6 on 2026-10-10
