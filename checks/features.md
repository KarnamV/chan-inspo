# Features

Stable ids, never reused. `write-checks` confirms acceptance criteria with the user,
adds a coverage table per feature, then writes and locks the tests.

## F-01 Thief imp loot timer is frame-rate independent (DRAFT - not confirmed)
Area: brains
Why: `AIBrain._thief` adds a fixed `0.016` to `carry_t` per think instead of `delta`,
so the "throw loot after ~5 s" rule changes with frame rate.
Acceptance criteria:
- AC1: An imp carrying loot throws it after 5.0 s (+/- 0.1 s) of simulated time at
  30, 60 and 120 physics ticks per second.
- AC2: The 5.0 s carry limit is a `FighterData` field (`loot_carry_seconds`) set in
  `thief_imp.tres`, not an inline number.
- AC3: `bot_m2` still passes 3x.
Out of scope: changing how much imps kite (that is F-02, after playtest).
Expected footprint: `game/scripts/brains/ai_brain.gd`, `game/scripts/fighters/fighter_data.gd`,
`game/data/fighters/thief_imp.tres`, `game/tests/unit/test_ai_brain.gd` (new)
Depends on: none

## F-02 Thief imps can be pinned down (DRAFT - decide after playtest)
Area: brains
Why: STATUS.md: imps still kite a lot (bot room 9 took ~70 s).
Acceptance criteria: to be set after the user plays a run. Candidate:
- After throwing loot, an imp cannot steal again for N s and fights instead.
- `bot_m2` clears a 3-imp wave faster than today (target set from playtest).
- Human: catching imps feels fair, not tedious.
Expected footprint: `game/scripts/brains/ai_brain.gd`, `game/data/fighters/thief_imp.tres`,
`game/tests/unit/test_ai_brain.gd`, `game/tests/bot/` (new or existing bot)
Depends on: F-01
