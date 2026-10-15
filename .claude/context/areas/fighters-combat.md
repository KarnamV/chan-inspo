# Fighters and combat

## What it does
One `Fighter` (CharacterBody3D) for Jackie and every demon, with a state machine
(IDLE, ATTACK, DODGE, STAGGER, KNOCKDOWN, GETUP, DEAD, BODY, PICKUP, THROW). Attacks
open `Hitbox`es that hit `Hurtbox`es once per activation; `Health` applies physical or
magic resistances, shatter, parry, shield block and elements. Player feel: input
buffer, soft auto-aim (`AIM_RANGE`/`AIM_CONE`), light->heavy cancel, dodge-cancel out of
recovery/stagger, post-hit i-frames (`mercy_t` from `data.hit_iframes`). Enemies show a
tiny billboard HP bar once hurt.

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
| Enemy HP bar | `game/scripts/fighters/fighter.gd` (`_make_hp_bar`, `_update_hp_bar`), `game/assets/shaders/enemy_hp.gdshader` |
| Hit sparks, dust, blob shadow, host ring | `game/scripts/core/vfx.gd` |
| Swing trail on prop attacks | `game/scripts/core/swing_trail.gd` |
| Carry pose (arms while holding a prop) | `game/scripts/fighters/carry_pose.gd` |
| Attack-feel showcase (record frames) | `game/tests/showcase/prop_moves.tscn` |
| Test arenas | `game/scenes/levels/test_room.tscn`, `combat_arena.tscn`, `game/scripts/levels/arena.gd` |

## Conventions
- `Health.take()` returns damage actually taken; emits `damaged`, `died` once.
- A hit that passes through (dead, getup, i-frames, perfect dodge, invulnerable) sets
  `info.whiff = true`; attackers skip wear and hitstop on a whiff.
- Hit reactions go through `Fighter.receive_hit`, not by editing HP directly.
- Element and damage-type rules live in `DamageInfo` / `Health`, not in attackers.

## What to avoid
- Spawning: set `position` before `add_child`.
- Heavy, throw, chop, thrust, spin and ram clips are procedural placeholders; do not
  tune feel against them.
- Nodes moved in `_process` need `physics_interpolation_mode = OFF` (interpolation is on).
- A queued light chains at `_chain_point()` (35% into recovery); players walk out of recovery there.
- Judge attack timing on recordings with `Juice.enabled = false`: hitstop runs on wall-clock time and stretches in `--write-movie`/headless.
- Knockdown/getup reuse the death clip forwards/backwards (`AnimDriver` fallback).

## How to verify
| Kind | Command |
|---|---|
| Unit | `godot --headless --path . -s addons/gut/gut_cmdln.gd -gexit -gtest=res://tests/unit/test_fighter.gd` (also `test_health.gd`, `test_m2_combat.gd`) |
| Gameplay | `res://tests/bot/bot_m1.tscn`, `res://tests/bot/bot_m2.tscn` |

## Last verified
52d9040 on 2026-10-10
