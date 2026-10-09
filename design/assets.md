# Asset manifest: Demon Realm Escape v2

Plan date 2026-10-09. Every asset counted, with its generation phase (= the roadmap milestone that first needs it). Status lives in `assets/manifest.csv` once the M0 tooling exists. This file is the human view.

## Pipeline per asset type (measured on the RTX 4090, 2026-10-09)

| Type | Steps | Time each |
|---|---|---|
| Character (humanoid) | klein concept → TRELLIS.2 textured mesh → prep → UniRig → humanoid rename → Quaternius clips | ≈ 5 s + 100 s + 150 s + 10 s ≈ **4.5 min** |
| Prop (breakable) | klein concept → TRELLIS.2 → prep (+ piece stages) | ≈ **2 min** per mesh |
| Decor (static) | klein → TRELLIS.2 → prep | ≈ **2 min** |
| Tileable texture | klein (seamless prompt) → tile check | ≈ **10 s** |
| Icon / portrait (2D) | klein (icon style prefix) → bg removal → crop | ≈ **10 s** |
| Animation clip | Quaternius retarget (seconds); gaps via Kimodo (≈ secs to gen + retarget) or Blender keyframe script | **< 1 min** |

Plan for re-rolls: ×2 on 3D (generated output varies), ×1.5 on 2D.

## Totals

| Category | M0 | M1 | M2 | M3 | M4 | M5 | M6–M9 | **Total** |
|---|---|---|---|---|---|---|---|---|
| Characters | 1 | 1 | 5 | 0 | 3 | 5 | 8 | **23** |
| Props (breakable) | 1 | 4 | 9 | 0 | 4 | 8 | 16 | **42** |
| Piece meshes (shared) | 0 | 4 | 2 | 0 | 0 | 0 | 0 | **6** |
| Decor (static) | 0 | 2 | 0 | 0 | 6 | 18 | 24 | **50** |
| Tileable textures | 0 | 2 | 0 | 0 | 2 | 7 | 8 | **19** |
| Icons / portraits | 1 | 0 | 4 | 25 | 22 | 9 | 8 | **69** |
| Animation clips | 0 | 15 | 10 | 8 | 7 | 12 | 20 | **72** |

GPU time with re-rolls: **M0–M1 ≈ 1 h, M2 ≈ 1.5 h, M3 ≈ 15 min, M4 ≈ 1.5 h, M5 ≈ 3 h, M6–M9 ≈ 5 h**. Total ≈ 12 h, spread over months, so no single session hogs the PC.

## Phase M0: style lock (3 assets)
- `hero`: Chan-inspired original martial artist, final design (re-gen of the test hero with the art-bible prefix).
- `chair`: style reference prop.
- `icon_sheep`: style reference icon.

## Phase M1: prototype (hero exists → 1 char, 4 props, 4 pieces, 2 decor, 2 textures, 15 clips)
- Characters: `brute` (Sheep host test).
- Props: `bench`, `crate`, `barrel`, `pole` (+ `chair` from M0).
- Pieces (shared by material): `plank`, `wood_leg`, `stake`, `barrel_stave`.
- Decor: `pillar`, `room_door`. Textures: `floor_test`, `wall_test`.
- Clips from Quaternius: idle, walk, run, punch_jab, punch_cross, roll (dodge), hit_chest, death, pickup, sword_attack (light prop swing), crouch_idle (knocked-down hold).
- **Gap clips (Kimodo):** two-hand heavy swing, throw, get-up from knockdown, possession enter (Sheep).

## Phase M2: combat kit (5 chars, 9 props, 2 pieces, 4 icons, 10 clips)
- Characters: `shield_demon`, `thief_imp`, `archer_demon`, `wraith` (spectral shader in Godot), `armored_ghoul`.
- Props: `lantern` (fire), `bucket` (water), `spirit_urn` (magic), `weapon_rack`, `spear`, `stool`, `bun_basket`, `roast_duck`, `fruit_cart` (food).
- Pieces: `pottery_shard`, `metal_scrap`.
- Icons: `dmg_physical`, `dmg_magic`, `elem_fire`, `elem_water`.
- Clips: parry/block, grab, thrown-object catch, shield block, imp sprint-steal, archer throw, wraith float idle, ghoul lurch, chi palm, chi heavy (Kimodo for the non-Quaternius ones).

## Phase M3: talismans (25 icons, 8 clips; no new meshes)
- Icons: 12 talisman icons + 12 talisman "equipped" glyphs + 1 talisman pickup medallion. One 3D medallion mesh with icon decals is made in Godot, not generated.
- Tiger Yin/Yang: material variants of the hero (shader tint), no new mesh.
- Clips: eat (Pig), belly slam, burp blast, ignite prop (Dragon), Ox lift-demon carry/swing, Rooster launcher, Rat talisman throw, Snake shadow-step.

## Phase M4: realm 1 Ember Night Market (3 chars, 4 props, 6 decor, 2 textures, 22 icons, 7 clips)
- Characters: `butcher_king` (boss), `helper_stunt_coordinator`, `helper_street_chef`.
- Props: `market_stall_cart`, `wok`, `hanging_lantern` (fixed), `crate_of_fish`.
- Decor: `stall_awning`, `noodle_stand`, `paper_lantern_string`, `rice_sacks`, `market_gate`, `incense_stand`.
- Textures: `market_floor`, `market_wall`.
- Icons/2D: 2 helper portraits, 12 boon icons, 5 reward-door icons (talisman, boon, draft, gold, shop), gold, shards, shop banner.
- Clips: Butcher King cleaver throw, ground pound, meat-hook pull, roar/intro, stagger (Kimodo); helper idle-talk ×2 (Quaternius `Idle_Talking_Loop`).

## Phase M5: realms 2–3 + hub (5 chars, 8 props, 18 decor, 7 textures, 9 icons, 12 clips)
- Characters: `tea_master` (boss), `harbor_kraken_man` (boss: tentacles = non-humanoid parts, UniRig + custom clips), `helper_old_herbalist`, `helper_street_brawler`, `helper_monk`.
- Props: Teahouse `tea_table`, `teapot`, `folding_screen`, `ice_block`; Docks `oar`, `fishing_net`, `fish_barrel`, `anchor`.
- Decor: 6 per realm (teahouse, docks) + 6 hub tea house.
- Textures: floor + wall per realm + hub floor/wall/roof.
- Icons: 3 helper portraits, 6 more boon icons.
- Clips: Tea Master pour, slide dash, teacup barrage, parry stance; Kraken grab, ink cloud, whirlpool, tentacle idle; 4 boss intros/staggers.

## Phase M6–M9: realms 4–7 (per realm ≈ 2 chars, 4 props, 6 decor, 2 textures, 2 icons, 5 clips)
Opera House (Opera Phantom), Bone Temple (Temple Guardian), Void Bamboo Forest (Shadow Twin), Demon Palace (Demon Lord). Plus enemy realm variants as texture tints, not new meshes.

## Not generated by this pipeline
- **VFX** (chi, fire, possession outline, losing-yourself flicker): Godot shaders/particles, built in code.
- **UI layout**: Godot themes. Icons come from above.
- **Audio** (SFX, music): no local audio pipeline yet. Placeholder free SFX through M4. A separate track to evaluate local audio gen (e.g. Stable Audio Open, ACE-Step) before M5.

## Asset rules
- Every 3D prompt uses the art-bible prefix (M0). Humanoids in A-pose, arms clear of the body (rigging needs it).
- Characters: 1.8 m (bosses 2.2–2.8 m), ≤ 30k tris; props ≤ 5k tris; decor ≤ 8k tris; textures 2048 (characters), 1024 (props/decor).
- Enemies must stay humanoid-ish (shared animation library = cheap Sheep possession). Exceptions: wraith (floats, shared clips + shader), Kraken-man (custom).
- Review renders (front/side/back) before rigging. Re-roll, don't polish bad output.
