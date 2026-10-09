# Roadmap: Demon Realm Escape v2

Plan date 2026-10-09. Hobby scope. Each milestone ends with a **playable gate**: something you can open, play and judge before the next one starts. Assets per milestone: `design/assets.md`.

Rule: assets are generated **just in time per milestone** (generation phase = milestone). No bulk generation before the M1 gate proves prop combat is fun. If the gate fails, the style/scale changes and early bulk assets would be rework.

## M0: Style lock + tooling (≈1 session)
- Art bible: one style prompt prefix for all 3D (characters, props, decor) and 2D (icons, portraits). Lock it by generating hero + 1 prop + 1 icon and comparing side by side.
- Final hero design (Chan-*inspired* original; no real name/likeness).
- Extend pipeline: manifest categories beyond character|prop. Add `decor`, `texture` (tileable), `icon` (2D only, no mesh), `portrait`. Add batch runner over the manifest (status column, skip done, resume after crash).
- Godot 4.7 project skeleton at `chan-inspo/game/` (isometric camera, test room, GUT).
- **Gate:** style sheet approved, `godot --headless` boots, manifest runner generates the 3 lock assets end-to-end.

## M1: Core-loop prototype: is prop fighting fun? (≈1–2 weeks)
- One room. Hero with light/heavy, grab/throw, dodge.
- 5 props that degrade into pieces. Knockdown state.
- Brute enemy (dummy AI: approach, swing). **Sheep possession** on the Brute; Jackie's body lies vulnerable.
- Base spirit fill (hits).
- **Gate (go/no-go):** 10-minute playtest. Is grabbing and breaking props fun from the isometric camera? Which body am I in, readable? If no → rethink before any more assets.

## M2: Combat kit (≈2–3 weeks)
- Full v1 moveset + parry. Chi variants (L2) for 2 moves, locked/unlock flow stubbed.
- Physical/magic damage types + resists. Shatter. Throw & catch. Fixed props.
- All 6 enemy archetypes with AI. Element tags (fire, water, magic, food).
- **Gate:** one arena wave fight with all 6 enemies feels fair and readable.

## M3: Talismans (≈3 weeks)
- All 12 talismans, equip 3 (L1 + button). Shared ally-AI system (Tiger twin, Rat props, Dog convert).
- Tiger Yin/Yang swap. Monkey uses a test boss form (placeholder moveset) with attack limit + "losing yourself" indicator.
- **Gate:** each talisman tried in the arena. Every one feels distinct; 3 synergy combos work (Ox+Sheep, Dragon+Rat, Rabbit+Snake).

## M4: Realm 1 vertical slice (≈3–4 weeks)
- Ember Night Market: room generation, reward doors, room-clear rewards.
- Move draft, helpers 1–2 (meet at story level + boons). Shop, shrine.
- **Butcher King** boss + his full Monkey form. Death → shards (minimal hub stub).
- **Gate:** start → realm 1 → boss → win/lose, full loop in one sitting (15–20 min).

## M5: Milestone-1 release: realms 1–3 (≈6–8 weeks)
- Frozen Teahouse + Rotting Docks. Tea Master + Harbor Kraken-man (+ Monkey forms).
- Helpers 3–5. Temptation room, prop vault.
- Tea-house hub: shards, boss ledger, prop codex, helper bonds.
- Placeholder → final audio pass (separate track, see assets.md §Audio).
- **Gate:** full run realms 1–3 start to end. Shareable build (Windows export).

## M6–M9: Realms 4–7 (≈3–4 weeks each)
One realm per milestone: Ash Opera House, Bone Temple, Void Bamboo Forest, Demon Palace (final boss). Each: realm kit + boss + Monkey form + new enemy variants.

## Process per milestone
1. Generate that milestone's asset phase (assets.md), review renders, re-roll bad ones.
2. Build in slices (concept-to-prd and slicing before M2; the board from the PRD onward).
3. Headless tests + boot clean each slice; playtest gate at the end; log in CHANGELOG.
