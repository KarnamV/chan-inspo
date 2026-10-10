# Decisions

Deliberate choices that might look wrong. Agents must not "fix" these. Full history
in `design/CHANGELOG.md`.

| Date | Decision | Why | Revisit when |
|---|---|---|---|
| 2026-10-09 | One `Fighter` body for Jackie and every demon; behaviour via swappable `Brain` | Possession = brain + team swap; Monkey/Tiger reuse it | Never without a design change |
| 2026-10-09 | Sheep: 40 spirit is a requirement, no up-front charge, drains 7/s | Old cost ended possession instantly at exactly 40 | User review of Sheep economy |
| 2026-10-09 | Thief imp fights when there is nothing to steal; throws loot after ~5 s | Fleeing forever made it unkillable | Playtest (imps still kite ~70 s) |
| 2026-10-09 | Shield demon turns at 1.5 rad/s, guard break on heavy/knockdown, magic passes | Snapping to face you made flanking impossible | Playtest |
| 2026-10-09 | Bots run god-mode HP + 3x damage | Prove the loop works, not balance | Never use bots for balance |
| 2026-10-09 | Icons: flat vector | Most readable at 48 px | User review |
| 2026-10-09 | Bucket + stool removed from realm-1 random prop pool | Generated meshes are bad | Assets fixed |
| 2026-10-09 | Data `.tres` generated once by `tools/build_data.gd`, then hand-tuned | Inspector tuning | Never re-run the generator |
| 2026-10-09 | Loose props/pieces parent to the `level_root` group node, not `current_scene` | GUT has no `current_scene`; rooms swap | - |
