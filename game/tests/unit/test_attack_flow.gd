extends GutTest
## Attack flow (polish pass): prop swings chain and alternate, recovery can be cut short by a queued
## light, a heavy or walking away, and a same-clip follow-up restarts its animation.

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


func _hold(id: StringName) -> Prop:
	var p := Prop.new()
	p.data = load("res://data/props/%s.tres" % id)
	_root().add_child(p)
	p.attach_to(hero)
	hero.held_prop = p
	p.durability = 99
	return p


func before_each() -> void:
	hero = Fighter.new()
	hero.data = load("res://data/fighters/hero.tres")
	hero.team = Fighter.Team.PLAYER
	_root().add_child(hero)
	hero.facing = Vector3(0, 0, 1)


func after_each() -> void:
	for n in _root().get_children():
		n.queue_free()
	await wait_process_frames(2)


func test_prop_light_queues_and_alternates() -> void:
	_hold(&"chair")
	hero.request_light()
	var first := hero.attack
	assert_eq(first.clip, &"swing")
	hero.state_t = first.active_start + 0.01
	hero.request_light()
	assert_true(hero.queued_light, "a press during a prop swing queues the next one")
	await wait_physics_frames(60)
	assert_ne(hero.attack, first, "the queued swing fired")
	assert_eq(hero.attack.clip, &"chop", "second swing is the backhand chop")


func test_queued_light_fires_before_the_clip_ends() -> void:
	_hold(&"chair")
	hero.request_light()
	var a := hero.attack
	hero.queued_light = true
	hero.state_t = hero._chain_point() + 0.001
	hero._physics_process(0.0)
	assert_ne(hero.attack, a, "chains at the chain point, not at the end of the clip")
	assert_lt(hero._chain_point(), a.duration)


func test_prop_light_cancels_into_heavy() -> void:
	_hold(&"chair")
	hero.request_light()
	hero.state_t = hero.attack.active_end + 0.01
	hero.request_heavy()
	assert_eq(hero.attack.id, &"prop_club_heavy")
	assert_eq(hero.state_t, 0.0)


func test_walking_cuts_recovery_short() -> void:
	hero.set_brain(_Push.new())   # intent_move is reset every frame, so push through a brain
	hero.request_light()
	hero.state_t = hero._chain_point() + 0.001
	hero._physics_process(0.0)
	assert_eq(hero.state, Fighter.State.IDLE)


func test_same_clip_restarts() -> void:
	hero.anim.play(&"chop", 0.0, 0.5)
	hero.anim.player.seek(0.4, true)
	hero.anim.play(&"chop", 0.0, 0.5)
	assert_almost_eq(hero.anim.player.current_animation_position, 0.0, 0.01)


class _Push:
	extends Brain
	func think(f: Fighter, _delta: float) -> void:
		f.intent_move = Vector3(1, 0, 0)
