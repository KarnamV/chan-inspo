# Concept: Demon Realm Escape (v2, working title)

- **Pitch:** Chan-style martial artist trapped in demon realm. Fights through isometric 3D rooms with whatever lying around: chairs, ladders, lanterns, crates. Sheep talisman lets him jump into a downed demon's body.
- **Genre:** isometric 3D action roguelite. Godot 4.7, GDScript.
- **Core fantasy:** never strongest guy in room, always most creative. Improvise, scramble, survive. Comedy + kung fu.
- **Hook / USP:**
  1. Room = arsenal. Every prop is weapon. All props break, so keep grabbing next thing.
  2. Possession is rare + earned. Only via **Sheep talisman**. Knock demon down, jump in, borrow its moveset for a while. Demon roster doubles as temporary playable cast.
- **Pillars:**
  1. **Improvise.** Props everywhere, all break. No main weapon. Bare hands = weakest option.
  2. **Borrowed power.** Props, talismans, Sheep bodies. All temporary in-run except talismans held.
  3. **Readable slapstick.** Big telegraphs, clear hits, comic timing. Isometric camera must always show what is happening.
- **Audience:** action-roguelite fans who like melee feel. Comparables: Hades (run structure, room rewards), Sifu (kung-fu feel), Jackie Chan stunt films (prop fights), Jackie Chan Adventures (talisman fantasy).
- **Scope tier:** hobby (months). Solo + Claude.

## Core loop (rough)

Moment to moment:
`enter room → scan props → grab / swing / throw → prop breaks → grab next → (Sheep: knock down demon → possess → fight as demon → host dies / timer ends → snap back) → room clear`

Run:
`pick door (reward shown) → room → reward (talisman / upgrade / gold) → shop / shrine sometimes → realm boss → next realm → die or escape`

Meta:
`death → Spirit Shards → hub unlocks (talisman pool, starting slots, base moves) → new run`

## Systems (first cut, PRD decides)

- **Props:** each has weight class (light = one-hand swing, heavy = two-hand / throw only), durability, hit effect (knockback, stun, AoE). Starter set: chair, bench, ladder, lantern, crate, pole, barrel, weapon-rack spear.
- **Talismans:** 12 zodiac talismans, equip 3. **Sheep = possession, fixed rule.** Other 11 powers set in PRD; old v1 ideas reusable (Tiger dodge-counter, Monkey extra dashes, Dragon AoE, Snake chain). Keep each power original, not copied 1:1 from the show.
- **Possession (Sheep):** target must be knocked down. Costs spirit meter. Duration = meter drain or host HP. Jackie's body during possession: open question (see risks).
- **Enemies:** demons, possessed warriors, beasts. v1 = humanoid-shaped so they share one animation library (makes them possessable cheaply).

## Pipeline fit

- Props + characters: klein concept → TRELLIS.2 textured mesh (about 100 s each) → `blender_prep`. Proven on the hero 2026-10-09.
- Humanoid demons: + UniRig → humanoid rename → Quaternius clips. Possessed demons reuse the same clips with different tuning.
- Isometric camera forgives rough mesh detail.
- Gaps: prop swing/throw/pickup clips. Quaternius has Sword_Attack, PickUp_Table, Punch; **no throw, no two-hand heavy swing**. Use Kimodo for those.

## Open risks / questions

1. **Prop combat feel.** Physics props can feel floaty or janky. Biggest risk → prototype first.
2. **Possession readability.** From isometric view, player must always know which body they are in. Needs strong outline/colour + UI.
3. **Jackie's body while possessing:** vulnerable on the floor (risk/reward) vs vanishes (simple)? Decide in prototype.
4. **Animation coverage:** throw, heavy swing and possessed-demon specials need clips not in Quaternius.
5. **Prop density per room.** Too few → bare-hand slog; too many → noise. Tune in playtests.
6. **IP:** keep hero as Chan-*inspired* original character. No real name or likeness in anything public. Talisman powers original.
7. **Old v1 code** (Godot 4.3, 2.5D sprites) mostly not reusable for 3D. Design ideas are reusable (shops, shrines, temptation rooms, meta). Archived in `archive/demon-realm-escape/`.

## Hand-off

Prop combat fun unproven → **core-loop-prototype** next: one room, hero (already rigged and animated), 4–5 props, dummy demons, Sheep possession on one enemy type. Then concept-to-prd.
