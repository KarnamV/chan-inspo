# Handover — 2026-10-10

## Goal
chan-inspo v2 (Demon Realm Escape: isometric 3D action roguelite, Godot 4.7). The user said "Go auto till M4 … verify everything … I will check at the end". M0–M4 now done; the user's review is next.

## Done this session
- Concept + 12 talismans + systems designed with the user one by one → `design/concept.md`.
- Plan → `design/roadmap.md` (M0–M9), `design/assets.md`. Art style locked low-poly → `design/art-bible.md`.
- M0–M4 built and verified (details + bug list in `design/STATUS.md`, decisions in `design/CHANGELOG.md`):
  - realm 1 run: hub → 10 rooms (2 helpers, shop, shrine/vault, elite) → Butcher King → hub, meta save
  - 12 talismans, 12 boons, chi moves, 6 demon types
- All 83 manifest assets generated + synced into the game. 3 still bad (bucket, stool, pottery shard).
- Retro run (see below).

## Current state
- **Working.** 37/37 unit tests. Bots: bot_m1, bot_m2, bot_m3 (19/19, 3× stable), bot_run (10/10 with real models).
- Captures: `assets/captures/combat.gif`, `boss.gif`, plus `*_sheet.png`.
- Commits local only (latest `b4e8f52`). Remote `origin` = github KarnamV/chan-inspo. **Not pushed.** Ask before pushing; Git LFS holds the .glb files.
- **Balance untested** (bots ran god-mode HP + 3× damage).

## Pick up next
1. **Get the user's review.** Ask them to open `game/` in Godot 4.7 → F5 (hub) → play a run. Collect feedback on the list in `design/STATUS.md` → "For user review":
   - fun
   - balance
   - Sheep economy change
   - thief + shield demon changes
   - icon style
   - placeholder heavy/throw clips
   - 3 bad props
2. Capture their feel notes with the `playtest-capture` skill → `design/playtests/2026-10-xx.md`.
3. Decide on the **PRD/board drift**: create `design/prd.md` + slices + board (concept-to-prd → prd-to-horizontal-slices → game-board) before M5, or stay roadmap-only.
4. Balance pass from playtest notes (tune `.tres` in `game/data/`; don't re-run `tools/build_data.gd`, it overwrites).
5. Then **M5** (realms 2–3, Tea Master + Kraken-man, helpers 3–5, hub meta UI) per `design/roadmap.md`; generate M5 assets via the manifest runner first.

## Blockers / open questions
- 3 bad props: bucket, stool, pottery shard. TRELLIS fails on open/thin shapes. Bucket + stool are pulled from the run pool. Options: closed-lid / thick-seat prompts, or Hunyuan 2.1 + hand texture.
- Heavy/throw clips are procedural placeholders (stiff). Upgrade = Kimodo (not installed).
- Thief imps still kite a lot (bot room ~70 s).
- Possible push to GitHub (LFS quota 1 GB free).

## Key context
- Start here: `design/STATUS.md` (progress, user-review list), `design/tech.md` (architecture, gotchas, how to run checks).
- Checks (in `game/`):
  - `godot --headless --path . --import`
  - `-s addons/gut/gut_cmdln.gd -gexit`
  - bots: `godot --headless --path . --fixed-fps 60 res://tests/bot/bot_run.tscn` (exit 0 = pass)
- Assets:
  - `assets/manifest.csv` + `assets/style.json`
  - runner: `~/.claude/skills/personal-skills/skills/asset-gen/ai-gamedev-pipeline/scripts/asset_runner.py`
  - then `python tools/sync_assets.py`
  - one runner at a time
- ComfyUI must be running for asset gen: `cd D:\Tools\ComfyUI && venv\Scripts\python.exe main.py --listen 127.0.0.1 --port 8188` (currently left running; stop it to free the GPU).
- Test arenas: `scenes/levels/test_room.tscn` (M1), `combat_arena.tscn` (M2 waves); keys 1-0,-,= swap talismans.

## Suggested skills
playtest-capture → concept-to-prd / game-board (if the user wants a board) → slice-to-build for M5. ai-gamedev-pipeline (read its `references/gotchas.md` first). The personal skills aren't loaded as a plugin, so read `~/.claude/skills/personal-skills/skills/<bucket>/<name>/SKILL.md` directly.

## Retro changes (2026-10-10)
- Pipeline skill: new `references/gotchas.md` (asset failure modes, VRAM, runner rules, Godot traps, gameplay bots), linked from `SKILL.md`. Manifest runner documented in Mode 3.
- Memories added: show-results-as-user-sees-them, windows-shell-scripting, personal-skills-not-loaded, gameplay-bots-verify. Updated: chan-inspo-v2.
- Lessons logged in `design/CHANGELOG.md` (2026-10-10 retro).
