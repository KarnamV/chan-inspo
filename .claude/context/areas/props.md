# Props

## What it does
Props are weapons. `Prop` (RigidBody3D + `PropData`) goes FREE -> HELD (attached to the
`RightHand` bone) -> swung (wear) or THROWN (damages on contact) -> BROKEN, then spawns
`data.pieces`. Wear only counts on hits that connect. Each prop has an attack style
(`PropData.attack_style()`): club = swing/chop, long = thrust/spin, bulky = ram/slam,
small = jab/chop. Fixed props (hanging lanterns, weapon rack) react in place.

## Pages / routes / entry points -> files
| Entry point | Files |
|---|---|
| Prop lifecycle | `game/scripts/props/prop.gd` |
| Prop data | `game/scripts/props/prop_data.gd`, `game/data/props/*.tres` |
| Fixed props | `game/scripts/props/fixed_prop.gd` |
| Attack styles (clips, hit shapes, timing) | `game/scripts/props/prop_data.gd` (`style`, `attack_style`, `SMALL`), `game/scripts/fighters/fighter.gd` (`_prop_attack`) |
| Grab / throw requests | `game/scripts/fighters/fighter.gd` (`request_grab`, `held_prop`, `nearest_prop`) |
| Models | `game/assets/props/*.glb`, `game/assets/pieces/*.glb` (Git LFS) |

## Conventions
- Loose props and pieces parent to the `level_root` group node.
- Long props spawn lying down.
- Override the derived style with `PropData.style` in the `.tres`, not with a new code branch.

## What to avoid
- Bucket, stool and pottery shard meshes are bad; bucket + stool are out of the realm-1
  pool. Do not add them back without new assets.
- Asset fixes are not code work: they go through the asset pipeline, not this loop.

## How to verify
| Kind | Command |
|---|---|
| Unit | `... -gtest=res://tests/unit/test_prop.gd`, `test_prop_wear.gd` |
| Gameplay | `res://tests/bot/bot_m1.tscn` (grab, break), `bot_m2` (kickable, thrown props) |

## Last verified
52d9040 on 2026-10-10
