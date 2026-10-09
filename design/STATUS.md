# Status (auto run M0 → M4)

User instruction 2026-10-09: "Go auto till M4. Verify everything you create if it is proper. I will check at the end and provide inputs."

Rules for this run:
- Order M0 → M1 → M2 → M3 (Sheep, Tiger, Rat, Dragon first, then other 8) → M4.
- Verify each piece: headless tests + clean boot, Movie Maker captures inspected, asset chain checks.
- Commit often. Log decisions in CHANGELOG. Update this file at each milestone step.
- Can't judge fun. Flag feel questions for the user's end review in "For user review" below.

## Progress
- [x] M0 style lock (icons: flat vector) + tooling (manifest runner, asset_runner.py) + Godot skeleton
  - Runner gotchas fixed: relative paths (Blender cwd), output checks per stage, free ComfyUI VRAM before mesh/rig, lighter TRELLIS for props (box props 5 min → 3 min).
- [x] M1 prototype (functional gate passed 2026-10-09): bot playtest 7/7 (grab, break, knockdown, possess, host hits, release, kill); captures in assets/M1_bot_sheet.png + M1_bot.gif. **Fun = user's call.**
  - Bugs found + fixed: spawn order (bodies stacking), Sheep cost made possession end instantly at exactly 40 spirit (now: 40 = requirement, then drains), long props spawned balancing upright (now lie down), stake mesh fragmented (re-rolled, prompt 'thick chunky').
- [ ] M2 combat kit: parry, catch, shield block, elements (fire/water/magic), chi palm/wave/pull/blink, thief + archer AI, projectiles, kickable props, hanging lanterns, weapon rack written + unit-tested. Needs M2 assets + combat_arena bot.
- [ ] M3 talismans
- [ ] M4 realm 1 slice

## For user review (collected during the run)
- Icon style picked by me: flat vector (most readable at 48 px). Low-poly faceted is an option for big reward cards.
- Heavy smash + throw clips are procedural placeholders (stiff). Upgrade path: Kimodo.
- Sheep economy changed: 40 spirit needed to start, no up-front charge; drains 7/s (≈6–14 s of possession).
- M1 'is it fun?' gate: please play `game/scenes/levels/test_room.tscn` (F6) — I can only verify it works.
