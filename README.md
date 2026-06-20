# chan-inspo

Jackie Chan–inspired games.

## Games

1. **Demon Realm Escape** — a 2.5D top-down roguelite built in Godot 4. *Developed first, fully standalone.* Design: [`GAME-design.md`](GAME-design.md).
2. **Unity open-world sandbox** — a *Jackie Chan Adventures*–style third-person open world (Unity 6 + URP). **Parked — to plan later**, after the roguelite ships.

## Getting Started

### Prerequisites

- **Godot 4.7+** — install via winget: `winget install -e --id GodotEngine.GodotEngine`
- **VS Code** (optional, for editing) — install the [godot-tools](https://marketplace.visualstudio.com/items?itemName=geequlim.godot-tools) extension, then set Godot's external editor to `Code.exe` with flags `{project} --goto {file}:{line}:{col}`

### Running the game

1. Open Godot and click **Import**
2. Select `game/project.godot`
3. Press **F5** (or the ▶ Run button) to start

### Controls

| Key | Action |
|-----|--------|
| WASD / Arrow keys | Move (8 directions) |
| Shift | Walk (slower / precise) |
| Z | Punch |
| X | Kick |
| C | Throw |
| V | Dash attack (directional lunge) |
| Space | Dodge roll |

## Dev Phases & Testable Milestones

Each phase ends with something you can open, play, and judge before the next phase starts.

### Phase 0 — Setup ✅
Open `game/` in Godot 4. Press F5. A blue rectangle moves in 8 directions on a dark floor. Camera follows smoothly. Y-sort depth is active. **If this runs: Phase 0 done.**

### Phase 1 — Prototype (in progress)
Open the test room. Move, punch, kick, throw, and dash into dummy enemies. Dodge roll through attacks. Toggle the Yin-Yang talisman. **Gate:** if fighting feels fun and responsive, proceed to Phase 2. If not, stop and fix — combat feel is the entire point of this phase.

### Phase 2 — Core Systems
Start a run from the hub. Clear a room of real enemies (3 types), pick a door, clear 2 more rooms, fight a mini-boss. Die → return to hub with Spirit Shards. **Gate:** can you play a full room sequence without soft-locking?

### Phase 3 — Progression
Complete a run with all systems live: buy from a shop, hit a shrine, unlock a realm, spend Shards on a perma-upgrade. **Gate:** does a second run feel meaningfully different from the first?

### Phase 4 — Polish
Record a 10–20 minute gameplay clip. Watch it back. Does it look and feel like a finished game worth sharing? **Gate:** yes → build and distribute. No → fix what's wrong.

## Tracking

Progress is tracked on an interactive board — open [`kanban.html`](kanban.html) in any browser.
