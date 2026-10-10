extends GutTest
## A prop only wears when it actually connects: swinging at air, at an invulnerable demon, or
## throwing it at nothing costs no durability.

var _level: Node3D
var hero: Fighter


func before_all() -> void:
	Juice.enabled = false


func _root() -> Node3D:
	if _level == null or not is_instance_valid(_level):
		_level = Node3D.new()
		_level.add_to_group(&"level_root")
		add_child(_level)
	return _level


func _fighter(team: Fighter.Team, at: Vector3, id := &"hero") -> Fighter:
	var f := Fighter.new()
	f.data = load("res://data/fighters/%s.tres" % id)
	f.team = team
	f.position = at
	_root().add_child(f)
	return f


func _hold(id: StringName) -> Prop:
	var p := Prop.new()
	p.data = load("res://data/props/%s.tres" % id)
	_root().add_child(p)
	p.attach_to(hero)
	hero.held_prop = p
	return p


func before_each() -> void:
	hero = _fighter(Fighter.Team.PLAYER, Vector3.ZERO)
	hero.facing = Vector3(0, 0, 1)


func after_each() -> void:
	for n in _root().get_children():
		n.queue_free()
	await wait_process_frames(2)


func test_swing_at_air_costs_nothing() -> void:
	var p := _hold(&"chair")
	var before := p.durability_left()
	hero.request_light()
	await wait_seconds(0.7)
	assert_eq(p.durability_left(), before)


func test_swing_at_invulnerable_demon_costs_nothing() -> void:
	var p := _hold(&"chair")
	var before := p.durability_left()
	var b := _fighter(Fighter.Team.ENEMY, Vector3(0, 0, 1.2), &"brute")
	b._set_state(Fighter.State.GETUP)   # getting up = invulnerable
	b.knock_time = 99.0
	hero.request_light()
	await wait_seconds(0.3)
	assert_eq(b.health.hp, b.health.max_hp, "no damage dealt")
	assert_eq(p.durability_left(), before)


func test_swing_that_connects_wears() -> void:
	var p := _hold(&"chair")
	var before := p.durability_left()
	_fighter(Fighter.Team.ENEMY, Vector3(0, 0, 1.2), &"brute")
	hero.request_light()
	await wait_seconds(0.5)
	assert_eq(p.durability_left(), before - 1)


func test_throw_at_nothing_costs_nothing() -> void:
	var p := _hold(&"chair")
	var before := p.durability_left()
	var floor_body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(40, 0.2, 40)
	cs.shape = box
	floor_body.add_child(cs)
	floor_body.position = Vector3(0, -0.1, 0)
	_root().add_child(floor_body)
	hero.request_grab()   # throw
	await wait_seconds(1.5)
	assert_true(is_instance_valid(p), "still exists")
	assert_eq(p.durability_left(), before)
