# Jackie's Demon Realm Escape — Roguelite Game Design

## Core Concept

Jackie (Chan-inspired martial artist) trapped in demon realm. Fight through procedurally generated levels. Collect talismans with unique powers to break free. Permadeath + meta-progression between runs.

## Game Design

### Premise
A demon lord has imprisoned Jackie in the demon realm. Each death sends him back to start — but he retains learned techniques and unlocked talismans for next run. Break through 7 realms -> final boss -> escape.

### Core Loop
```
Start run -> Fight enemies across randomized rooms -> Collect talismans & gold -> Shop between levels -> Die or reach top -> Keep unlockables -> Repeat, progressively stronger
```

### Gameplay Mechanics

#### Combat (real-time, side-view beat-em-up)
- 4 basic attacks: punch, kick, throw, jump-kick
- Combo system: sequences build "martial spirit" meter
- Dodge roll (i-frame invincibility), block (stagger guard)
- Jackie Chan style: environment kills (throw objects), acrobatic moves

#### Talisman System (core progression)
Each talisman grants a persistent ability — equip 3 at start of run, find more to swap.

| Talisman | Effect | Rarity |
|----------|--------|--------|
| **Yin-Yang** | Toggle light/dark stance -> different attack types | Common |
| **Dragon Claw** | Unleash claw slash AoE (costs spirit) | Uncommon |
| **Phoenix Feather** | Heal 20% on kill | Uncommon |
| **Tiger Fang** | Dodge counter -> massive damage burst | Rare |
| **Snake Coil** | Chain light between nearby enemies | Rare |
| **Monkey Step** | Double jump + air control | Uncommon |
| **Crane Wing** | Parry window expands -> stagger on parry | Rare |
| **Demon Seal** | Absorb one hit, explode afterward (1 use) | Epic |
| **Void Star** | Teleport short distance, leave afterimage decoy | Rare |
| **Heaven's Token** | Call random power-up (5s cooldown) | Legendary |

#### Room Structure
- 7 realms (increasing difficulty)
- Each realm: 8-12 rooms with 3 exits (pick one path)
- Enemy types: demons, possessed warriors, beasts, bosses
- Interstitial rooms: shops, shrines (blessings), puzzles, rest spots

#### Progression Within Run
- Gold drops from enemies -> spend in shops
- Shops sell: talismans, upgrades, healing items, info
- Shrine rooms: sacrifice gold for random blessing OR restore HP
- Mini-bosses at realm boundaries -> drop guaranteed talisman or upgrade

#### Meta-Progression (outside runs)
- Persistent currency: "Spirit Shards" from each run (based on distance + foes defeated)
- Unlock permanent upgrades in hub area:
  - More starting talisman slots
  - New base moves
  - Passive stat boosts (HP, damage, speed)
  - New character variants with unique start-talisman
- Unlock new realms after beating previous max

#### Death & Run Scumming Tradeoff
- Die -> return to hub with Spirit Shards
- Some items are run-only (consumables purchased in shops die on death)
- Talismans unlocked permanently persist across runs
- "Temptation" rooms: risk gold/shards for powerful but cursed power-ups

## Tech Stack Recommendation

### Engine & Framework
**Recommendation: Godot 4.x (GDScript/C#)**

Why:
- Free, open-source, lightweight (~100MB)
- Excellent 2D support — ideal for side-view roguelite
- Node scene tree maps perfectly to room/enemy/talisman components
- Built-in tilemap + tileset editors
- Export to Windows/macOS/Linux/Android/iOS/WebGL easily
- GDScript is Python-like, fast iteration. C# via monodroid if needed
- Alternative: **Unity** (larger, heavier, C#, better asset store) or **HaxeFlixel** (lightweight open-source, but smaller community)

### Language
- **GDScript** for gameplay logic (fast dev cycle)
- **C#** optional — use if writing complex systems (save system, network multiplayer later)

### Art & Assets
- **Aseprite** or **LibreSprite** (pixel art)
- **Inkscape** (vector sprites/props)
- **Kenney.nl** packs for placeholder art
- **OpenGameArt.org** for free assets
- Animation: skeletal via **Spine** or hand-drawn sprite sheets

### Audio
- **LMMS** or **Audacity** for music/SFX creation
- **Bosca Ceoil** (simple chiptune composer)
- Free SFX: **freesound.org**, **opengameart.org/sfx**

### Additional Tools
| Tool | Purpose |
|------|---------|
| **Tiled Map Editor** | Level layout (or Godot's built-in tilemap) |
| **Git + GitHub/GitLab** | Version control |
| **VS Code** or **Godot Editor** | IDE |
| **Draw.io / Excalidraw** | Design docs, flow diagrams |

## Architecture Overview

```
Main Menu
  -> Hub (meta-progression shop)
  -> Select Realm
     -> Room Manager (procedural room selection)
        -> Level Scene (rooms with enemies, pickups)
           -> Player Controller
              -> Combat System
              -> Talisman Manager
              -> Stamina/Spirit Bar
           -> Enemy AI Controller (state machine per type)
           -> Prop/Environment objects
        -> Room Transitions
     -> Shop Interface
     -> Boss Scene
  -> Death Screen + Spirit Shard tally
  -> Perma-upgrade Menu
```

## Prerequisites Checklist

### Must Have
- [ ] Godot 4.x installed
- [ ] Git installed + GitHub account (or local repo)
- [ ] Code editor: VS Code or Godot built-in
- [ ] Art tool of choice (Aseprite, Krita, LibreSprite)
- [ ] Audio tool (Audacity for SFX at minimum)

### Nice to Have
- [ ] Pixel art references for Jackie Chan movie stills / martial arts poses
- [ ] Reference roguelites: Binding of Isaac, Dead Cells, Enter the Gungeon, Hades
- [ ] Understanding of finite state machines (for enemy AI)
- [ ] Basic knowledge of procedural generation concepts (room graphs, BSP trees, noise functions)

### Technical Requirements
- [ ] 4GB+ RAM minimum
- [ ] Windows 10/11 target platform
- [ ] ~2GB disk space for Godot + assets
- [ ] Target: 60fps at 720p minimum

## Recommended Dev Phases

### Phase 1: Prototype (Week 1-2)
- Basic player movement + combat (4 attacks, dodge)
- One room with dummy enemies
- One talisman working
- Verify core combat feels good

### Phase 2: Core Systems (Week 3-5)
- Room generation (simple graph of rooms)
- Enemy AI (3 enemy types)
- Talisman system (4 talismans)
- Health, spirit meter, HUD
- Death + respawn loop

### Phase 3: Progression (Week 6-8)
- Shop between levels
- Spirit shard meta-currency
- Hub area UI
- Perma-upgrades
- 7 realm themes

### Phase 4: Polish (Week 9-12)
- Art passes, animations, VFX
- Sound design + music
- Particles, screen shake, hitstop
- Bug fixes, balance pass
- Build + distribute

## Key Design Principles

1. **Combat first.** If fighting doesn't feel satisfying, nothing else matters. Prototype combat in day one.
2. **Talisman variety.** Each talisman should enable a distinct playstyle. Avoid overlap.
3. **Risk/reward everywhere.** Every room choice is a gamble. Players should feel tension.
4. **Readability > complexity.** Player must always see what's happening. Clear telegraphs for enemy attacks.
5. **Fast runs.** 10-20 minute runs max. Short sessions = more attempts = more fun.
6. **"One more run" loop.** Death gives something (shards/progress). No wasted effort.
