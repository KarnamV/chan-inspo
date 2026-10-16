extends GutTest

var _level: Node3D
var a: Fighter
var b: Fighter


func _root() -> Node3D:
	if _level == null or not is_instance_valid(_level):
		_level = Node3D.new()
		_level.add_to_group(&"level_root")
		add_child(_level)
		var floor_body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(30, 0.2, 30)
		cs.shape = bs
		floor_body.add_child(cs)
		floor_body.position.y = -0.1
		_level.add_child(floor_body)
	return _level


func _jab() -> AttackData:
	var j := AttackData.new()
	j.duration = 0.3
	j.active_start = 0.05
	j.active_end = 0.2
	j.damage = 10.0
	j.lunge = 0.0
	return j


func _fighter(team: Fighter.Team, at: Vector3, d: FighterData = null) -> Fighter:
	var f := Fighter.new()
	if d == null:
		d = FighterData.new()
		var arr: Array[AttackData] = [_jab()]
		d.light_combo = arr
	f.data = d
	f.team = team
	f.position = at
	_root().add_child(f)
	return f


func before_all() -> void:
	Juice.enabled = false


func after_each() -> void:
	for n in [a, b]:
		if is_instance_valid(n):
			n.queue_free()
	for n in get_tree().get_nodes_in_group(&"props"):
		n.queue_free()
	await wait_process_frames(2)


func test_perfect_dodge_staggers_attacker_and_crits_next() -> void:
	a = _fighter(Fighter.Team.PLAYER, Vector3.ZERO)
	b = _fighter(Fighter.Team.ENEMY, Vector3(0, 0, 1))
	a.request_dodge()
	var info := DamageInfo.make(20.0, b)
	assert_eq(a.receive_hit(info), 0.0, "perfect-dodged hit does no damage")
	assert_eq(a.health.hp, a.data.max_hp)
	assert_eq(b.state, Fighter.State.STAGGER, "attacker staggered")
	assert_true(a.crit_next, "counter: next hit crits")


func test_late_dodge_avoids_without_counter() -> void:
	a = _fighter(Fighter.Team.PLAYER, Vector3.ZERO)
	b = _fighter(Fighter.Team.ENEMY, Vector3(0, 0, 1))
	a.request_dodge()
	a.state_t = a.data.parry_window + 0.05
	assert_eq(a.receive_hit(DamageInfo.make(20.0, b)), 0.0, "still inside the i-frames")
	assert_ne(b.state, Fighter.State.STAGGER, "no counter for a late dodge")
	assert_false(a.crit_next)


func test_parry_button_dodges() -> void:
	a = _fighter(Fighter.Team.PLAYER, Vector3.ZERO)
	a.request_parry()
	assert_eq(a.state, Fighter.State.DODGE)


func test_light_out_of_dodge_is_dash_strike() -> void:
	a = _fighter(Fighter.Team.PLAYER, Vector3.ZERO)
	a.request_dodge()
	a.state_t = Fighter.DODGE_FOLLOW_FROM + 0.01
	a.request_light()
	assert_eq(a.state, Fighter.State.ATTACK)
	assert_eq(a.attack.id, &"dash_strike")


func test_light_after_perfect_dodge_is_counter_spin() -> void:
	a = _fighter(Fighter.Team.PLAYER, Vector3.ZERO)
	b = _fighter(Fighter.Team.ENEMY, Vector3(0, 0, 1))
	a.request_dodge()
	a.receive_hit(DamageInfo.make(20.0, b))
	a.state_t = Fighter.DODGE_FOLLOW_FROM + 0.01
	a.request_light()
	assert_eq(a.attack.id, &"counter_spin")
	assert_eq(a.counter_t, 0.0, "counter used up")


func test_heavy_just_after_dodge_is_leap_slam() -> void:
	a = _fighter(Fighter.Team.PLAYER, Vector3.ZERO)
	a.request_dodge()
	a.state_t = a.data.dodge_time + 0.01
	await wait_physics_frames(1)
	assert_eq(a.state, Fighter.State.IDLE)
	a.request_heavy()
	assert_eq(a.attack.id, &"leap_slam")


func test_plain_light_is_still_the_combo() -> void:
	a = _fighter(Fighter.Team.PLAYER, Vector3.ZERO)
	a.request_light()
	assert_eq(a.attack, a.data.light_combo[0])


func test_dodge_passes_through_fighters() -> void:
	a = _fighter(Fighter.Team.PLAYER, Vector3.ZERO)
	a.request_dodge()
	assert_eq(a.collision_mask & (1 << 2), 0, "enemy bodies ignored mid-dodge")
	a.state_t = a.data.dodge_time + 0.01
	await wait_physics_frames(2)
	assert_ne(a.collision_mask & (1 << 2), 0, "solid again after the dodge")


func test_dodge_ending_inside_a_demon_eases_out_before_turning_solid() -> void:
	a = _fighter(Fighter.Team.PLAYER, Vector3.ZERO)
	b = _fighter(Fighter.Team.ENEMY, Vector3(0, 0, 0.2))
	a.request_dodge()
	a.state_t = a.data.dodge_time + 0.01
	await wait_physics_frames(2)
	assert_eq(a.collision_mask & (1 << 2), 0, "still passing through while overlapping")
	await wait_physics_frames(30)
	var gap := Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length()
	assert_gt(gap, a.data.radius + b.data.radius, "pushed clear")
	assert_ne(a.collision_mask & (1 << 2), 0, "solid once clear")


func test_shield_blocks_front_not_back_not_shatter() -> void:
	var d := FighterData.new()
	d.front_block = true
	a = _fighter(Fighter.Team.ENEMY, Vector3.ZERO, d)   # shield demon facing +Z
	a.facing = Vector3(0, 0, 1)
	b = _fighter(Fighter.Team.PLAYER, Vector3(0, 0, 1.5))
	assert_eq(a.receive_hit(DamageInfo.make(10.0, b)), 0.0, "front hit blocked")
	b.global_position = Vector3(0, 0, -1.5)
	assert_gt(a.receive_hit(DamageInfo.make(10.0, b)), 0.0, "hit from behind lands")
	b.global_position = Vector3(0, 0, 1.5)
	var s := DamageInfo.make(10.0, b)
	s.shatter = true
	assert_gt(a.receive_hit(s), 0.0, "breaking a prop on the shield goes through")


func test_fire_burns_water_douses() -> void:
	a = _fighter(Fighter.Team.ENEMY, Vector3.ZERO)
	var fire := DamageInfo.make(5.0)
	fire.element = &"fire"
	a.receive_hit(fire)
	assert_gt(a.status.burning, 0.0)
	var hp := a.health.hp
	a.status._physics_process(1.0)
	assert_lt(a.health.hp, hp, "burn ticks damage")
	var water := DamageInfo.make(1.0)
	water.element = &"water"
	a.receive_hit(water)
	assert_eq(a.status.burning, 0.0, "water puts it out")


func test_chi_locked_then_unlocked_costs_spirit() -> void:
	a = _fighter(Fighter.Team.PLAYER, Vector3.ZERO)
	var pc := PlayerController.new()
	_root().add_child(pc)
	pc.setup(a, null)
	pc.add_spirit(100)
	assert_false(pc.use_chi(0), "palm locked at start")
	pc.unlock_all_chi()
	assert_true(pc.use_chi(0))
	assert_eq(pc.spirit, 100.0 - pc.CHI_COST[&"palm"])
	assert_eq(a.state, Fighter.State.ATTACK)
	assert_true(a.attack.magic, "chi palm is magic damage")
	pc.queue_free()


func test_dodge_catches_thrown_prop() -> void:
	a = _fighter(Fighter.Team.PLAYER, Vector3.ZERO)
	b = _fighter(Fighter.Team.ENEMY, Vector3(0, 0, 6))
	var pd := PropData.new()
	pd.durability = 3
	var p := Prop.new()
	p.data = pd
	p.position = Vector3(0, 1, 0.8)
	_root().add_child(p)
	p.mode = Prop.Mode.THROWN
	p.thrower = b
	a.request_dodge()
	await wait_physics_frames(2)
	assert_eq(a.held_prop, p, "caught out of the air")
	assert_eq(p.mode, Prop.Mode.HELD)


func test_throw_aims_at_the_demon_in_front() -> void:
	a = _fighter(Fighter.Team.PLAYER, Vector3.ZERO)
	b = _fighter(Fighter.Team.ENEMY, Vector3(3, 0, 6))   # ~27 degrees off facing (+Z)
	a.facing = Vector3(0, 0, 1)
	var p := Prop.new()
	p.data = load("res://data/props/chair.tres")
	add_child_autofree(p)
	p.attach_to(a)
	a.held_prop = p
	a.request_grab()
	assert_eq(a.state, Fighter.State.THROW)
	var to := (b.global_position - a.global_position).normalized()
	assert_gt(a.facing.dot(to), 0.99, "turned to face the demon")
	var v := a._throw_velocity(p)
	assert_gt(Vector3(v.x, 0, v.z).normalized().dot(Vector3(to.x, 0, to.z).normalized()), 0.97, "thrown at it")


func test_throw_with_no_demon_ahead_goes_straight() -> void:
	a = _fighter(Fighter.Team.PLAYER, Vector3.ZERO)
	b = _fighter(Fighter.Team.ENEMY, Vector3(-6, 0, -1))   # behind and to the side
	a.facing = Vector3(0, 0, 1)
	assert_null(a._throw_target())
