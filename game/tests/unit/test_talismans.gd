extends GutTest
## One check per talisman rule (design/concept.md → Talismans).

var _level: Node3D
var hero: Fighter
var foe: Fighter
var pc: PlayerController


func _root() -> Node3D:
	if _level == null or not is_instance_valid(_level):
		_level = Node3D.new()
		_level.add_to_group(&"level_root")
		add_child(_level)
		var fb := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(40, 0.2, 40)
		cs.shape = bs
		fb.add_child(cs)
		fb.position.y = -0.1
		_level.add_child(fb)
	return _level


func _fd() -> FighterData:
	var d := FighterData.new()
	d.knockdown_time = 5.0
	var j := AttackData.new()
	j.duration = 0.3
	j.active_start = 0.05
	j.active_end = 0.2
	j.damage = 10.0
	j.lunge = 0.0
	var arr: Array[AttackData] = [j]
	d.light_combo = arr
	return d


func _fighter(team: Fighter.Team, at: Vector3) -> Fighter:
	var f := Fighter.new()
	f.data = _fd()
	f.team = team
	f.position = at
	_root().add_child(f)
	return f


func _prop(element: StringName = &"", at := Vector3(0, 0.2, 1.2)) -> Prop:
	var d := PropData.new()
	d.durability = 4
	d.damage = 10.0
	d.element = element
	var p := Prop.new()
	p.data = d
	p.position = at
	_root().add_child(p)
	return p


func before_all() -> void:
	Juice.enabled = false


func before_each() -> void:
	hero = _fighter(Fighter.Team.PLAYER, Vector3.ZERO)
	foe = _fighter(Fighter.Team.ENEMY, Vector3(0, 0, 1.6))
	foe.set_brain(AIBrain.new())
	pc = PlayerController.new()
	_root().add_child(pc)
	pc.setup(hero, null)
	pc.add_spirit(100)


func after_each() -> void:
	pc.equip([])
	for n in _root().get_children():
		if n is Fighter or n is Prop or n is PlayerController:
			n.queue_free()
	await wait_process_frames(2)


func _knock(f: Fighter) -> void:
	var i := DamageInfo.make(1.0)
	i.knockdown = true
	f.receive_hit(i)


func test_equip_three_max() -> void:
	pc.equip([&"sheep", &"tiger", &"rat", &"ox"])
	assert_eq(pc.equipped.size(), 3)


func test_sheep_slot_possesses() -> void:
	pc.equip([&"sheep"])
	_knock(foe)
	assert_true(pc.use_talisman(0))
	assert_eq(pc.controlled, foe)
	assert_true(pc.use_talisman(0), "press again to release")
	assert_eq(pc.controlled, hero)


func test_tiger_split_yin_yang_swap_and_merge() -> void:
	pc.equip([&"tiger"])
	var base := hero.health.max_hp
	assert_true(pc.use_talisman(0))
	var tiger := pc.talisman(&"tiger") as Zodiac.Tiger
	var twin := tiger.twin
	assert_not_null(twin)
	assert_almost_eq(hero.health.max_hp, base * 1.3, 0.01, "Yang: more HP")
	assert_almost_eq(twin.health.max_hp, base * 0.7, 0.01, "Yin: less HP")
	assert_eq(hero.dmg_mult_physical, 1.4)
	assert_eq(twin.dmg_mult_magic, 1.6)
	assert_true(twin.brain is AllyBrain, "the other twin is AI")
	pc.use_talisman(0)
	assert_eq(pc.controlled, twin, "tap again: swap control")
	tiger.tick(tiger.DURATION + 1.0)
	assert_null(tiger.twin, "merged after the duration")
	assert_eq(pc.controlled, hero)
	assert_almost_eq(hero.health.max_hp, base, 0.01)


func test_tiger_yang_falls_continue_as_yin() -> void:
	pc.equip([&"tiger"])
	pc.use_talisman(0)
	var twin := (pc.talisman(&"tiger") as Zodiac.Tiger).twin
	hero.receive_hit(DamageInfo.make(99999.0))
	assert_false(hero.is_dead(), "hero survives the lethal hit while a twin lives")
	assert_almost_eq(hero.global_position.x, twin.global_position.x, 0.01, "continues from the twin's spot")


func test_monkey_needs_a_beaten_boss_and_limits_attacks() -> void:
	pc.equip([&"monkey"])
	assert_false(pc.use_talisman(0), "no boss beaten yet")
	pc.boss_ledger = {&"hero": 1}   # any FighterData stands in for a boss form here
	assert_true(pc.use_talisman(0))
	var m := pc.talisman(&"monkey") as Zodiac.Monkey
	assert_not_null(m.form)
	assert_eq(pc.controlled, m.form)
	assert_true(hero.hidden, "Jackie is inside the form")
	assert_eq(m.attacks_left, m.BASE_LIMIT)
	for i in m.BASE_LIMIT:
		m._on_form_attack(null)
	await wait_process_frames(2)
	assert_null(m.form, "attack limit reached: back to Jackie")
	assert_eq(pc.controlled, hero)
	assert_false(hero.hidden)


func test_monkey_repeat_kills_raise_limit() -> void:
	pc.equip([&"monkey"])
	pc.boss_ledger = {&"hero": 3}
	pc.use_talisman(0)
	var m := pc.talisman(&"monkey") as Zodiac.Monkey
	assert_eq(m.attacks_left, m.BASE_LIMIT + 2 * m.PER_EXTRA_KILL)


func test_rat_animates_a_prop_that_attacks() -> void:
	pc.equip([&"rat"])
	hero.facing = Vector3(0, 0, 1)
	var p := _prop(&"", Vector3(0, 0.2, 0.8))
	assert_true(pc.use_talisman(0))
	assert_eq(p.animator, hero)
	await wait_physics_frames(40)
	assert_true(p.mode == Prop.Mode.THROWN or foe.health.hp < foe.data.max_hp, "the prop went after the demon")


func test_ox_heavy_one_hand_and_demon_swing() -> void:
	pc.equip([&"ox"])
	assert_true(hero.heavy_one_hand)
	_knock(foe)
	hero.request_grab()
	assert_eq(hero.state, Fighter.State.ATTACK, "grabbing a downed demon starts the giant swing")
	assert_lt(foe.health.hp, foe.data.max_hp)


func test_rabbit_widens_parry_and_perfect_dodge_refills() -> void:
	pc.equip([&"rabbit"])
	assert_eq(hero.parry_mult, 2.0)
	hero.request_dodge()
	hero.dodge_cd = 1.0
	watch_signals(hero)
	hero.receive_hit(DamageInfo.make(10.0, foe))
	assert_signal_emitted(hero, "perfect_dodge")
	assert_eq(hero.dodge_cd, 0.0)


func test_snake_stealth_after_dodge() -> void:
	pc.equip([&"snake"])
	hero.request_dodge()
	assert_true(hero.stealthed)
	assert_true(hero.crit_next)
	(pc.talisman(&"snake") as Zodiac.Snake).tick(2.1)
	assert_false(hero.stealthed)


func test_horse_lifesteal() -> void:
	pc.equip([&"horse"])
	hero.health.hp = 50.0
	Events.damage_dealt.emit(foe, DamageInfo.make(50.0, hero), 50.0)
	assert_almost_eq(hero.health.hp, 54.0, 0.01, "8% of 50")


func test_rooster_launch_bonus() -> void:
	pc.equip([&"rooster"])
	assert_eq(hero.launch_bonus, 5.0)


func test_dog_survives_lethal_once_and_converts_killer() -> void:
	pc.equip([&"dog"])
	hero.receive_hit(DamageInfo.make(99999.0, foe))
	assert_false(hero.is_dead())
	assert_eq(hero.health.hp, 1.0)
	assert_eq(foe.team, Fighter.Team.PLAYER, "killer joins you")
	hero.receive_hit(DamageInfo.make(99999.0, foe))
	assert_true(hero.is_dead(), "only once per room")


func test_pig_eats_food_for_chi() -> void:
	pc.equip([&"pig"])
	pc.spirit = 10.0
	var p := _prop(&"food")
	p.attach_to(hero)
	hero.held_prop = p
	assert_true(pc.use_talisman(0))
	assert_eq(pc.spirit, 40.0)
	assert_null(hero.held_prop)


func test_dragon_ignites_held_prop() -> void:
	pc.equip([&"dragon"])
	var p := _prop()
	assert_false(pc.use_talisman(0), "nothing held")
	p.attach_to(hero)
	hero.held_prop = p
	assert_true(pc.use_talisman(0))
	assert_eq(p.current_element(), &"fire")
