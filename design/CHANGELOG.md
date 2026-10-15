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

## 2026-10-10 gamepad, art polish, story intro
- Gamepad: Inputs tracks last device (`using_pad`), `label()/combo()/controls_line()` → all prompts follow device (HUD slots, NPC prompts, chi draft text, dialogue, intro). Xbox names. Rumble on hits taken/dealt. Pause menu closes with B/Esc/Start. Hub: focus follows scroll, talisman blurb shown on focus (tooltips never show on pad), focus kept after buying.
- Story: new main scene `intro.tscn` (5 klein cards, Ken Burns drift, typed captions, hold-to-skip, once per save, replay button in hub). Auntie Mei (tea house ghost) hub intro + first-room tips. New portraits: Jackie, Auntie Mei. Meta `seen` flags.
- Art: AI floor/wall textures replaced by world-space shaders (flagstone, lacquer wall: no seams, no painted lanterns). Street outside + shop-house silhouettes with lit windows (no black void). AgX tonemap, SSAO, fog, cool moon key + warm lanterns. Embers, hit sparks, dust puffs, blob shadows (jade ring under player). Camera 13 → 11.5.
- UI: project theme (`assets/ui/theme.tres`, built by `tools/build_theme.gd`): Lilita One titles + Nunito body (OFL), lacquer panels, gold trim, jade focus ring. HUD rewritten: round portrait, HP with damage chip, chi bar, cooldown sweep slots, low-HP vignette, controls hint only early.
- Gotcha: `clip_children` on a HUD control → `p_elem->_root` engine error on every scene change (4.7). Masked portrait with a shader instead.
- Bots: m1 now stops when all checks met (demons die faster post-balance); m3 Ox/Dog checks account for getup invuln + hit i-frames. 3/3 stable.

## 2026-10-10 prop wear + prop attack styles
- User: props lose a hit without hitting anything; different props need different attacks.
- Wear leaks found by new tests (`test_prop_wear.gd`): swing at an invulnerable demon (getup/dodge/i-frames) wore the prop; thrown props wore on hitting floor/walls. Fix: `DamageInfo.whiff` set by the target; throws only wear on fighter hits.
- Prop styles (`PropData.attack_style()`: club / long / bulky / small, derived from reach/weight/id, overridable): club swing/chop, long thrust/spin (360 hit), bulky ram (big shove)/slam, small jab/chop. Hit boxes and strike timing per style.
- New procedural clips chop, thrust, spin, ram (pipeline `anim_procedural.py`, + quaternion hemisphere fix) added to hero + 6 humanoid demons. Godot import drops hip rotation → spin turn done on the model in code.

## 2026-10-10 playtest 2 changes
- User: don't replace talismans; start with none and collect; tiny enemy HP bars; faster hits; demons 4–5 hits, spread out, attack only when they see you.
- Talismans: no cap, `PlayerController.collect()`, actives map to 4 slots (mod + light/heavy/grab/dodge) in pickup order; offers skip actives once slots are full, Monkey only after a boss kill. First room always rewards a talisman. Hub picker → shard unlocks only. Intro/Mei lines: talismans scattered into the realm. First-talisman tip.
- Enemy HP bar: billboard shader quad with per-instance ratio + damage chip; hidden until hurt.
- Hero attacks ×0.8 duration; prop swings 0.5/0.75 → 0.42/0.64 s.
- Demon HP: brute 55, shield 45, thief 32, archer 32, wraith 28 (phys resist 0.75 → 0.5), ghoul 38 (phys resist 0.5 → 0.35).
- AI: unaware until sight (7.5 m, ~150° cone) / hearing (2.8 m) / hit; alerts allies within 6 m; "!" mark + reaction delay; wander near spawn. Spawns spread ≥7 m from Jackie, ≥3 m apart, random facing.
- Hurt vignette now scales with damage. Fair probe now starts empty-handed: beats the boss (1 extra life) → may be too easy.

## 2026-10-10 gamepad menus + shop panel
- Bug: A did nothing in menus. Godot 4.7 `ui_accept` = Enter/Space only, no pad button. Fix: `Inputs.UI_BUTTONS` adds A → ui_accept, B → ui_cancel. Shop "freeze" = paused panel A couldn't confirm.
- Bug: shop has 5 cards (4 items + Leave); panel fixed 920 px box, row 1114 px → spilled off right. Fix: CenterContainer, cards 180 px when > 4.
- Confirm press must not act in game (A = dodge). `Input.action_release` not enough: since Godot 4.3 `is_action_just_pressed` stays true rest of frame. Fix: `Inputs.release_gameplay()` mutes 2 frames; gameplay polls `Inputs.just_pressed()`.
- Tests: test_inputs, test_choice_panel (pad A buys from 5-card shop; row fits + centred). 49 pass, 4 bots pass.

## 2026-10-10 standalone exe
- User doesn't want to open Godot each time → Windows export (single exe, pck embedded) + `build_exe.bat`. Official 4.7 export templates installed (Windows only). Rule: rebuild exe after every gameplay/art change.

## 2026-10-10 plan convergence
- User: all plans in one place, referenced from CLAUDE.md. → `design/plan.html` (index, Now, auto progress, roadmap M0–M9 with tasks, waiting-on-user, backlog, assets, risks, process). roadmap.md, STATUS.md, assets.md merged + deleted. Project `CLAUDE.md` added pointing at it.

## 2026-10-10 retro (session 2)
- Lesson: god-mode bots hid that room 1 was unwinnable → run fair probe (`bot_run -- --fair`) before any hand-off (pipeline gotchas + memory).
- Lesson: "low fps" was 60 Hz physics judder + global hitstop, render was ~1600 fps → measure first; physics interpolation on by default (gotchas).
- Lesson: balance changes broke bots that stopped on proxy events / ignored new i-frames → end bots on checks met, re-run 3× (gotchas + memory).
- Lesson: `clip_children` engine error on scene change; decal needs character meshes on own layer (gotchas).
- Lesson: 2D story art = klein with custom width/height, key out white portraits (gotchas).
- User rule: stop ComfyUI when gens are done (memory + pipeline SKILL.md).
- Lesson: PYTHONUTF8=1 for edit scripts; backslash text → script file (memory).
- Board check: still no PRD/slices/board; work tracked in roadmap/STATUS only. Decision pending with user.

## 2026-10-10 retro
- Lesson: gameplay bots in the real scene found 8 bugs unit tests missed → keep per-milestone bots (memory + pipeline gotchas).
- Lesson: show visuals colored and in motion; user had to ask for colors and animations (memory).
- Lesson: TRELLIS fails on thin/open/see-through props; prompt "solid, opaque, chunky", review every asset, time-box re-rolls (pipeline gotchas). Bucket, stool, shard still bad.
- Lesson: asset runner bugs (relative paths, silent stages, VRAM, boss folder name) are fixed and documented; run one runner per manifest.
- Lesson: Godot traps (spawn order, autoloads in -s scripts, class cache, paused bots, typed arrays) → pipeline references/gotchas.md.
- Lesson: on Windows, write scripts to files; run long jobs in the background (memory).
- Drift: no PRD / slices / board for v2 (auto mode skipped them). Decide at next session: create via concept-to-prd + game-board before M5.

## 2026-10-13 polish pass: attack feel, prop moves, hitches
- User: "game needs polish", picked game feel, tech hitches, props + AI; named "clunky attacks, prop attack anim".
- Found by recording `tests/showcase/prop_moves.tscn` frame by frame (not by reading code):
  - Same clip back to back (chop → chop, thrust → thrust, ram → ram, cross → heavy cross) didn't restart: Jackie stood still while the hit landed. `AnimDriver.play` now seeks to 0.
  - Recovery locked until the clip ended; prop swings couldn't queue. Now a queued light chains 35% into recovery (`CHAIN_AT`), moving walks out of recovery, prop lights queue from the windup and alternate swing / backhand chop, prop light → heavy cancels.
  - Prop durations ~10% shorter, heavy-prop slow 1.35 → 1.2.
  - Held props hung limp through the legs: `CarryPose` (SkeletonModifier3D) aims the arms while idle/moving.
  - Bulky props were swung one-handed by the end and flipped upright over Jackie: now held across the chest between both hands. Long props point where they're thrust, out along the arm in a spin.
  - Swing trails (`SwingTrail`) on prop attacks; small camera shake on your own hits; warmer, see-through hit flash (solid white read as a blob); softer dust.
- Hitches: `Arena._prewarm` draws every demon model, hit-flash, HP-bar, trail and particle material once under the floor at room start.
- Possessed host gets a violet floor ring. Exe icon (Jackie, `game/icon.ico`; Godot 4.7 embeds it without rcedit).
- Thief imp: at most 2 steals, fights 4 s after each throw, throws loot after 3.5 s (was 5 s, unlimited).
- Lesson: `--write-movie` and headless runs stretch hitstop (wall-clock), so judge timing with `Juice.enabled = false`.
- Not done: re-keying the procedural chop/thrust/ram/heavy clips (Blender); re-generating bucket/stool/shard (GPU).

## 2026-10-15 room loading + exit doors
- User: "takes time to load the next level"; wants a door that animates open.
- Measured (probe changing rooms in a window): every room change froze 3–5 s, not just the first. Cause: `change_scene` frees the old room, every model/texture refcount hits zero, so the next room re-read ~150 MB of character `.glb`s plus props/decor from disk (hero data ~0.26 s, hero/HUD/props ~1.3 s, `_prewarm` ~1.6 s).
- Fix: `AssetCache` autoload threads-loads `data/fighters`, `data/props`, `assets/{characters,props,pieces,decors,icons,portraits,shaders}`, `scenes/run` at boot (done ~1 s after launch, during the intro) and holds the references forever. Room change now ~85 ms.
- `Fade` autoload: room ↔ room, hub → room, room → hub fade to black, swap, wait 3 frames, fade in.
- Exit doors rebuilt in code (generated gate meshes can't animate): lacquered double door with gold studs, bands and ring pulls, a talisman seal split across the leaves. Doors stand sealed (red seal) from room start; on clear the reward label/icon pop in and the seal turns gold; within 3.4 m the leaves swing inward onto a glowing doorway (dust + small shake); walking into the doorway takes it. Pillars are solid.
- Lesson: Godot's resource cache is not a cache across scene changes — anything not referenced is freed. Hold references in an autoload for anything reused per room.

## 2026-10-15 playtest 3 fixes
- User: can't carry props into new rooms (vault useless); prop hits inconsistent; too little gold; shrines belong later; art grainy/basic; attacks too basic; dodge into enemies inconsistent; parry doesn't work. Decisions (asked): realm 1 rest = vault only; parry merged into dodge; do it all now.
- Bot found during door work: Jackie already standing in a doorway when it unlocked never triggered it (body_entered fires only on entry), so doors also poll overlapping bodies. Space behind doors blocked (got wedged there).
- Cache hang: several threaded loads (or sub-threads) in flight deadlocked the main thread when a room's own `load()` hit a resource mid-load (headless bot froze before room 1). AssetCache now loads one request at a time, no sub-threads (~5 s total, inside the intro; 246/246 in the exported exe); `Fade` calls `wait_all` while black.
- Props carry over: `Run.carried` {id, durability, bonus} stored on leaving; the next room puts it back in Jackie's hands.
- Gold: demons drop 4–7 (+3 in elite rooms), broken props 35% for 1–4; "+N gold" pop with coin glints. Gold door/vault unchanged.
- Realm 1 rest room is the prop vault only; shrine code kept for later realms.
- Prop hits: measured with a probe (passive brute, mashed light chains). Single swings always landed; chains landed 2–8 of 8–13 because each light knocked the demon ~1.4 m away and the windup step was ~0.25 m. Now the player's windup steps in to striking distance of the soft-aim target (`lunge_speed`, up to 11 m/s), prop light knockback x0.6, bulky ram shove 2.0 -> 1.15. Chains now land 7/8 (bulky) and all of them for club/long/small.
- Dodge passes through demons (collision mask world-only during DODGE).
- Parry -> perfect dodge: a dodge whose hit lands within the old parry window (0.22 s, Rabbit x2) staggers the attacker (not bosses), 0.3 s slow-mo, gold ring flash, next hit crits. Later in the i-frames: still avoided, no counter. Parry button now dodges.
- New moves out of the dodge (existing clips): light late in / just after a dodge = dash strike (ram clip, 9 m/s, knockdown); light within 1.2 s of a perfect dodge = counter spin (360 backfist, crit); heavy = leap slam (hop on the model, shockwave ring, knockdown around).
- Render: 4x MSAA, debanding, full-res high SSAO, soft shadow quality high; SSR on. Floor shader filters grout with derivatives (was the shimmer/grain), adds worn centres + grime, darkens toward walls; street dimmer (0.3). Ambient 0.75 -> 0.5 with warm light pools at stalls and mid-room, feathered glossy puddles, screen vignette.
- Lesson: judge "prop hits inconsistent" with a chain probe, not single swings: isolated hits were 100%.
