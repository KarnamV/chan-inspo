# Handoff — Jackie Chan game project (chan-inspo)

**Date:** 2026-06-20
**Workspace (persistent):** `D:\Projects\Claude\chan-inspo` (git repo)
**User:** Vignesh — see his global operating instructions in `CLAUDE.md` (PRD-before-code, wants pushback, flag contradictions, reversibility checks). Strong C#/.NET background, newer to game dev.

---

## Project in one line

Two Jackie Chan–inspired games, **sequenced**:
1. **Demon Realm Escape** — a **2.5D top-down roguelite** in **Godot 4**. Built **first**, fully standalone. *Active project.*
2. **Unity open-world sandbox** (*Jackie Chan Adventures*–style, Unity 6 + URP, cel-shaded, 12-talisman combo). **Parked — "plan later"**, only after the roguelite ships.

This direction supersedes the older imported project memory that treated the Unity open-world as primary. Recorded in agent memory as `game-direction.md`.

---

## What this session produced (don't re-do — reference these)

- **`kanban.html`** — self-contained interactive board (drag-drop columns Backlog→To Do→In Progress→Testing→Done, game/phase filters, add/edit/delete, localStorage persistence at key `chanInspoKanban.v2`, JSON export/import, reset). Seeded with ~37 cards: 36 for the 2.5D roguelite across Setup + 4 dev phases; the Unity game is a single "PLAN LATER" parked card whose notes hold the 10 previously-derived sub-tasks. Two cards pre-marked Done (git repo, design doc).
- **`GAME-design.md`** — reframed side-view → 2.5D top-down throughout (combat = top-down brawler, 8-dir movement, jump-kick→dash-attack, Monkey Step double-jump→extra dodge-dash charges, Godot rationale + Phase 1 now cover 2.5D camera/render, scope note that Unity is out of scope). Verified: no stale side-view/platformer terms remain.
- **`README.md`** — now describes both games and points to the kanban.

---

## Current state / things to watch

- **All edits are UNSTAGED / uncommitted.** Nothing committed this session — fully reversible. Next agent may offer to commit.
- **`LICENSE` shows as modified in `git status`** but was never touched — almost certainly environment line-ending (CRLF) normalization. Check before staging; don't blindly commit it.
- A `.git/index.lock` permission warning appeared during `git status` from the sandbox — cosmetic, git still reported status fine.

---

## Open threads / likely next steps

- **Commit the changes?** (offered, not yet done.) Suggested scope: "Reframe to 2.5D top-down roguelite; park Unity game; add kanban board."
- **Re-expand the Unity parked card** into 10 separate cards if the user later wants Unity tracked in detail (offered as an option).
- **Talisman effects for top-down:** only Monkey Step was adjusted. If more talismans assume verticality on closer review, adjust (none currently flagged).
- **Starting actual development:** per the user's `CLAUDE.md`, a short PRD must come before any build, with sign-off. The kanban's Phase 1 + the "combat-feel gate" card is the natural starting point ("combat first — if fighting isn't fun, stop").

---

## Suggested skills for the next session

- **`write-prd`** — when the user is ready to start building, draft the PRD for the first vertical slice (Phase 1 prototype: top-down movement + 4 attacks + dodge + one talisman + combat-feel gate). Required by his workflow before code.
- **`prd-to-plan`** — slice that PRD into independently-grabbable vertical-slice issues. Pairs naturally with the kanban.
- **`impl-doc`** — if he wants HLD/LLD technical design for a Godot phase before implementation.

---

## Pointers

- Design doc: `D:\Projects\Claude\chan-inspo\GAME-design.md`
- Board: `D:\Projects\Claude\chan-inspo\kanban.html`
- Readme: `D:\Projects\Claude\chan-inspo\README.md`
- User instructions: `CLAUDE.md` (global) — re-read for working style and the open intake questions at its end (several still unanswered).
- Agent memory: `game-direction.md` (+ `MEMORY.md` index) capture the current direction.
