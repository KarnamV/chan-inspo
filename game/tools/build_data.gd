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
	_m2_enemies()
	_bosses()


func _enemy(id: StringName, hp: float, speed: float, h: float, r: float, attacks_list: Array) -> FighterData:
	var d := FighterData.new()
	d.id = id
	d.model = _model("res://assets/characters/%s.glb" % id)
	d.max_hp = hp
	d.move_speed = speed
	d.height = h
	d.radius = r
	d.ai_attacks = attacks(attacks_list)
	d.light_combo = attacks([attacks_list[0]])
	d.heavy = attacks_list[-1]
	return d


func _m2_enemies() -> void:
	var bash := atk(&"shield_bash", &"punch_cross", 0.7, 0.35, 0.5, 9.0, 5.0, false, 2.0, Vector3(1.4, 1.5, 1.3), Vector3(0, 1.0, 0.9))
	var shield := _enemy(&"shield_demon", 90.0, 3.6, 1.9, 0.45, [bash])
	shield.front_block = true
	shield.stagger_scale = 0.8
	shield.attack_range = 1.9
	_save(shield, "res://data/fighters/shield_demon.tres")

	var scratch := atk(&"imp_scratch", &"punch_jab", 0.4, 0.15, 0.26, 4.0, 1.5, false, 2.0, Vector3(0.8, 1.0, 0.9), Vector3(0, 0.6, 0.6))
	var imp := _enemy(&"thief_imp", 45.0, 6.0, 1.3, 0.3, [scratch])
	imp.ai_kind = FighterData.AiKind.THIEF
	imp.attack_cooldown = 1.4
	imp.knockdown_time = 1.6
	_save(imp, "res://data/fighters/thief_imp.tres")

	var stab := atk(&"archer_stab", &"punch_jab", 0.45, 0.18, 0.3, 6.0, 2.0, false, 1.5)
	var archer := _enemy(&"archer_demon", 60.0, 4.2, 1.8, 0.35, [stab])
	archer.ai_kind = FighterData.AiKind.RANGED
	archer.keep_distance = 7.0
	archer.attack_cooldown = 2.0
	_save(archer, "res://data/fighters/archer_demon.tres")

	var claw := atk(&"wraith_claw", &"chi_cast", 0.7, 0.3, 0.45, 10.0, 4.0, false, 1.0, Vector3(1.2, 1.4, 2.0), Vector3(0, 1.1, 1.2))
	claw.magic = true
	var wraith := _enemy(&"wraith", 70.0, 3.8, 1.9, 0.4, [claw])
	wraith.resist_physical = 0.75
	wraith.hover = 0.25
	wraith.attack_range = 2.2
	_save(wraith, "res://data/fighters/wraith.tres")

	var maul := atk(&"ghoul_maul", &"swing", 1.0, 0.55, 0.72, 14.0, 5.0, true, 1.0, Vector3(1.6, 1.5, 1.7), Vector3(0, 1.0, 1.0))
	var ghoul := _enemy(&"armored_ghoul", 110.0, 2.6, 1.8, 0.45, [maul])
	ghoul.resist_physical = 0.5
	ghoul.resist_magic = 0.8
	ghoul.stagger_scale = 0.6
	ghoul.attack_cooldown = 2.0
	_save(ghoul, "res://data/fighters/armored_ghoul.tres")


func _bosses() -> void:
	var slash := atk(&"cleaver_slash", &"swing", 0.7, 0.32, 0.48, 14.0, 5.0, false, 2.0, Vector3(2.2, 1.8, 2.2), Vector3(0, 1.2, 1.3))
	var slash2 := atk(&"cleaver_backhand", &"punch_cross", 0.65, 0.3, 0.45, 12.0, 6.0, false, 2.0, Vector3(2.2, 1.8, 2.2), Vector3(0, 1.2, 1.3))
	var b := FighterData.new()
	b.id = &"butcher_king"
	b.model = _model("res://assets/characters/butcher_king.glb")
	b.max_hp = 600.0
	b.move_speed = 3.0
	b.height = 2.6
	b.radius = 0.75
	b.stagger_scale = 0.15
	b.knockdown_immune = true
	b.kit = &"butcher"
	b.boss = true
	b.attack_cooldown = 1.4
	b.light_combo = attacks([slash, slash2])
	b.heavy = slash
	b.ai_attacks = attacks([slash, slash2])
	_save(b, "res://data/fighters/butcher_king.tres")


func _props() -> void:
	# pieces first (other props reference them)
	var stake := _prop(&"stake", PropData.Weight.LIGHT, 2, 11.0, 1.1, [])
	var wood_leg := _prop(&"wood_leg", PropData.Weight.LIGHT, 2, 9.0, 1.0, [])
	var stave := _prop(&"barrel_stave", PropData.Weight.LIGHT, 2, 9.0, 1.2, [])
	var plank := _prop(&"plank", PropData.Weight.LIGHT, 3, 10.0, 1.3, [stake])
	var shard := _prop(&"pottery_shard", PropData.Weight.LIGHT, 1, 8.0, 0.9, [])
	var scrap := _prop(&"metal_scrap", PropData.Weight.LIGHT, 2, 9.0, 1.0, [])
	_prop(&"chair", PropData.Weight.LIGHT, 4, 14.0, 1.3, [wood_leg, wood_leg])
	_prop(&"bench", PropData.Weight.HEAVY, 5, 18.0, 1.8, [plank, wood_leg])
	_prop(&"crate", PropData.Weight.HEAVY, 3, 16.0, 1.3, [plank, plank])
	_prop(&"barrel", PropData.Weight.HEAVY, 4, 16.0, 1.4, [stave, scrap])
	_prop(&"pole", PropData.Weight.LIGHT, 6, 12.0, 2.2, [stake])
	# M2: element + food props
	_prop(&"lantern", PropData.Weight.LIGHT, 2, 10.0, 1.1, [], &"fire")
	_prop(&"bucket", PropData.Weight.LIGHT, 2, 9.0, 1.1, [plank], &"water")
	_prop(&"spirit_urn", PropData.Weight.LIGHT, 3, 16.0, 1.2, [shard, shard], &"magic")
	_prop(&"spear", PropData.Weight.LIGHT, 5, 13.0, 2.4, [stake])
	_prop(&"stool", PropData.Weight.LIGHT, 3, 11.0, 1.1, [wood_leg])
	_prop(&"bun_basket", PropData.Weight.LIGHT, 1, 6.0, 1.0, [], &"food")
	_prop(&"roast_duck", PropData.Weight.LIGHT, 1, 7.0, 1.0, [], &"food")
	_prop(&"fruit_cart", PropData.Weight.HEAVY, 4, 18.0, 1.6, [plank, plank], &"food")
	_prop(&"weapon_rack", PropData.Weight.HEAVY, 4, 16.0, 1.4, [plank, stake])


func _prop(id: StringName, w: PropData.Weight, dur: int, dmg: float, reach: float, pieces: Array, element: StringName = &"") -> PropData:
	var p := PropData.new()
	p.id = id
	var cat := "pieces" if id in [&"stake", &"wood_leg", &"barrel_stave", &"plank", &"pottery_shard", &"metal_scrap"] else "props"
	p.model = _model("res://assets/%s/%s.glb" % [cat, id])
	p.weight = w
	p.durability = dur
	p.damage = dmg
	p.reach = reach
	p.knockback = 6.0 if w == PropData.Weight.HEAVY else 4.0
	p.element = element
	var typed: Array[PropData] = []
	for x in pieces:
		typed.append(x)
	p.pieces = typed
	_save(p, "res://data/props/%s.tres" % id)
	return load("res://data/props/%s.tres" % id)


func _model(path: String) -> PackedScene:
	return load(path) if ResourceLoader.exists(path) else null


func _save(r: Resource, path: String) -> void:
	var err := ResourceSaver.save(r, path)
	if err != OK:
		push_error("save failed %s: %s" % [path, err])
