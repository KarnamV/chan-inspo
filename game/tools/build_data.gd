extends SceneTree
## Generates data/*.tres (fighters, props) with ResourceSaver so the files are always valid.
## Run: godot --headless --path . -s tools/build_data.gd
## After first generation the .tres files are the source of truth (tune them in the Inspector);
## re-running overwrites them, so only re-run when adding new types.


func _init() -> void:
	DirAccess.make_dir_recursive_absolute("res://data/fighters")
	DirAccess.make_dir_recursive_absolute("res://data/props")
	_props()
	_fighters()
	print("build_data: done")
	quit()


func atk(id: StringName, clip: StringName, dur: float, a0: float, a1: float, dmg: float, kb: float,
		kd := false, lunge := 2.0, size := Vector3(1.0, 1.2, 1.1), off := Vector3(0, 1.0, 0.85), cw := -1.0) -> AttackData:
	var a := AttackData.new()
	a.id = id
	a.clip = clip
	a.duration = dur
	a.active_start = a0
	a.active_end = a1
	a.combo_window = cw if cw >= 0.0 else a1
	a.damage = dmg
	a.knockback = kb
	a.knockdown = kd
	a.lunge = lunge
	a.hit_size = size
	a.hit_offset = off
	a.stun = 0.45 if kd else 0.25
	return a


func attacks(list: Array) -> Array[AttackData]:
	var out: Array[AttackData] = []
	for a in list:
		out.append(a)
	return out


func _fighters() -> void:
	var hero := FighterData.new()
	hero.id = &"hero"
	hero.model = load("res://assets/characters/hero.glb")
	hero.height = 1.8
	hero.radius = 0.35
	hero.max_hp = 100.0
	hero.move_speed = 5.5
	hero.knockdown_time = 1.0
	hero.light_combo = attacks([
		atk(&"jab", &"punch_jab", 0.36, 0.11, 0.22, 6.0, 2.0, false, 2.5, Vector3(0.9, 1.2, 1.1), Vector3(0, 1.1, 0.8), 0.16),
		atk(&"cross", &"punch_cross", 0.42, 0.14, 0.26, 8.0, 3.0, false, 2.5, Vector3(0.9, 1.2, 1.1), Vector3(0, 1.1, 0.8), 0.2),
	])
	hero.heavy = atk(&"bare_heavy", &"punch_cross", 0.7, 0.34, 0.48, 10.0, 5.0, true, 3.5, Vector3(1.1, 1.3, 1.3), Vector3(0, 1.0, 0.9))
	_save(hero, "res://data/fighters/hero.tres")

	var brute := FighterData.new()
	brute.id = &"brute"
	brute.model = load("res://assets/characters/brute.glb")
	brute.height = 2.1
	brute.radius = 0.5
	brute.max_hp = 120.0
	brute.move_speed = 3.3
	brute.stagger_scale = 0.5
	brute.knockdown_time = 2.4
	brute.aggro_range = 14.0
	brute.attack_range = 2.1
	brute.attack_cooldown = 1.8
	var punch := atk(&"brute_punch", &"punch_cross", 0.75, 0.38, 0.52, 10.0, 3.0, false, 1.5, Vector3(1.2, 1.5, 1.4), Vector3(0, 1.2, 1.0))
	var slam := atk(&"brute_slam", &"swing", 1.1, 0.62, 0.8, 16.0, 6.0, true, 1.0, Vector3(1.8, 1.6, 1.9), Vector3(0, 1.0, 1.1))
	brute.ai_attacks = attacks([punch, slam])
	brute.light_combo = attacks([punch])
	brute.heavy = slam
	_save(brute, "res://data/fighters/brute.tres")


func _props() -> void:
	# pieces first (other props reference them)
	var stake := _prop(&"stake", PropData.Weight.LIGHT, 2, 11.0, 1.1, [])
	var wood_leg := _prop(&"wood_leg", PropData.Weight.LIGHT, 2, 9.0, 1.0, [])
	var stave := _prop(&"barrel_stave", PropData.Weight.LIGHT, 2, 9.0, 1.2, [])
	var plank := _prop(&"plank", PropData.Weight.LIGHT, 3, 10.0, 1.3, [stake])
	_prop(&"chair", PropData.Weight.LIGHT, 4, 14.0, 1.3, [wood_leg, wood_leg])
	_prop(&"bench", PropData.Weight.HEAVY, 5, 18.0, 1.8, [plank, wood_leg])
	_prop(&"crate", PropData.Weight.HEAVY, 3, 16.0, 1.3, [plank, plank])
	_prop(&"barrel", PropData.Weight.HEAVY, 4, 16.0, 1.4, [stave, stave])
	_prop(&"pole", PropData.Weight.LIGHT, 6, 12.0, 2.2, [stake])


func _prop(id: StringName, w: PropData.Weight, dur: int, dmg: float, reach: float, pieces: Array) -> PropData:
	var p := PropData.new()
	p.id = id
	var cat := "pieces" if id in [&"stake", &"wood_leg", &"barrel_stave", &"plank"] else "props"
	p.model = load("res://assets/%s/%s.glb" % [cat, id])
	p.weight = w
	p.durability = dur
	p.damage = dmg
	p.reach = reach
	p.knockback = 6.0 if w == PropData.Weight.HEAVY else 4.0
	var typed: Array[PropData] = []
	for x in pieces:
		typed.append(x)
	p.pieces = typed
	_save(p, "res://data/props/%s.tres" % id)
	return load("res://data/props/%s.tres" % id)


func _save(r: Resource, path: String) -> void:
	var err := ResourceSaver.save(r, path)
	if err != OK:
		push_error("save failed %s: %s" % [path, err])
