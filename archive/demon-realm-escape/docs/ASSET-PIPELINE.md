# AI Asset Pipeline — Demon Realm Escape

How art, animation, and audio get produced with AI tools and dropped into the
Godot game. The game is fully playable **without** any of these — every asset
slot degrades gracefully (placeholder textures, silent audio) until a real file
replaces it, so production can happen incrementally in any order.

> Tooling in reach: **Blender** (driven directly via the Blender MCP from this
> agent), any **image-generation AI** (sprites/icons/tiles/UI), and **audio-gen
> AI** (SFX + music). Cleanup in Blender / an image editor / Audacity as needed.

---

## 1. Art direction

- **Look:** 2.5D top-down. Characters read as solid 3/4-view figures on a dark,
  moody demon-realm floor. Jackie-Chan-inspired martial artist; enemies are
  demons, possessed warriors, beasts.
- **Technique — pre-rendered sprites:** model + animate in **Blender**, render
  from a fixed 3/4 top-down camera into **sprite sheets**. This gives consistent
  lighting/volume across 8 facings and is far faster than hand-drawing frames.
  (Classic Diablo / Donkey Kong Country approach.)
- **2D art (icons, tiles, UI, backgrounds):** image-gen AI, style-locked with a
  shared prompt suffix, then cleaned up (alpha cut, palette match, downscale).
- **Palette:** warm ambers/reds + jade + gold accents (already used in the HUD
  and kanban theme). Each realm has its own accent (see `RealmDefs.gd`).

---

## 2. Full asset spec

### 2.1 Characters (animated sprite sheets)

Render **8 directions** (N, NE, E, SE, S, SW, W, NW) where possible; 4 (N/E/S/W
mirrored) is an acceptable first pass. Target on-screen height ≈ 48–64 px, so
render at 2–4× (128–256 px) and downscale.

| Character | Animation states (clips) |
|-----------|--------------------------|
| **Player (Jackie)** | idle, walk, punch, kick, throw, dash_attack, dodge, block, hurt, dead |
| **Demon** (ranged) | idle, move, cast, hurt, death |
| **Possessed Warrior** (melee) | idle, move, windup, strike, hurt, death |
| **Beast** (rusher) | idle, move, rush, hurt, death |
| **Mini-boss** | idle, move, windup, strike, hurt, death (bigger, menacing) |

Clip → game state mapping for the Player is driven by `Player.gd`'s `State`
enum + `facing_dir` (see §4.1).

### 2.2 Talisman icons — 10 × 64×64 (image-gen)

Yin-Yang · Dragon Claw · Phoenix Feather · Tiger Fang · Snake Coil ·
Monkey Step · Crane Wing · Demon Seal · Void Star · Heaven's Token.
Consistent circular seal frame; realm-agnostic; transparent background.

### 2.3 Environment / tiles (image-gen + optional Blender props)

- Floor + wall tiles per realm theme (7). Seamless/tileable, 128×128.
  Currently `RoomRenderer` draws flat `ColorRect`s tinted by `realm_floor_color`.
- Door archway, shrine altar, temptation altar, shop stall props.
- Gold coin sprite (currently code-drawn in `GoldPickup._draw`).

### 2.4 UI (image-gen)

Panel backgrounds, HP/spirit bar frames, button skins (normal/hover/disabled),
a title treatment for the Hub. A display font pick (e.g. a wuxia-flavored TTF).

### 2.5 VFX (optional sprite-based, on top of code particles)

Slash arcs, impact flashes, talisman auras. Current juice is code-only
`CPUParticles2D` via `FX.gd` — sprite sheets can layer on later.

### 2.6 Audio

SFX keys (drop `<key>.ogg` in `game/assets/audio/sfx/`):
`hit`, `big_hit`, `enemy_death`, `player_hurt`, `coin`, `talisman`, `ui_open`,
`purchase`, `miniboss`.

Music (drop `<name>.ogg` in `game/assets/audio/music/`):
`realm_0`…`realm_6` (one loop per realm), `hub`, optional `miniboss`.

---

## 3. Production workflows

### 3.1 Blender → sprite sheet (characters)

1. **Model** a low-poly character (or start from a Meshy/Rodin/other AI base
   mesh, then retopo/clean in Blender).
2. **Rig** — Rigify or a simple armature. Retarget Mixamo humanoid animations
   for the shared locomotion/combat set where useful.
3. **Camera** — orthographic, fixed 3/4 top-down angle (~55–60° tilt) to match
   the game's perspective. Toon/flat shading via a small node setup; render with
   alpha (`film_transparent = True`).
4. **Batch render** with `bpy` (the agent can run this over the Blender MCP):
   for each `direction` (rotate the rig root in 45° steps) × each `action` ×
   each `frame`, set the frame and render to
   `sprites/<char>/<action>_<DIR>/<frame>.png`.
5. **Pack** frames into a grid sheet (or import loose frames straight into a
   Godot `SpriteFrames`).

### 3.2 Image-gen (icons / tiles / UI)

1. Generate at high resolution with a **style-locked prompt** (shared suffix:
   art direction, palette, lighting, "game asset, centered, plain background").
2. **Cut alpha** (remove background), **downscale** to target, **palette-match**
   to the game's colors.
3. For tiles, verify **seamless tiling** (offset test) before export.

### 3.3 Audio-gen (SFX / music)

1. **SFX:** generate short clips (AI SFX tool or synth), trim, normalize, export
   mono `.ogg`. Keep < 1s and punchy — they pair with `FX.hitstop`/`shake`.
2. **Music:** generate loopable realm themes (~60–120s), confirm a clean loop
   point, export stereo `.ogg` at ~-14 LUFS.

---

## 4. Godot integration

### 4.1 Characters: `Sprite2D` → `AnimatedSprite2D`

Once a character's `SpriteFrames` exists, in that character's `.tscn` replace the
`Sprite2D` with an `AnimatedSprite2D` and assign the resource. Name clips
`<state>_<DIR>` (e.g. `walk_S`, `punch_E`). Drive it from the existing state
machine — e.g. in `Player.gd`, map `state` + `facing_dir` to a clip name and
call `$AnimatedSprite2D.play(clip)`. The `facing_dir` → 8-way suffix is a small
helper (angle → one of N/NE/E/SE/S/SW/W/NW). No combat logic changes — the state
machine already exists; this only swaps the visual.

### 4.2 Tiles: `RoomRenderer`

Swap the flat floor `ColorRect` for a tiled texture (per-realm), keyed off the
same `realm_floor_color` hook (add a `realm_floor_texture`). Walls likewise.

### 4.3 Icons / UI

HUD talisman label → a `TextureRect` fed by an icon per talisman
(`talisman_display_name()` → icon path). Shop/shrine/temptation panels can adopt
the button/panel skins.

### 4.4 Audio — already wired ✅

`AudioManager` (autoload) is live and called from every relevant event. It looks
up files by key/name and **no-ops when absent**. Dropping a correctly-named file
into `assets/audio/sfx|music/` makes it play — no code changes. See the READMEs
in those folders.

---

## 5. Suggested production order

1. **Player sheet** + core SFX (`hit`, `enemy_death`, `player_hurt`, `coin`) —
   biggest felt improvement.
2. **Enemy sheets** (Demon, Warrior, Beast).
3. **Realm tiles** (start with realm 0, then reuse the pipeline for 1–6).
4. **Talisman icons** + UI skin.
5. **Music** (hub first, then realms).
6. **Mini-boss sheet** + sprite VFX.

---

## 6. Status

- [x] Audio system (`AudioManager`) + event hooks + drop folders — **done**
- [x] Asset folder structure + specs — **done**
- [ ] Player sprite sheet (Blender)
- [ ] Enemy sprite sheets (Blender)
- [ ] Realm tiles / props (image-gen + Blender)
- [ ] Talisman icons + UI (image-gen)
- [ ] SFX set (audio-gen)
- [ ] Music set (audio-gen)
- [ ] Godot wiring: `AnimatedSprite2D` swap, tile textures, icon `TextureRect`s
