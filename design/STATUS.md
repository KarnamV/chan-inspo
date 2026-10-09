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
- [x] M2 combat kit (bot_m2: all 6 types): parry, catch, shield block, elements (fire/water/magic), chi palm/wave/pull/blink, thief + archer AI, projectiles, kickable props, hanging lanterns, weapon rack written + unit-tested. Needs M2 assets + combat_arena bot.
- [x] M3 talismans (bot_m3 19/19, stable 3 runs)
- [x] M4 realm 1 slice (2026-10-10): all art synced, full-run bot passes with real models, captures in assets/captures/ (combat, boss, hub). Run loop works end to end (bot_run 10/10: 10 rooms, 2 helpers, shop, shrine, 10 rewards, Butcher King, ledger, shards, hub). Waiting: M2-M4 assets (models for demons/boss/helpers/market), visual pass.
  - Bugs found + fixed by the run bot: panels paused the bot (deadlock), thief imp kited forever (unkillable), shield demon snapped to face you (flanking impossible) → turn rate + guard break + magic bypass, double-counted boon rewards.

## For user review (collected during the run)
- Icon style picked by me: flat vector (most readable at 48 px). Low-poly faceted is an option for big reward cards.
- Heavy smash + throw clips are procedural placeholders (stiff). Upgrade path: Kimodo.
- Sheep economy changed: 40 spirit needed to start, no up-front charge; drains 7/s (≈6–14 s of possession).
- **3 props still look bad** after 3 re-roll attempts: bucket, stool, pottery shard (TRELLIS struggles with open/thin shapes even at full quality; concepts are clean). Bucket + stool removed from the realm-1 random pool; shard only appears as brief debris. Fix ideas: closed-lid bucket / thick-seat stool prompts, or Hunyuan3D 2.1 shape + hand texture.
- 4 other broken props fixed by re-roll with 'solid, opaque, chunky' prompts (spirit urn, hanging lantern, lantern post, rice sacks).
- **Balance is untested:** bots run with god-mode HP and 3× damage to prove the loop. Expect tuning needs (enemy HP, spirit costs, boss damage).
- Thief imps still kite a lot (room 9 took ~70 s for the bot). Might need a slower imp or a 'grab' counter.
- M1 'is it fun?' gate: please play `game/scenes/levels/test_room.tscn` (F6) — I can only verify it works.

## Pick up next
- M0–M4 done. Waiting on user review (see list above). Next milestone after review: M5 (realms 2–3) per roadmap.
