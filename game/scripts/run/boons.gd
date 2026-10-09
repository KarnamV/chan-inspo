class_name Boons
extends RefCounted
## Helper boons (design/concept.md → Helpers). Each is a passive, built on the Talisman base so it
## can hook the same signals. Offered as room rewards once the helper has been met.

const HELPERS := {
	&"stunt_coordinator": {"name": "Stunt Coordinator", "portrait": "portrait_stunt_coordinator",
		"boons": [&"combo_fill", &"prop_power", &"stunt_dodge", &"double_throw", &"extra_life", &"crowd_ko"],
		"intro": "Kid, you fight like a stunt double who lost the script. Good. Improvise. Every chair's a cue. Take this, and make it look dangerous."},
	&"street_chef": {"name": "Street Chef", "portrait": "portrait_street_chef",
		"boons": [&"food_fill", &"spicy_dmg", &"hearty_heal", &"feast_shield", &"chef_knife", &"second_helping"],
		"intro": "Demons ate my whole stall! You hungry? Fighting on an empty stomach is how heroes become lunch. Here, on the house."},
}

const INFO := {
	&"combo_fill": ["Variety Show", "Each different prop or move in a combo fills extra spirit."],
	&"prop_power": ["Breakaway Props", "Prop hits deal +30% damage."],
	&"stunt_dodge": ["Near Miss", "Dodging through a demon staggers it."],
	&"double_throw": ["Big Throw", "Thrown props deal +50% damage."],
	&"extra_life": ["Stunt Double", "+1 extra life: get back up once at half health."],
	&"crowd_ko": ["Domino Effect", "Knocking a demon down stuns demons around it."],
	&"food_fill": ["Snack Break", "Holding food slowly fills spirit."],
	&"spicy_dmg": ["Extra Spicy", "Fire deals +50% damage and burns twice as hot."],
	&"hearty_heal": ["Hearty Meal", "+25 max HP and a full heal."],
	&"feast_shield": ["Wok Shield", "The first hit you take in each room is blocked."],
	&"chef_knife": ["Knife Skills", "Light attacks deal +25% damage."],
	&"second_helping": ["Second Helping", "+1 extra life: get back up once at half health."],
}


static func helper_of(boon: StringName) -> StringName:
	for h in HELPERS:
		if boon in HELPERS[h].boons:
			return h
	return &""


## One-time effects of picking a boon (multipliers, lives, max HP). Never re-applied per room.
static func apply_once(id: StringName, pc: PlayerController) -> void:
	var m: Dictionary = Run.mods
	match id:
		&"prop_power": m.prop_mult = m.prop_mult * 1.3
		&"chef_knife": m.light_mult = m.light_mult * 1.25
		&"spicy_dmg": m.fire_mult = m.fire_mult * 1.5
		&"double_throw": m["throw_mult"] = float(m.get("throw_mult", 1.0)) * 1.5
		&"extra_life", &"second_helping": Run.extra_lives += 1
		&"hearty_heal":
			Run.max_hp_bonus += 25.0
			if pc:
				pc.hero.health.max_hp += 25.0
				pc.hero.health.hp = pc.hero.health.max_hp


static func make(id: StringName) -> Talisman:
	var b := Boon.new()
	b.id = id
	b.title = INFO[id][0]
	b.blurb = INFO[id][1]
	return b


class Boon:
	extends Talisman
	var _variety: Array = []
	var _variety_t := 0.0
	var _shield_used := false
	var _hooked: Array = []

	## Re-run every room (boons are re-equipped after each room change): behaviour hooks only.
	## One-time effects live in Boons.apply_once (called when the boon is picked).
	func _on_equip() -> void:
		on_controlled_changed(pc.controlled)
		if id == &"crowd_ko":
			Events.knocked_down.connect(_on_knockdown)

	func _on_unequip() -> void:
		if id == &"crowd_ko" and Events.knocked_down.is_connected(_on_knockdown):
			Events.knocked_down.disconnect(_on_knockdown)

	func on_controlled_changed(f: Fighter) -> void:
		if f == null or f in _hooked:
			return
		_hooked.append(f)
		match id:
			&"combo_fill":
				f.attack_started.connect(_on_attack_started)
			&"stunt_dodge":
				f.dodged.connect(_on_dodged.bind(f))
			&"feast_shield":
				f.shield_guard = _shield

	func _on_attack_started(a: AttackData) -> void:
		var key: StringName = a.id if a else &"special"
		var f := pc.controlled
		if f and f.attack_with_prop and is_instance_valid(f.attack_with_prop):
			key = StringName("prop_" + String(f.attack_with_prop.data.id))
		if key not in _variety:
			_variety.append(key)
			if _variety.size() >= 2:
				pc.add_spirit(4.0)
		_variety_t = 3.0

	func _on_dodged(f: Fighter) -> void:
		for n in f.get_tree().get_nodes_in_group(&"fighters"):
			var o := n as Fighter
			if o and o.team != f.team and not o.is_dead() and o.global_position.distance_to(f.global_position) < 2.2:
				var info := DamageInfo.make(0.0, f)
				info.stun = 0.6
				o.receive_hit(info)

	func _on_knockdown(e: Node) -> void:
		var down := e as Fighter
		if down == null or down.team == Fighter.Team.PLAYER:
			return
		for n in down.get_tree().get_nodes_in_group(&"fighters"):
			var o := n as Fighter
			if o and o != down and o.team == down.team and not o.is_dead() and o.global_position.distance_to(down.global_position) < 2.5:
				var info := DamageInfo.make(8.0, pc.controlled)
				info.stun = 0.7
				o.receive_hit(info)

	func _shield(_info: DamageInfo) -> bool:
		if _shield_used:
			return false
		_shield_used = true
		return true

	func tick(delta: float) -> void:
		if _variety_t > 0.0:
			_variety_t -= delta
			if _variety_t <= 0.0:
				_variety.clear()
		if id == &"food_fill":
			var f := pc.controlled
			if f and f.held_prop and is_instance_valid(f.held_prop) and f.held_prop.data.element == &"food":
				pc.add_spirit(3.0 * delta)

	func on_room_cleared() -> void:
		_shield_used = false
