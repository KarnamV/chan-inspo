class_name Rewards
extends RefCounted
## Room reward offers and grants: talisman, helper boon, move draft, gold; plus shop and shrine.
## Pure logic (returns card dicts + apply callables) so UI and bots share it.

const DRAFT_STAT := {
	&"iron_fists": ["Iron Fists", "Bare-hand attacks deal +25% damage."],
	&"prop_master": ["Prop Master", "Props you pick up get +1 durability."],
	&"light_feet": ["Light Feet", "Dodge recovers 30% faster."],
}
const CHI_INFO := {
	&"palm": ["Chi Palm", "Magic palm strike with reach.", &"attack_light"],
	&"wave": ["Chi Wave", "Magic shockwave that knocks down.", &"attack_heavy"],
	&"pull": ["Chi Pull", "Yank a prop into your hand, or a demon to you.", &"grab"],
	&"blink": ["Chi Blink", "Short teleport dodge.", &"dodge"],
}


static func icon(name: String) -> String:
	return "res://assets/icons/%s.png" % name


## Returns an Array of offers: {title, text, icon, apply: Callable}
static func offers(kind: StringName, pc: PlayerController, rng: RandomNumberGenerator) -> Array:
	match kind:
		&"talisman": return _talisman_offers(pc, rng)
		&"boon": return _boon_offers(pc, rng)
		&"draft": return _draft_offers(pc, rng)
		&"gold":
			var g := rng.randi_range(40, 60)
			return [{"title": "%d gold" % g, "text": "Spend it at the shop.", "icon": icon("icon_gold"),
				"apply": func() -> void: Run.gold += g}]
	return []


## Talismans you don't have yet (unlocked in the tea house). Never replaces one: once every active
## button slot is used, only passives are offered. Monkey only once a boss is in the ledger.
static func _talisman_offers(pc: PlayerController, rng: RandomNumberGenerator) -> Array:
	var have: Array = pc.equipped.map(func(t: Talisman) -> StringName: return t.id)
	var slots_full := pc.actives().size() >= PlayerController.ACTIVE_SLOTS
	var pool: Array = Meta.unlocked.filter(func(id: StringName) -> bool:
		if id in have or (id == &"monkey" and pc.boss_ledger.is_empty()):
			return false
		return not (slots_full and Zodiac.make(id).is_active_talisman()))
	_shuffle(pool, rng)
	var out: Array = []
	for id in pool.slice(0, 3):
		var t := Zodiac.make(id)
		var how := "Active." if t.is_active_talisman() else "Passive."
		out.append({"title": t.title + " talisman", "text": "%s %s" % [how, t.blurb],
			"icon": icon("icon_talisman_%s" % id), "apply": func() -> void: pc.collect(id)})
	return out


static func _boon_offers(pc: PlayerController, rng: RandomNumberGenerator) -> Array:
	var helpers: Array = Meta.helpers_met.duplicate()
	if helpers.is_empty():
		return _draft_offers(pc, rng)
	_shuffle(helpers, rng)
	var taken: Array = Run.boons
	for h in helpers:
		var pool: Array = (Boons.HELPERS[h].boons as Array).filter(func(b: StringName) -> bool: return b not in taken)
		if pool.is_empty():
			continue
		_shuffle(pool, rng)
		return pool.slice(0, 3).map(func(b: StringName) -> Dictionary: return boon_card(b, pc))
	return _draft_offers(pc, rng)


static func boon_card(b: StringName, pc: PlayerController) -> Dictionary:
	var h := Boons.helper_of(b)
	var bond := int(Meta.bonds.get(h, 0))
	return {"title": Boons.INFO[b][0], "text": "%s\n— %s%s" % [Boons.INFO[b][1], Boons.HELPERS[h].name,
		(" (bond %d)" % bond) if bond > 0 else ""], "icon": icon("icon_boon_%s" % b),
		"apply": func() -> void: grant_boon(b, pc)}


static func grant_boon(b: StringName, pc: PlayerController) -> void:
	Run.boons.append(b)
	Boons.apply_once(b, pc)
	pc.add_boon(b)
	if pc.hero:
		pc.hero.data_mods = Run.mods
	Events.run_reward.emit(&"boon", b)


static func _draft_offers(pc: PlayerController, rng: RandomNumberGenerator) -> Array:
	var cards: Array = []
	for id in CHI_INFO:
		var unlocked: bool = pc.chi_unlocked[id]
		var lvl: int = pc.chi_level[id]
		if unlocked and lvl >= 3:
			continue
		var title: String = CHI_INFO[id][0] + ("" if not unlocked else " Lv%d" % (lvl + 1))
		var text: String = CHI_INFO[id][1] if not unlocked else "Upgrade: +35% power, more reach."
		text += " (%s)" % Inputs.combo(&"chi_mod", CHI_INFO[id][2])
		cards.append({"title": title, "text": text, "icon": icon("icon_dmg_magic"),
			"apply": func() -> void:
				if not pc.chi_unlocked[id]:
					pc.chi_unlocked[id] = true
				else:
					pc.chi_level[id] = int(pc.chi_level[id]) + 1})
	for id in DRAFT_STAT:
		cards.append({"title": DRAFT_STAT[id][0], "text": DRAFT_STAT[id][1], "icon": icon("icon_dmg_physical"),
			"apply": func() -> void:
				match id:
					&"iron_fists": Run.mods.bare_mult = float(Run.mods.bare_mult) * 1.25
					&"prop_master": Run.mods.durability_bonus = int(Run.mods.durability_bonus) + 1
					&"light_feet": Run.mods.dodge_cd_mult = float(Run.mods.dodge_cd_mult) * 0.7
				pc.hero.data_mods = Run.mods})
	_shuffle(cards, rng)
	return cards.slice(0, 3)


static func shop_stock(pc: PlayerController, rng: RandomNumberGenerator) -> Array:
	var stock: Array = []
	var tal: Array = _talisman_offers(pc, rng)
	if not tal.is_empty():
		var t: Dictionary = tal[0]
		t["price"] = 60
		stock.append(t)
	stock.append({"title": "Bowl of noodles", "text": "Heal 30% HP.", "icon": icon("icon_boon_hearty_heal"),
		"price": 25, "apply": func() -> void: pc.hero.health.heal(pc.hero.health.max_hp * 0.3)})
	var dr: Array = _draft_offers(pc, rng)
	if not dr.is_empty():
		var d: Dictionary = dr[0]
		d["price"] = 50
		stock.append(d)
	stock.append({"title": "Steamed buns", "text": "A food prop (Pig fuel, or just a snack weapon).",
		"icon": icon("icon_boon_food_fill"), "price": 15, "apply": func() -> void:
			var lvl := pc.get_tree().get_first_node_in_group(&"level_root")
			if lvl and lvl.has_method("spawn_prop"):
				lvl.spawn_prop(&"bun_basket", pc.controlled.global_position + pc.controlled.facing * 1.2)})
	for s in stock:
		s["title"] = "%s — %dg" % [s.title, s.price]
		s["enabled"] = Run.gold >= int(s.price)
	stock.append({"title": "Leave", "text": "Keep your gold.", "icon": "", "price": 0, "enabled": true,
		"apply": func() -> void: pass})
	return stock


static func shrine_options(pc: PlayerController, rng: RandomNumberGenerator) -> Array:
	var opts: Array = []
	var boon_pool: Array = []
	for h in Meta.helpers_met:
		for b in Boons.HELPERS[h].boons:
			if b not in Run.boons:
				boon_pool.append(b)
	if not boon_pool.is_empty():
		var b: StringName = boon_pool[rng.randi_range(0, boon_pool.size() - 1)]
		opts.append({"title": "Blood offering", "text": "Lose 15 HP. Receive: %s." % Boons.INFO[b][0],
			"icon": icon("icon_boon_%s" % b), "enabled": pc.hero.health.hp > 16.0,
			"apply": func() -> void:
				pc.hero.health.take(DamageInfo.make(15.0))
				grant_boon(b, pc)})
	opts.append({"title": "Gold offering", "text": "Pay 40 gold. Heal 50%.", "icon": icon("icon_gold"),
		"enabled": Run.gold >= 40, "apply": func() -> void:
			Run.gold -= 40
			pc.hero.health.heal(pc.hero.health.max_hp * 0.5)})
	opts.append({"title": "Bow and leave", "text": "Nothing ventured.", "icon": "", "enabled": true,
		"apply": func() -> void: pass})
	return opts


static func _shuffle(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp: Variant = a[i]
		a[i] = a[j]
		a[j] = tmp
