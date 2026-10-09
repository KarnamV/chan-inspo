# Changelog

## 2026-10-09
- Scaffolded design/ (game-dev-index).
- v1 (2.5D sprite Demon Realm Escape) archived → `archive/demon-realm-escape/`. WIP snapshot commit first, nothing lost.
- New concept chosen: Demon Realm + props-as-weapons; possession only via Sheep talisman. Isometric 3D, Godot 4.7, hobby scope. → `design/concept.md`.
- Talismans set by user: **Tiger** = split into Yin (magic dmg+, HP−) / Yang (phys dmg+, HP+); both fight, swap control. **Monkey** = shapeshift into any boss ever killed (meta), keeps ≥3 moves. **Pig, Dragon** = magic damage sources.
- New systems: physical/magic damage types; move draft (rewards turn physical moves into magic versions).
- All 12 talismans set (one-by-one review): Rat animate props, Ox strongman, Rabbit quick feet (wider dodge/parry window), Snake shadow coil, Horse lifesteal, Rooster juggle, Dog loyal, Pig feast, Dragon fire. Ally AI shared by Tiger/Rat/Dog.
- Systems set: spirit fill via **helpers** (met at a fixed level, then boon room rewards: fill rules, talisman upgrades, damage, lives, saves); props degrade into pieces + element tags, throw & catch, fixed props, shatter; v1 moves light/heavy/grab-throw/dodge/parry; bare hands scale with draft; Sheep body lies vulnerable, protected by talisman synergies; **dual-variant moves** (L2 + button = chi version, unlocked/upgraded by draft, costs spirit); L1 + button = talismans.
