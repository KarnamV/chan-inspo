extends Node
## Visual showcase (not a test): screenshots of the hub, a combat room and the boss room,
## wide and close, for judging the art before/after a pass. Windowed (needs a renderer):
##   godot --path . res://tests/showcase/look_shots.tscn -- --out=<abs dir>
## Opening the hub writes the real save: back up meta.json first (see design/tech.md).

const SHOTS := [["hub", -1], ["room", 1], ["boss", 9], ["props", 1]]
const SETTLE := 150   # frames after a scene change (fade in, spawns, physics settle)

var out_dir := "user://look_shots"
var shot := -1
var frames := 0
var _moved := false


func _ready() -> void:
	Juice.enabled = false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.split("=")[1]
		if arg.begins_with("--look="):   # none / rim / outline / both: compare readability passes
			CharacterLook.mode = CharacterLook.Mode[arg.split("=")[1].to_upper()]
	DirAccess.make_dir_recursive_absolute(out_dir)
	_reparent_to_root.call_deferred()


func _reparent_to_root() -> void:   # survive change_scene
	var r := get_tree().root
	get_parent().remove_child(self)
	r.add_child(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_moved = true
	_next()


func _next() -> void:
	shot += 1
	frames = 0
	if shot >= SHOTS.size():
		get_tree().quit()
		return
	var name: String = SHOTS[shot][0]
	if name == "hub":
		get_tree().change_scene_to_file(Run.HUB_SCENE)
	else:
		Run.start_run([&"sheep", &"tiger", &"rat"], 7)
		Run.room_i = SHOTS[shot][1]
		get_tree().change_scene_to_file(Run.ROOM_SCENE)


func _process(_delta: float) -> void:
	if not _moved or shot >= SHOTS.size():
		return
	frames += 1
	var cs := get_tree().current_scene
	if cs == null:
		return
	for f in cs.find_children("*", "Fighter", true, false):   # freeze the cast so shots compare
		var fi := f as Fighter
		if fi.brain:
			fi.set_brain(null)
	var cam := cs.get("camera") as Camera3D
	var name: String = SHOTS[shot][0]
	if frames == SETTLE - 40 and cs is Arena:
		if name == "props":
			_line_up_props(cs as Arena)
		else:   # walk Jackie up to the nearest demon so both are in frame
			_frame_fight(cs as Arena)
	if frames == SETTLE:
		_save(name + "_wide")
		if cam:
			cam.size = cam.size * 0.5
	elif frames == SETTLE + 20:
		_save(name + "_close")
		_next()


func _frame_fight(a: Arena) -> void:
	var best: Fighter = null
	for f in a.find_children("*", "Fighter", true, false):
		var fi := f as Fighter
		if fi.team == Fighter.Team.ENEMY and (best == null or fi.global_position.distance_to(a.hero.global_position)
				< best.global_position.distance_to(a.hero.global_position)):
			best = fi
	if best == null:
		return
	var right := a.camera.global_transform.basis.x * Vector3(1, 0, 1)
	a.hero.global_position = best.global_position + right.normalized() * 2.4
	a.hero.facing = (best.global_position - a.hero.global_position).normalized()
	var mid := (a.hero.global_position + best.global_position) / 2.0 + Vector3(0, 0.9, 0)
	a.camera.target = null   # hold the camera on the pair
	a.camera.global_position = mid + a.camera.global_transform.basis.z * a.camera.distance


## The props art pass 2 rebuilt, laid out next to Jackie.
func _line_up_props(a: Arena) -> void:
	var right := (a.camera.global_transform.basis.x * Vector3(1, 0, 1)).normalized()
	var at := a.hero.global_position
	var i := 0
	for id in [&"stool", &"bucket", &"pottery_shard", &"spirit_urn"]:
		i += 1
		var p := a.spawn_prop(id, at + right * (0.9 * i))
		p.rotation.y = 0.4
	a.camera.target = null
	a.camera.global_position = at + right * 1.6 + Vector3(0, 0.6, 0) + a.camera.global_transform.basis.z * a.camera.distance


func _save(n: String) -> void:
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join(n + ".png"))
	print("shot ", n)
