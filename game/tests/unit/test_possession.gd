extends GutTest

var _level: Node3D


func _root() -> Node3D:
	if _level == null or not is_instance_valid(_level):
		_level = Node3D.new()
		_level.add_to_group(&"level_root")
		add_child(_level)
	return _level

var hero: Fighter
var brute: Fighter
var pc: PlayerController


func _fighter(team: Fighter.Team, at: Vector3) -> Fighter:
	var f := Fighter.new()
	f.data = FighterData.new()
	f.data.knockdown_time = 5.0
	f.team = team
	f.position = at
	_root().add_child(f)
	return f


func before_all() -> void:
	Juice.enabled = false


func before_each() -> void:
	hero = _fighter(Fighter.Team.PLAYER, Vector3.ZERO)
	brute = _fighter(Fighter.Team.ENEMY, Vector3(0, 0, 1.5))
	brute.set_brain(AIBrain.new())
	pc = PlayerController.new()
	_root().add_child(pc)
	pc.setup(hero, null)


func after_each() -> void:
	for n in [hero, brute, pc]:
		if is_instance_valid(n):
			n.queue_free()
	await wait_process_frames(2)


func _knock(f: Fighter) -> void:
	var info := DamageInfo.make(1.0)
	info.knockdown = true
	f.receive_hit(info)


func test_needs_knockdown_and_spirit() -> void:
	pc.add_spirit(100)
	assert_false(pc.try_possess(), "standing target can't be possessed")
	_knock(brute)
	pc.spirit = 0.0
	assert_false(pc.try_possess(), "not enough spirit")
	pc.add_spirit(100)
	assert_true(pc.try_possess())


func test_possession_swaps_control_and_lays_body_down() -> void:
	pc.add_spirit(100)
	_knock(brute)
	pc.try_possess()
	assert_eq(pc.controlled, brute)
	assert_eq(brute.team, Fighter.Team.PLAYER)
	assert_eq(brute.brain, pc.brain)
	assert_eq(hero.state, Fighter.State.BODY)
	assert_null(hero.brain)


func test_body_hit_snaps_back_with_penalty() -> void:
	pc.add_spirit(100)
	_knock(brute)
	pc.try_possess()
	var before := hero.health.hp
	hero.receive_hit(DamageInfo.make(5.0))
	assert_null(pc.host, "possession ended")
	assert_eq(pc.controlled, hero)
	assert_eq(brute.team, Fighter.Team.ENEMY)
	assert_eq(hero.health.hp, before - 5.0 - pc.body_hit_penalty)


func test_spirit_drain_ends_possession() -> void:
	pc.add_spirit(100)
	_knock(brute)
	pc.try_possess()
	pc._physics_process(100.0)
	assert_null(pc.host)
	assert_eq(pc.controlled, hero)
