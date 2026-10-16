# Decisions

Deliberate choices that might look wrong. Agents must not "fix" these. Full history
in `design/CHANGELOG.md`.

| Date | Decision | Why | Revisit when |
|---|---|---|---|
| 2026-10-16 | Exit doors flush on the back wall, swinging out; trigger covers the pillars | Bodies got wedged behind/beside inward doors | - |
| 2026-10-15 | No parry state in play: the parry button dodges; timed dodges are the counter | Playtest 3: "can't really parry" | Playtest |
| 2026-10-15 | Realm 1 rest room is the prop vault only | Playtest 3: shrines later; vault useful now props carry over | Realm 2 |
| 2026-10-15 | `AssetCache` loads one resource at a time, no sub-threads | Parallel threaded loads deadlocked the room build | Godot loader fix |
| 2026-10-09 | One `Fighter` body for Jackie and every demon; behaviour via swappable `Brain` | Possession = brain + team swap; Monkey/Tiger reuse it | Never without a design change |
| 2026-10-10 | Talismans run on cooldowns, no spirit cost; spirit (chi) is only for chi moves. Sheep possession lasts 10 s (`sheep_duration`), 12 s cooldown | Chi costs left the player unable to attack (playtest 1) | Playtest |
| 2026-10-10 | Talismans are collected, never replaced. Start with none; the first room always rewards one. 4 active slots (mod + light/heavy/grab/dodge) | Playtest 2 | Playtest |
| 2026-10-10 | Props wear only on hits that connect (`DamageInfo.whiff` set on dodge, getup, i-frames); floor/wall hits never wear | Playtest 2: props broke on misses | - |
| 2026-10-10 | Demons attack only after seeing (7.5 m, ~150 deg cone) or hearing (2.8 m) you; a noticed demon alerts others within 6 m; max 2 attackers per target | Playtest 2: swarmed at room start | Playtest |
| 2026-10-10 | Spin's 360 deg turn is rotated on the model in code | Godot humanoid import drops Hips rotation from clips | Clips remade |
| 2026-10-10 | Physics interpolation on; hitstop only on the player's own hits | "Low fps" was judder + hitstop, not rendering | - |
| 2026-10-09 | Thief imp fights when there is nothing to steal; throws loot after ~5 s | Fleeing forever made it unkillable | Playtest (imps still kite ~70 s) |
| 2026-10-09 | Shield demon turns at 1.5 rad/s, guard break on heavy/knockdown, magic passes | Snapping to face you made flanking impossible | Playtest |
| 2026-10-09 | Bots run god-mode HP + 3x damage | Prove the loop works, not balance | Only rough balance probe: `bot_run.tscn -- --fair` (real HP, no dodging, starts empty-handed) |
| 2026-10-09 | Icons: flat vector | Most readable at 48 px | User review |
| 2026-10-09 | Bucket + stool removed from realm-1 random prop pool | Generated meshes are bad | Assets fixed |
| 2026-10-09 | Data `.tres` generated once by `tools/build_data.gd`, then hand-tuned | Inspector tuning | Never re-run the generator |
| 2026-10-09 | Loose props/pieces parent to the `level_root` group node, not `current_scene` | GUT has no `current_scene`; rooms swap | - |
