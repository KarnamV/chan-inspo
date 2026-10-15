extends Node
## Visual showcase (not a test): Jackie runs every prop style's light, light, heavy against a
## standing dummy, then the bare-hand combo. For judging attack feel on recorded frames:
##   godot --path . --write-movie <dir>/f.png --fixed-fps 30 res://tests/showcase/prop_moves.tscn

const STEPS := [&"bare", &"chair", &"pole", &"bench", &"roast_duck"]
var arena: Arena
var dummy: Fighter
var step := -1
var t := 0.0
var presses := 0


func _ready() -> void:
	Juice.enabled = false   # hitstop runs on wall-clock time, which stretches it in --write-movie captures
	arena = Arena.new()
	arena.preset = "m1"
	arena.spawn_enemies = false
	arena.with_hud = false
	add_child(arena)
	for n in get_tree().get_nodes_in_group(&"props"):
		n.queue_free()
	arena.hero.set_brain(null)
	arena.hero.global_position = Vector3(0, 0, 1)
	arena.hero.facing = Vector3(0, 0, -1)
	arena.camera.size = 6.5
	dummy = arena.spawn_fighter(load("res://data/fighters/brute.tres"), Fighter.Team.ENEMY, Vector3(0, 0, -0.6))
	dummy.set_brain(null)
	dummy.health.max_hp = 99999
	dummy.health.hp = 99999
	var h := arena.hero
	h.attack_started.connect(func(a: AttackData) -> void: print("F%d start %s clip=%s dur=%.2f" % [Engine.get_physics_frames(), a.id, a.clip, a.duration]))
	h.attack_landed.connect(func(_i: DamageInfo, _a: float, _t: Node) -> void: print("F%d landed" % Engine.get_physics_frames()))
	_next()


func _next() -> void:
	step += 1
	presses = 0
	t = 0.0
	if step >= STEPS.size():
		get_tree().quit()
		return
	var h := arena.hero
	if h.held_prop:
		h.held_prop.queue_free()
		h.held_prop = null
	if STEPS[step] != &"bare":
		var p := arena.spawn_prop(STEPS[step], h.global_position)
		p.attach_to(h)
		h.held_prop = p
		p.durability = 999


func _physics_process(delta: float) -> void:
	t += delta
	var h := arena.hero
	dummy.global_position = Vector3(0, 0, -0.6)
	h.global_position = Vector3(0, 0, 1)
	if dummy.state == Fighter.State.KNOCKDOWN or dummy.state == Fighter.State.STAGGER:
		pass
	# mash-ish: a press every 0.12 s while presses remain
	var seq: Array = [&"l", &"l", &"l", &"h"] if STEPS[step] == &"bare" else [&"l", &"l", &"h"]
	if presses < seq.size():
		if t > 0.5 and h.can_act():
			if seq[presses] == &"l":
				h.request_light()
			else:
				h.request_heavy()
			presses += 1
	elif t > 1.0 and h.can_act() and dummy.state in [Fighter.State.IDLE, Fighter.State.STAGGER]:
		_next()
