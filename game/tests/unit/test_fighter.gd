extends GutTest

var _level: Node3D


func _root() -> Node3D:
	if _level == null or not is_instance_valid(_level):
		_level = Node3D.new()
		_level.add_to_group(&"level_root")
		add_child(_level)
	return _level

var a: Fighter
var b: Fighter


func _data() -> FighterData:
	var d := FighterData.new()
	d.knockdown_time = 0.5
	var jab := AttackData.new()
	jab.clip = &"punch_jab"
	jab.duration = 0.3
	jab.active_start = 0.05
	jab.active_end = 0.2
	jab.damage = 10.0
	jab.lunge = 0.0
	var arr: Array[AttackData] = [jab]
	d.light_combo = arr
	return d


func _fighter(team: Fighter.Team, at: Vector3) -> Fighter:
	var f := Fighter.new()
	f.data = _data()
	f.team = team
	f.position = at
	_root().add_child(f)
	return f


func before_all() -> void:
	Juice.enabled = false


func before_each() -> void:
	a = _fighter(Fighter.Team.PLAYER, Vector3(0, 0, 0))
	b = _fighter(Fighter.Team.ENEMY, Vector3(0, 0, 1.0))


func after_each() -> void:
	a.queue_free()
	b.queue_free()
	await wait_process_frames(2)


func test_light_attack_lands_through_physics() -> void:
	a.facing = Vector3(0, 0, 1)
	a.request_light()
	await wait_physics_frames(30)
	assert_eq(b.health.hp, b.data.max_hp - 10.0, "jab hit once (not every frame)")


func test_same_team_is_not_hit() -> void:
	b.set_team(Fighter.Team.PLAYER)
	a.facing = Vector3(0, 0, 1)
	a.request_light()
	await wait_physics_frames(30)
	assert_eq(b.health.hp, b.data.max_hp)


func test_knockdown_then_get_up() -> void:
	var info := DamageInfo.make(5.0)
	info.knockdown = true
	b.receive_hit(info)
	assert_true(b.is_knocked_down())
	await wait_seconds(0.5 + 0.6 + 0.2)
	assert_eq(b.state, Fighter.State.IDLE, "back on feet after knockdown_time + getup")


func test_dodge_iframes() -> void:
	a.request_dodge()
	assert_eq(a.state, Fighter.State.DODGE)
	assert_eq(a.receive_hit(DamageInfo.make(30.0)), 0.0, "invulnerable at dodge start")
	assert_eq(a.health.hp, a.data.max_hp)
