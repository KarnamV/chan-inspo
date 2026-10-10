# Changelog

## 2026-10-09
- Scaffolded design/ (game-dev-index).
- v1 (2.5D sprite Demon Realm Escape) archived → `archive/demon-realm-escape/`. WIP snapshot commit first, nothing lost.
- New concept chosen: Demon Realm + props-as-weapons; possession only via Sheep talisman. Isometric 3D, Godot 4.7, hobby scope. → `design/concept.md`.
- Talismans set by user: **Tiger** = split into Yin (magic dmg+, HP−) / Yang (phys dmg+, HP+); both fight, swap control. **Monkey** = shapeshift into any boss ever killed (meta), keeps ≥3 moves. **Pig, Dragon** = magic damage sources.
- New systems: physical/magic damage types; move draft (rewards turn physical moves into magic versions).
- All 12 talismans set (one-by-one review): Rat animate props, Ox strongman, Rabbit quick feet (wider dodge/parry window), Snake shadow coil, Horse lifesteal, Rooster juggle, Dog loyal, Pig feast, Dragon fire. Ally AI shared by Tiger/Rat/Dog.
- Systems set: spirit fill via **helpers** (met at a fixed level, then boon room rewards: fill rules, talisman upgrades, damage, lives, saves); props degrade into pieces + element tags, throw & catch, fixed props, shatter; v1 moves light/heavy/grab-throw/dodge/parry; bare hands scale with draft; Sheep body lies vulnerable, protected by talisman synergies; **dual-variant moves** (L2 + button = chi version, unlocked/upgraded by draft, costs spirit); L1 + button = talismans.
- Systems set (cont.): 7 realms (demon-twisted real places, own prop families; ship realms 1–3 first); special rooms shop/shrine/temptation/prop vault; meta = shards, boss ledger (Monkey 3→5 moves), prop codex, helper bonds; 6 enemy archetypes (wraith resists physical, ghoul resists magic); 3 milestone-1 bosses with Monkey kits. Concept brainstorm complete.
- Monkey changed: full boss moveset (not 3 moves), other talismans usable while transformed, limited by an attack count before a forced revert ("lose yourself to the demon"); boss ledger now raises the attack limit.
- Plan: `design/roadmap.md` (M0 style lock → M1 prototype go/no-go → M2 combat → M3 talismans → M4 realm 1 slice → M5 realms 1–3 release → M6–M9 realms 4–7) + `design/assets.md` (23 chars, 42 props, 6 pieces, 50 decor, 19 textures, 69 icons, 72 clips; generated just in time per milestone, ≈12 h GPU total).
- **Art style locked: stylized low-poly** (`design/art-bible.md`). Chosen after all 4 styles ran the full chain (rig + walk/run + Godot); chunky rejected for animation cost, painterly for readability. Hero + chair promoted to `art/`. Git LFS for .glb/.fbx/.blend/audio/.mp4; style-test intermediates ignored.

## 2026-10-09 (auto run M0 → M4)
- M0: icon style flat vector; asset runner + manifest (83 rows); Godot 4.7 skeleton (GUT, iso camera).
- M1: fighters with swappable brains (possession = brain swap), props degrade into pieces, Sheep. Bot 7/7.
- M2: parry, catch, shield block (+ guard break on heavy/knockdown hits, magic passes through, slow turn so flanking works), fire/water/magic elements, chi palm/wave/pull/blink (locked until drafted), thief + archer AI, projectiles, kickable props, hanging lanterns, weapon rack. Bot: all 6 demon types.
- M3: all 12 talismans + shared ally AI; Monkey = full boss kit (BossKit shared by boss AI and player). Bot 19/19.
- M4: run state + meta save, realm 1 = 10 rooms (combat, 2 helper story rooms, shop, shrine/vault, elite, Butcher King), reward doors, 12 boons, move draft, tea-house hub. Full-run bot 10/10.
- Design changes made during the run (user to confirm): Sheep 40 spirit = requirement, no up-front charge (drains 7/s); thief fights when nothing to steal, throws loot after ~5 s; shield demon turn speed 1.5 rad/s + guard break.

## 2026-10-10 playtest fix: clunky combat
- User playtest: "clunky", overwhelmed in room 1, "can't attack". Asked: talismans no chi cost; chi only for chi moves; more fluid moves / more fps.
- Talismans: spirit cost → cooldowns (Sheep 12 s after possession ends, Tiger 20 s after merge, Monkey 30 s after revert, Rat 8, Pig burp 6, Dragon 8). Sheep possession = 10 s timer (no drain). HUD shows cooldown seconds.
- Fluidity: 0.25 s input buffer (presses during attacks/stagger no longer dropped); player dodge cancels attack recovery + stagger after 0.15 s; light → heavy cancel; soft auto-aim (snap to enemy within 3.2 m / ~60°); getup invulnerable; hero 0.4 s hit i-frames, stagger ×0.6.
- Hero: 3-hit combo (jab 9 → cross 11 → finisher 15), faster jab/cross, heavy 16, move 6.0.
- AI: max 2 demons attack one target at once; others circle.
- Feel/fps: render was already ~1600 fps; judder came from 60 Hz physics with no interpolation → physics interpolation on, camera follows interpolated transform. Hitstop only on the player's own hits (crowd hits used to freeze the game constantly). Hit-flash no longer walks the mesh tree every frame.
- Balance: demons damage ×0.65, HP ×0.75, attack cooldown ×1.2 (shield/wraith 1.9 s); archer knife 8 → 5; Butcher King damage ×0.75, HP ×0.85.
- Probe: `bot_run -- --fair` (real HP, no-dodge bot). Before: died room 1 (22 s). After: reached room 9/10.

## 2026-10-10 retro
- Lesson: gameplay bots in the real scene found 8 bugs unit tests missed → keep per-milestone bots (memory + pipeline gotchas).
- Lesson: show visuals colored and in motion; user had to ask for colors and animations (memory).
- Lesson: TRELLIS fails on thin/open/see-through props; prompt "solid, opaque, chunky", review every asset, time-box re-rolls (pipeline gotchas). Bucket, stool, shard still bad.
- Lesson: asset runner bugs (relative paths, silent stages, VRAM, boss folder name) are fixed and documented; run one runner per manifest.
- Lesson: Godot traps (spawn order, autoloads in -s scripts, class cache, paused bots, typed arrays) → pipeline references/gotchas.md.
- Lesson: on Windows, write scripts to files; run long jobs in the background (memory).
- Drift: no PRD / slices / board for v2 (auto mode skipped them). Decide at next session: create via concept-to-prd + game-board before M5.
