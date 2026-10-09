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
`pick door (reward shown) → room → reward (talisman / helper boon / move draft / gold) → shop / shrine sometimes → realm boss → next realm → die or escape`

Meta:
`death → Spirit Shards + boss ledger + prop codex + helper bonds → hub unlocks → new run`

## Systems (first cut, PRD decides)

- **Props:**
  - Weight class: light = one-hand swing, heavy = two-hand / throw only.
  - Durability, hit effect (knockback, stun, AoE).
  - Starter set: chair, bench, ladder, lantern, crate, pole, barrel, weapon-rack spear, + food (buns, roast duck, fruit cart).
  - **Breaking = degrading.** A prop breaks into smaller usable pieces before it's gone (bench → bench leg → splinter stake; crate → planks). Each stage is lighter and faster but weaker. Assets: 2–3 piece meshes per prop (pipeline-generated, or Blender fracture of the main mesh).
  - **Element tags:** lantern = fire, bucket = water/douse, spirit urn = magic, food = Pig fuel. Feed Dragon/Pig and helper boons.
  - **Throw & catch:** perfect dodge near a thrown prop (yours or an enemy's) catches it.
  - **Fixed props:** hanging lanterns that drop, barrels that roll, weapon racks to grab from.
  - **Shatter:** breaking a prop on an enemy strips its armor for 3 s, so physical builds can crack armored foes.
- **Spirit meter (chi):** one shared resource. Pays for Sheep, Tiger, Monkey, Rat and chi moves.
  - **Base fill:** landing hits fills it slowly, so talismans work from room 1.
  - **How else it fills is a choice made through helpers** (below), not fixed.
- **Helpers (boon system, Hades-gods style):** allies who back Jackie in the demon realm.
  - **First meeting:** at a fixed story level (scripted encounter that introduces the helper).
  - **Afterwards:** their help appears as **room rewards** (door shows the helper's icon). Pick 1 of ~3 boons.
  - **Boon kinds:** chi-fill rules (variety, damage taken, perfect dodges, eating food, kills…), talisman upgrades (how a talisman is used), damage boosts, extra lives, saves/shields.
  - Candidate helpers (working names, one theme each): Stunt Coordinator (variety / props), Old Herbalist (passive, healing, lives), Street Brawler (damage taken, raw damage), Monk (perfect dodge/parry), Street Chef (food, Pig synergy).
  - Helpers persist as story NPCs in the hub once met. Their roster = a meta unlock.
- **Combat core (v1 moves):** light + heavy attack (combos from mixing), grab & throw (props + stunned enemies), dodge (i-frames; perfect timing feeds Rabbit/Snake), parry (timed block → stagger; Rabbit widens the window).
  - **Knockdown state:** enemies can be knocked down (prop hits, heavies, throws). Required for Sheep possession and Ox lift.
  - **Bare hands scale with the move draft.** They start weak (props hit much harder early). Draft upgrades to the physical and chi versions make fists viable late-run.
- **Run structure:** 7 realms, 8–10 rooms each + boss. Doors show their reward type. Demon-twisted real places, each with its own prop family; v1 moods kept as colour themes:
  1. Ember Night Market: stalls, lanterns, food carts, woks. Boss: Butcher King.
  2. Frozen Teahouse: tables, teapots, screens, ice blocks. Boss: Tea Master.
  3. Rotting Docks: crates, oars, nets, fish barrels. Boss: Harbor Kraken-man.
  4. Ash Opera House: prop racks, fans, spears, falling scenery. Boss: Opera Phantom.
  5. Bone Temple: bells, staves, statues, incense urns (magic). Boss: Temple Guardian.
  6. Void Bamboo Forest: bamboo poles, rope bridges, boulders. Boss: Shadow Twin.
  7. Demon Palace: thrones, gongs, weapon racks, everything. Boss: Demon Lord.
  - **Delivery:** design all 7. **Milestone 1 = realms 1–3 fully playable start to end** (3 bosses, each a full playable Monkey form). Realms 4–7 are later milestones.
  - **Special rooms:**
    - Shop (gold → talismans, food, upgrades).
    - Shrine (trade HP/gold for a blessing).
    - Temptation (cursed power-up, from v1).
    - Prop vault (timed, rare props, no enemies; carry one forward).
- **Meta (hub = tea house):**
  - **Spirit Shards** (earned per run) → talisman unlocks, extra starting talisman slots, base move upgrades.
  - **Boss ledger** → feeds Monkey. First kill unlocks the boss form (full moveset); repeat kills raise its attack limit.
  - **Prop codex** → props discovered/used join the run pool, with lore entries.
  - **Helper bonds** → helpers met live in the hub. Deeper bond (time/shards) → stronger boons offered in runs.
- **Damage types:** physical + magic.
  - Props and fists = physical.
  - Magic = chi attacks + Pig and Dragon talismans.
  - Enemies get physical/magic resist profiles so both builds matter.
- **Dual-variant moves + move draft (roguelite layer):** every move has 2 versions:
  - **Regular (physical).**
  - **Chi (magic):** hold **L2** + the same button.
  - Chi versions **start locked or weak**. The **move draft** (room reward) unlocks and upgrades them (chi palm lv1 → 2 → 3), so a build drifts physical → magic over a run.
  - Chi versions **cost spirit**, competing with talismans for the meter (makes helper fill rules matter).
  - Tiger synergy: Yin boosts chi versions, Yang boosts regular ones, so swapping twins swaps which half of your kit is strong.
  - *(User design 2026-10-09; replaces "convert a slot".)*
- **Controls (gamepad):** □ light, △ heavy, ○ grab/throw, × dodge, R1 parry, **L2 + face = chi versions** (chi light / chi heavy / chi pull / chi blink), **L1 + □△○ = talisman 1/2/3**, R2 free (lock-on or sprint). Keyboard: Shift = chi modifier, Ctrl = talisman modifier.
- **Talismans:** 12 zodiac talismans, equip 3. Powers stay original, not copied 1:1 from the show. All 12 set 2026-10-09:
  - **Sheep: possession.** Fixed rule: the only way to possess. Target must be knocked down (regular demons only). Costs spirit meter. Lasts until the meter drains or the host's HP is gone, then you snap back. **Jackie's body lies vulnerable on the floor.** If it's hit, you snap back and take damage. Talisman synergies protect it:
    - Tiger: the twin guards the body.
    - Snake: the body is invisible while you possess.
    - Horse: the host's attacks heal Jackie's body.
    - Dog: a shield on the body.
    - Rat: animated props defend it.
  - **Tiger: split.** Jackie splits into two:
    - **Yin:** more magic damage, less HP.
    - **Yang:** more physical damage, more HP.
    - Both fight. You control one and AI runs the other; tap to swap control. If one dies, you continue as the survivor.
  - **Monkey: boss shapeshift.** Turn into any boss you have **ever** killed (meta, persists across runs). On demand, unlike Sheep.
    - **Your attack set fully changes to the boss's** (its whole moveset, not a subset).
    - **Other talismans still work** while transformed.
    - **Attack limit:** you can only make so many attacks, then you're forced back into Jackie. Lore: stay longer and you lose yourself to the demon.
    - A "losing yourself" indicator shows as you near the limit (form darkens, outline flickers), so the revert is never a surprise.
    - Repeat kills of a boss raise its attack limit (meta pull). Limit numbers set in PRD.
    - *(User change 2026-10-09: replaces "keeps ≥3 moves".)*
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
- **Sheep vs Monkey (keep distinct):** Sheep = regular demons, needs knockdown in the room, temporary host with its own HP. Monkey = bosses only, on demand, from kill history, limited by attack count (Sheep is limited by meter + host HP).
- **Enemies (realms 1–3):** mostly humanoid, so they share one animation library and Sheep can possess them cheaply.
  - **Shield demon:** blocks prop hits. Flank it, or Shatter it.
  - **Brute:** knocks you down. Ideal Sheep host (heavy moveset).
  - **Thief imp:** grabs props off the floor and runs. Fights you for the room's arsenal.
  - **Archer / thrower:** ranged. Throws props back at you (catchable). Forces movement.
  - **Wraith (spectral):** resists physical. Needs chi moves, Dragon fire or Pig magic.
  - **Armored ghoul (warded):** resists magic. Its armor breaks with Shatter.
- **Bosses (milestone 1). Each is a fight and a full playable Monkey form (whole moveset); signature moves listed:**
  - **Butcher King** (Night Market): turns food carts into weapons. Kit: cleaver throw (returns), ground-pound shockwave, meat-hook pull.
  - **Tea Master** (Frozen Teahouse): graceful parry duelist who freezes spilled tea into ice. Kit: scalding pour cone (magic), ice-floor slide dash, teacup barrage.
  - **Harbor Kraken-man** (Rotting Docks): tentacles grab props across the dock. Kit: tentacle grab (steal a prop), ink cloud (stealth zone), whirlpool pull (AoE gather).

## Pipeline fit

- Props + characters: klein concept → TRELLIS.2 textured mesh (about 100 s each) → `blender_prep`. Proven on the hero 2026-10-09.
- Humanoid demons: + UniRig → humanoid rename → Quaternius clips. Possessed demons reuse the same clips with different tuning.
- Isometric camera forgives rough mesh detail.
- Gaps: prop swing/throw/pickup clips. Quaternius has Sword_Attack, PickUp_Table, Punch; **no throw, no two-hand heavy swing**. Use Kimodo for those.

## Open risks / questions

1. **Prop combat feel.** Physics props can feel floaty or janky. Biggest risk → prototype first.
2. **Possession readability.** From isometric view, player must always know which body they are in. Needs strong outline/colour + UI.
3. ~~Jackie's body while possessing~~ → decided: lies vulnerable, protected via talisman synergies (see Sheep).
4. **Animation coverage:** throw, heavy swing and possessed-demon specials need clips not in Quaternius.
5. **Prop density per room.** Too few → bare-hand slog; too many → noise. Tune in playtests.
6. **IP:** keep hero as Chan-*inspired* original character. No real name or likeness in anything public. Talisman powers original.
7. **Tiger ally AI.** The second Jackie needs companion AI that keeps up, doesn't steal kills or block the camera, and has readable swap feedback. A companion is a full system → prototype it after props.
8. **Bosses double as player characters (Monkey).** Every boss = AI enemy + its **entire** moveset player-controllable (inputs, balance, works with other talismans). Models are cheap via the pipeline; full playable kits are not. Milestone 1 caps it at 3 bosses.
9. **Damage-type balance.** Physical vs magic resists + the move draft + Yin/Yang stats = many multipliers. Keep the numbers small and readable.
10. **Old v1 code** (Godot 4.3, 2.5D sprites) mostly not reusable for 3D. Design ideas are reusable (shops, shrines, temptation rooms, meta). Archived in `archive/demon-realm-escape/`.

## Hand-off

Prop combat fun unproven → **core-loop-prototype** next: one room, hero (already rigged and animated), 4–5 props, dummy demons, Sheep possession on one enemy type. Then concept-to-prd.
