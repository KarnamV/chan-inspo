class_name Zodiac
extends RefCounted
## The 12 zodiac talismans (design/concept.md → Talismans). `Zodiac.make(id)` builds one.

const ALL := [&"rat", &"ox", &"tiger", &"rabbit", &"dragon", &"snake", &"horse", &"sheep", &"monkey",
	&"rooster", &"dog", &"pig"]


static func make(id: StringName) -> Talisman:
	var t: Talisman
	match id:
		&"sheep": t = Sheep.new()
		&"tiger": t = Tiger.new()
		&"monkey": t = Monkey.new()
		&"rat": t = Rat.new()
		&"ox": t = Ox.new()
		&"rabbit": t = Rabbit.new()
		&"snake": t = Snake.new()
		&"horse": t = Horse.new()
		&"rooster": t = Rooster.new()
		&"dog": t = Dog.new()
		&"pig": t = Pig.new()
		&"dragon": t = Dragon.new()
	t.id = id
	return t


# ---------------------------------------------------------------- Sheep: possession
class Sheep:
	extends Talisman
	func _init() -> void:
		title = "Sheep"
		blurb = "Possess a knocked-down demon. Your body lies vulnerable."
		cost = 40.0

	func is_active_talisman() -> bool:
		return true

	func activate() -> bool:
		if pc.host:
			pc.end_possession(&"released")
			return true
		return pc.try_possess()


# ---------------------------------------------------------------- Tiger: Yin / Yang split
class Tiger:
	extends Talisman
	var twin: Fighter
	var left := 0.0
	var hero_max := 0.0
	var prev_guard: Callable
	const DURATION := 20.0

	func _init() -> void:
		title = "Tiger"
		blurb = "Split into Yin (magic+, HP-) and Yang (physical+, HP+). Tap again to swap."
		cost = 45.0

	func is_active_talisman() -> bool:
		return true

	func activate() -> bool:
		if twin and is_instance_valid(twin):
			_swap()
			return true
		if pc.spirit < cost or pc.controlled != pc.hero or pc.host:
			return false
		pc.add_spirit(-cost)
		var hero := pc.hero
		hero_max = hero.health.max_hp
		# hero becomes Yang
		hero.health.max_hp = hero_max * 1.3
		hero.health.hp *= 1.3
		hero.dmg_mult_physical = 1.4
		hero.set_tint(Color(1.0, 0.55, 0.15, 0.18))
		# twin is Yin
		twin = Fighter.new()
		twin.data = hero.data
		twin.team = Fighter.Team.PLAYER
		twin.position = hero.global_position + hero.global_transform.basis.x * 1.2
		hero.get_parent().add_child(twin)
		twin.health.max_hp = hero_max * 0.7
		twin.health.hp = twin.health.max_hp * (hero.health.hp / hero.health.max_hp)
		twin.dmg_mult_magic = 1.6
		twin.set_tint(Color(0.2, 0.95, 0.65, 0.22))
		twin.set_brain(AllyBrain.new(func() -> Fighter: return pc.controlled))
		twin.died.connect(_on_one_died.bind(twin))
		prev_guard = hero.health.lethal_guard   # don't clobber Dog's guard
		hero.health.lethal_guard = _hero_guard
		left = DURATION
		Events.tiger_split.emit(hero, twin)
		return true

	func _swap() -> void:
		var hero := pc.hero
		if pc.controlled == hero:
			hero.set_brain(AllyBrain.new(func() -> Fighter: return pc.controlled))
			twin.set_brain(pc.brain)
			pc._set_controlled(twin)
		else:
			twin.set_brain(AllyBrain.new(func() -> Fighter: return pc.controlled))
			hero.set_brain(pc.brain)
			pc._set_controlled(hero)

	func _hero_guard(_info: DamageInfo) -> bool:
		# Yang falls: keep the hero alive and continue as Yin until the split ends
		if twin and is_instance_valid(twin) and not twin.is_dead():
			_end(true)
			return true
		return false

	func _on_one_died(_who: Fighter) -> void:
		_end(false)

	func _end(hero_fell: bool) -> void:
		if twin == null:
			return
		var hero := pc.hero
		var t := twin
		twin = null
		var ratio := (t.health.hp / t.health.max_hp) if hero_fell else (hero.health.hp / hero.health.max_hp)
		if hero_fell and is_instance_valid(t):
			hero.global_position = t.global_position
		hero.health.max_hp = hero_max
		hero.health.hp = maxf(hero_max * ratio, 1.0)
		hero.dmg_mult_physical = 1.0
		hero.set_tint(null)
		hero.health.lethal_guard = prev_guard
		hero.set_brain(pc.brain)
		if pc.controlled != hero and pc.host == null:
			pc._set_controlled(hero)
		if is_instance_valid(t):
			t.queue_free()
		Events.tiger_merged.emit(hero)

	func tick(delta: float) -> void:
		if twin:
			left -= delta
			if left <= 0.0:
				_end(false)

	func _on_unequip() -> void:
		_end(false)


# ---------------------------------------------------------------- Monkey: boss shapeshift
class Monkey:
	extends Talisman
	var form: Fighter
	var attacks_left := 0
	const BASE_LIMIT := 10
	const PER_EXTRA_KILL := 3

	func _init() -> void:
		title = "Monkey"
		blurb = "Become a boss you've beaten. Limited attacks before you lose yourself."
		cost = 60.0

	func is_active_talisman() -> bool:
		return true

	func activate() -> bool:
		if form and is_instance_valid(form):
			revert(false)
			return true
		var forms: Dictionary = pc.boss_ledger
		if forms.is_empty() or pc.spirit < cost or pc.controlled != pc.hero or pc.host:
			return false
		var id: StringName = forms.keys()[pc.monkey_pick % forms.size()]
		var d: FighterData = load("res://data/fighters/%s.tres" % id)
		if d == null:
			return false
		pc.add_spirit(-cost)
		var hero := pc.hero
		form = Fighter.new()
		form.data = d
		form.team = Fighter.Team.PLAYER
		form.position = hero.global_position
		hero.get_parent().add_child(form)
		form.facing = hero.facing
		form.set_tint(Color(1.0, 0.8, 0.2, 0.12))
		form.set_brain(pc.brain)
		form.attack_landed.connect(pc._on_landed)
		form.attack_started.connect(_on_form_attack)
		form.died.connect(revert.bind(true))
		attacks_left = BASE_LIMIT + PER_EXTRA_KILL * (int(forms[id]) - 1)
		hero.set_hidden(true)
		pc._set_controlled(form)
		Events.monkey_changed.emit(form, attacks_left)
		return true

	func _on_form_attack(_a: AttackData) -> void:
		if form == null or not is_instance_valid(form):
			return
		attacks_left -= 1
		# "losing yourself": the form darkens as the limit nears
		var lost := 1.0 - float(attacks_left) / float(BASE_LIMIT)
		form.set_tint(Color(0.35 - 0.3 * lost, 0.1, 0.25, 0.12 + 0.4 * lost))
		Events.monkey_changed.emit(form, attacks_left)
		if attacks_left <= 0:
			revert.call_deferred(false)

	func revert(form_died: bool) -> void:
		if form == null:
			return
		var f := form
		form = null
		var hero := pc.hero
		hero.global_position = f.global_position
		hero.set_hidden(false)
		hero.set_brain(pc.brain)
		pc._set_controlled(hero)
		if form_died:
			hero.health.take(DamageInfo.make(15.0))
		if is_instance_valid(f):
			f.queue_free()
		Events.monkey_changed.emit(null, 0)

	func _on_unequip() -> void:
		revert(false)


# ---------------------------------------------------------------- Rat: animate a prop
class Rat:
	extends Talisman
	var animated: Array[Prop] = []
	const MAX := 2
	const LIFE := 15.0

	func _init() -> void:
		title = "Rat"
		blurb = "Throw the talisman at a prop: it comes alive and fights for you."
		cost = 20.0

	func is_active_talisman() -> bool:
		return true

	func activate() -> bool:
		animated = animated.filter(func(p: Prop) -> bool: return is_instance_valid(p) and p.animator != null)
		if animated.size() >= MAX or pc.spirit < cost:
			return false
		var f := pc.controlled
		var best: Prop = null
		var bd := 7.0
		for n in f.get_tree().get_nodes_in_group(&"props"):
			var p := n as Prop
			if p == null or not p.can_pick_up() or p.animator:
				continue
			var to := p.global_position - f.global_position
			var d := to.length()
			if d < bd and (d < 2.0 or f.facing.dot(to.normalized()) > 0.2):
				bd = d
				best = p
		if best == null:
			return false
		pc.add_spirit(-cost)
		best.animate(f, LIFE)
		animated.append(best)
		return true


# ---------------------------------------------------------------- Ox: strongman (passive)
class Ox:
	extends Talisman
	func _init() -> void:
		title = "Ox"
		blurb = "Heavy props swing one-handed. Grab a knocked-down demon and swing it."

	func _on_equip() -> void:
		on_controlled_changed(pc.controlled)

	func on_controlled_changed(f: Fighter) -> void:
		for b in [pc.hero, f]:
			if b:
				b.heavy_one_hand = true
				b.grab_override = _grab_demon

	func _on_unequip() -> void:
		for b in [pc.hero, pc.controlled]:
			if b:
				b.heavy_one_hand = false
				b.grab_override = Callable()

	func _grab_demon(f: Fighter) -> bool:
		var victim: Fighter = null
		var bd := 1.9
		for n in f.get_tree().get_nodes_in_group(&"fighters"):
			var o := n as Fighter
			if o and o.team != f.team and o.is_knocked_down() and f.global_position.distance_to(o.global_position) < bd:
				bd = f.global_position.distance_to(o.global_position)
				victim = o
		if victim == null:
			return false
		var a := AttackData.new()
		a.id = &"ox_giant_swing"
		a.clip = &"heavy"
		a.duration = 0.8
		a.active_start = 0.35
		a.active_end = 0.55
		a.damage = 14.0
		a.knockback = 8.0
		a.knockdown = true
		a.lunge = 0.0
		a.hit_size = Vector3(3.6, 1.6, 3.6)
		a.hit_offset = Vector3(0, 0.8, 0)
		f.request_attack(a)
		var fling := DamageInfo.make(10.0, f)
		fling.knockback = f.facing * 12.0 + Vector3.UP * 5.0
		fling.knockdown = true
		victim.receive_hit(fling)
		return true


# ---------------------------------------------------------------- Rabbit: quick feet (passive)
class Rabbit:
	extends Talisman
	var hooked: Array[Fighter] = []

	func _init() -> void:
		title = "Rabbit"
		blurb = "Wider dodge/parry timing. A perfect dodge slows time and refills your dash."

	func _on_equip() -> void:
		on_controlled_changed(pc.controlled)

	func on_controlled_changed(f: Fighter) -> void:
		if f == null or f in hooked:
			return
		f.parry_mult = 2.0
		f.perfect_dodge.connect(_on_perfect.bind(f))
		hooked.append(f)

	func _on_perfect(f: Fighter) -> void:
		f.dodge_cd = 0.0
		Juice.slowmo(1.5, 0.4)

	func _on_unequip() -> void:
		for f in hooked:
			if is_instance_valid(f):
				f.parry_mult = 1.0
				f.perfect_dodge.disconnect(_on_perfect)
		hooked.clear()


# ---------------------------------------------------------------- Snake: shadow coil (passive)
class Snake:
	extends Talisman
	var hooked: Array[Fighter] = []
	var hidden_left := 0.0
	var who: Fighter

	func _init() -> void:
		title = "Snake"
		blurb = "After a dodge you're unseen for 2 s. Hits from stealth crit and spare the prop."

	func _on_equip() -> void:
		on_controlled_changed(pc.controlled)

	func on_controlled_changed(f: Fighter) -> void:
		if f == null or f in hooked:
			return
		f.dodged.connect(_on_dodged.bind(f))
		f.attack_landed.connect(_on_landed.bind(f))
		hooked.append(f)

	func _on_dodged(f: Fighter) -> void:
		who = f
		hidden_left = 2.0
		f.stealthed = true
		f.crit_next = true
		f.set_tint(Color(0.2, 0.2, 0.3, 0.45))

	func _on_landed(_i: DamageInfo, _a: float, _t: Node, f: Fighter) -> void:
		if f == who and hidden_left > 0.0:
			hidden_left = 0.01   # breaking stealth with the strike

	func tick(delta: float) -> void:
		if hidden_left > 0.0:
			hidden_left -= delta
			if hidden_left <= 0.0 and is_instance_valid(who):
				who.stealthed = false
				who.crit_next = false
				who.set_tint(null)

	func _on_unequip() -> void:
		for f in hooked:
			if is_instance_valid(f):
				f.dodged.disconnect(_on_dodged)
				f.attack_landed.disconnect(_on_landed)
				f.stealthed = false
		hooked.clear()


# ---------------------------------------------------------------- Horse: lifesteal (passive)
class Horse:
	extends Talisman
	var healed_this_room := 0.0
	const STEAL := 0.08
	const PROP_HEAL := 0.05
	const ROOM_CAP := 0.4

	func _init() -> void:
		title = "Horse"
		blurb = "Lifesteal 8%. Breaking a prop on a demon heals 5%."

	func _on_equip() -> void:
		Events.damage_dealt.connect(_on_damage)
		Events.prop_broken.connect(_on_prop_broken)

	func _on_unequip() -> void:
		Events.damage_dealt.disconnect(_on_damage)
		Events.prop_broken.disconnect(_on_prop_broken)

	func _heal(amount: float) -> void:
		var f := pc.controlled
		var cap := f.health.max_hp * ROOM_CAP - healed_this_room
		var h := clampf(amount, 0.0, maxf(cap, 0.0))
		if h > 0.0:
			f.health.heal(h)
			healed_this_room += h

	func _on_damage(target: Node, info: DamageInfo, amount: float) -> void:
		if info.source == pc.controlled and target != pc.controlled and amount > 0.0:
			_heal(amount * STEAL)

	func _on_prop_broken(prop: Node, _pieces: Array) -> void:
		var f := pc.controlled
		if f and f.attack_with_prop == prop:
			_heal(f.health.max_hp * PROP_HEAL)

	func on_room_cleared() -> void:
		healed_this_room = 0.0


# ---------------------------------------------------------------- Rooster: juggle (passive)
class Rooster:
	extends Talisman
	var hooked: Array[Fighter] = []

	func _init() -> void:
		title = "Rooster"
		blurb = "Launches keep demons airborne longer; air hits refund spirit."

	func _on_equip() -> void:
		on_controlled_changed(pc.controlled)

	func on_controlled_changed(f: Fighter) -> void:
		if f == null or f in hooked:
			return
		f.launch_bonus = 5.0
		f.attack_landed.connect(_on_landed)
		hooked.append(f)

	func _on_landed(_i: DamageInfo, amount: float, target: Node) -> void:
		var t := target as Fighter
		if t and amount > 0.0 and not t.is_on_floor():
			pc.add_spirit(4.0)

	func _on_unequip() -> void:
		for f in hooked:
			if is_instance_valid(f):
				f.launch_bonus = 0.0
				f.attack_landed.disconnect(_on_landed)
		hooked.clear()


# ---------------------------------------------------------------- Dog: loyal (passive)
class Dog:
	extends Talisman
	var used := false
	var allies: Array[Fighter] = []

	func _init() -> void:
		title = "Dog"
		blurb = "Survive one lethal hit per room; the demon that 'killed' you joins you."

	func _on_equip() -> void:
		pc.hero.health.lethal_guard = _guard

	func _on_unequip() -> void:
		if pc.hero.health.lethal_guard == Callable(self, "_guard"):
			pc.hero.health.lethal_guard = Callable()

	func _guard(info: DamageInfo) -> bool:
		if used:
			return false
		used = true
		var killer := info.source as Fighter
		if killer and not killer.is_dead() and killer.team == Fighter.Team.ENEMY:
			killer.set_team(Fighter.Team.PLAYER)
			killer.collision_layer = 1 << 1
			killer.set_brain(AllyBrain.new(func() -> Fighter: return pc.controlled))
			killer.set_tint(Color(0.95, 0.75, 0.3, 0.3))
			allies.append(killer)
		Events.dog_saved.emit(pc.hero, killer)
		return true

	func on_room_cleared() -> void:
		used = false
		for a in allies:
			if is_instance_valid(a) and not a.is_dead():
				a.health.take(DamageInfo.make(99999.0))   # loyalty lasts one room
		allies.clear()


# ---------------------------------------------------------------- Pig: feast (magic)
class Pig:
	extends Talisman
	func _init() -> void:
		title = "Pig"
		blurb = "Eat a held food prop for chi + health. Otherwise: burp blast (magic)."
		cost = 15.0

	func is_active_talisman() -> bool:
		return true

	func activate() -> bool:
		var f := pc.controlled
		if not f.can_act():
			return false
		if f.held_prop and f.held_prop.data.element == &"food":
			var p := f.held_prop
			f.held_prop = null
			p.queue_free()
			pc.add_spirit(30.0)
			f.health.heal(10.0)
			f.anim.play(&"chi_enter", 0.08, 0.5)
			Events.food_eaten.emit(f)
			return true
		if pc.spirit < cost:
			return false
		pc.add_spirit(-cost)
		var a := AttackData.new()
		a.id = &"pig_burp"
		a.clip = &"chi_cast"
		a.duration = 0.6
		a.active_start = 0.25
		a.active_end = 0.4
		a.damage = 14.0
		a.magic = true
		a.knockback = 7.0
		a.lunge = 0.0
		a.hit_size = Vector3(2.2, 1.4, 3.2)
		a.hit_offset = Vector3(0, 1.0, 2.0)
		f.request_attack(a)
		return true


# ---------------------------------------------------------------- Dragon: dragon fire (magic)
class Dragon:
	extends Talisman
	const SECONDS := 10.0

	func _init() -> void:
		title = "Dragon"
		blurb = "Set the prop you hold on fire: it deals magic damage and burns."
		cost = 15.0

	func is_active_talisman() -> bool:
		return true

	func activate() -> bool:
		var f := pc.controlled
		if f.held_prop == null or not is_instance_valid(f.held_prop) or pc.spirit < cost:
			return false
		pc.add_spirit(-cost)
		f.held_prop.ignite(SECONDS)
		return true
