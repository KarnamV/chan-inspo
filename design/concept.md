# Concept: Demon Realm Escape (v2, working title)

- **Pitch:** Chan-style martial artist trapped in demon realm. Fights through isometric 3D rooms with whatever lying around: chairs, ladders, lanterns, crates. Sheep talisman lets him jump into a downed demon's body.
- **Genre:** isometric 3D action roguelite. Godot 4.7, GDScript.
- **Core fantasy:** never strongest guy in room, always most creative. Improvise, scramble, survive. Comedy + kung fu.
- **Hook / USP:**
  1. Room = arsenal. Every prop is weapon. All props break, so keep grabbing next thing.
  2. Possession is rare + earned. Only via **Sheep talisman**. Knock demon down, jump in, borrow its moveset for a while. Demon roster doubles as temporary playable cast.
- **Pillars:**
  1. **Improvise.** Props everywhere, all break. No main weapon. Bare hands = weakest option.
  2. **Borrowed power.** Props, talismans, Sheep hosts, Monkey boss forms, Tiger twin. All temporary in-run; only kill history (Monkey pool) and unlocks persist.
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
- **Damage types:** physical + magic.
  - Props and fists = physical.
  - Magic = chi attacks + Pig and Dragon talismans.
  - Enemies get physical/magic resist profiles so both builds matter.
- **Moves + move draft (roguelite layer):** Jackie starts physical-only and learns magic moves during the run. Rewards offer magic versions of physical moves he already has (e.g. palm strike → chi palm, sweep kick → chi wave). Pick one per reward, so a build drifts physical → magic over the run. *(User idea 2026-10-09; exact rule set in PRD.)*
- **Talismans:** 12 zodiac talismans, equip 3. Powers stay original, not copied 1:1 from the show. All 12 set 2026-10-09:
  - **Sheep: possession.** Fixed rule: the only way to possess. Target must be knocked down (regular demons only). Costs spirit meter. Lasts until the meter drains or the host's HP is gone, then you snap back. What happens to Jackie's body meanwhile is still open (see risks).
  - **Tiger: split.** Jackie splits into two:
    - **Yin:** more magic damage, less HP.
    - **Yang:** more physical damage, more HP.
    - Both fight. You control one and AI runs the other; tap to swap control. If one dies, you continue as the survivor.
  - **Monkey: boss shapeshift.** Turn into any boss you have **ever** killed (persists across runs, meta-unlocked). Keeps at least 3 of that boss's moves. On demand, unlike Sheep. Monkey's pool grows as you beat more bosses → "one more run" pull.
  - **Rat: animate.** Throw the talisman at a prop, and the prop comes alive and fights beside you. Defaults:
    - Costs spirit.
    - Max 2 animated at once.
    - Lasts until it breaks or 15 s, then goes inert and can be grabbed again.
    - Behaviour by weight class: light = darts and pecks fast, heavy = slow, hard slams.
    - Fights in character: chair kicks, ladder spins, lantern spits fire. *(User pick 2026-10-09; the show's Rat also animated objects, so in-character prop behaviour is the original twist.)*
  - **Ox: strongman.** Swing heavy props one-handed. Pick up a stunned/knocked-down demon and swing it as a weapon (it takes damage too). Combos: Sheep (possessed brute swings demons), Rat (lift an animated prop?).
  - **Rabbit: quick feet.** Widens the perfect dodge/parry timing window (e.g. ~2×). A perfect dodge slows time for 1.5 s and refills your dash. Makes the skill move easy to hit.
  - **Snake: shadow coil.** After any dodge you're unseen for 2 s. Hits from stealth are crits and never break the prop. Synergy: Rabbit + Snake = assassin build.
  - **Horse: lifesteal (the healing talisman).** Heal 8% of damage dealt. Breaking a prop on an enemy heals a burst (5% max HP), so wearing props out = healing. Capped per room (boss safety). Numbers are first-pass defaults.
  - **Rooster: juggle.** Launchers keep enemies airborne longer. Aerial hits refund spirit, which feeds the Sheep, Tiger, Monkey and Rat costs.
  - **Dog: loyal.** Survive one lethal hit per room. The demon that "killed" you turns into a temporary ally.
  - **Ally AI is shared:** Tiger twin, Rat props and the Dog convert all use one ally-AI system. Build it once.
  - **Pig: feast (magic).** Food props (buns, roast duck, fruit carts) can be eaten for chi. Chi powers magic belly-slam and burp-blast. New prop category: food.
  - **Dragon: dragon fire (magic).** Ignite whatever you're holding. A burning prop deals magic damage and sets enemies alight. Magic works *with* props. Synergies: Rat (flaming animated props), Tiger Yin (magic glass cannon). Reusable v1 ideas: Dragon AoE, Snake chain lightning, extra dash charges, parry window.
- **Sheep vs Monkey (keep distinct):** Sheep = regular demons, needs knockdown in the room, temporary host with its own HP. Monkey = bosses only, on demand, from kill history.
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
7. **Tiger ally AI.** The second Jackie needs companion AI that keeps up, doesn't steal kills or block the camera, and has readable swap feedback. A companion is a full system → prototype it after props.
8. **Bosses double as player characters (Monkey).** Every boss = AI enemy + playable kit (≥3 moves, controls, balance). Models are cheap via the pipeline; movesets are not. Cap boss count for v1 (e.g. 1 boss per realm, 3 realms).
9. **Damage-type balance.** Physical vs magic resists + the move draft + Yin/Yang stats = many multipliers. Keep the numbers small and readable.
10. **Old v1 code** (Godot 4.3, 2.5D sprites) mostly not reusable for 3D. Design ideas are reusable (shops, shrines, temptation rooms, meta). Archived in `archive/demon-realm-escape/`.

## Hand-off

Prop combat fun unproven → **core-loop-prototype** next: one room, hero (already rigged and animated), 4–5 props, dummy demons, Sheep possession on one enemy type. Then concept-to-prd.
