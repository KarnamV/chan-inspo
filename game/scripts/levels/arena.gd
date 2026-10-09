class_name Arena
extends Node3D
## M1 prototype room, built in code: textured floor + walls, decor, Jackie, props, brutes.
## When every demon is down the wave respawns (props too) so the loop can be played repeatedly.
## R = reset the room.

var HERO: FighterData
const PRESETS := {
	"m1": {
		"props": [[&"chair", Vector3(-3, 0, 2)], [&"chair", Vector3(4, 0, -1)], [&"bench", Vector3(-4, 0, -3)],
			[&"crate", Vector3(2, 0, 4)], [&"crate", Vector3(5, 0, 3)], [&"barrel", Vector3(-5, 0, 4)],
			[&"barrel", Vector3(0, 0, -5)], [&"pole", Vector3(3, 0, -4)]],
		"waves": [[&"brute", &"brute"]],
		"fixed": [],
	},
	"m2": {
		"props": [[&"chair", Vector3(-3, 0, 2)], [&"bench", Vector3(-4, 0, -3)], [&"crate", Vector3(2, 0, 4)],
			[&"barrel", Vector3(-5, 0, 4)], [&"pole", Vector3(3, 0, -4)], [&"lantern", Vector3(4, 0, 1)],
			[&"bucket", Vector3(-1, 0, 5)], [&"spirit_urn", Vector3(6, 0, -2)], [&"stool", Vector3(-6, 0, 0)],
			[&"spear", Vector3(1, 0, -2)], [&"bun_basket", Vector3(-2, 0, -1)], [&"roast_duck", Vector3(5, 0, 5)]],
		"waves": [[&"brute", &"shield_demon"], [&"thief_imp", &"archer_demon", &"wraith"],
			[&"armored_ghoul", &"shield_demon", &"thief_imp", &"archer_demon", &"wraith", &"brute"]],
		"fixed": [[&"hanging_lantern", Vector3(-3, 2.6, -2)], [&"hanging_lantern", Vector3(3, 2.6, 2)],
			[&"weapon_rack", Vector3(-7.6, 0, -5)]],
	},
}
const ENEMY_SPAWNS := [Vector3(-2, 0, -6), Vector3(3, 0, -6), Vector3(-6, 0, -4), Vector3(6, 0, -4),
	Vector3(0, 0, -7), Vector3(-5, 0, -7)]

@export var preset := "m1"
@export var room_size := 18.0
@export var floor_tex := "res://assets/textures/floor_test.png"
@export var wall_tex := "res://assets/textures/wall_test.png"
@export var hero_spawn := Vector3(0, 0, 4)
@export var talismans: Array[StringName] = [&"sheep", &"tiger", &"rat"]
@export var spawn_enemies := true
@export var with_hud := true

var hero: Fighter
var controller: PlayerController
var camera: IsoCamera
var wave := 0
var _respawn_t := -1.0


func _ready() -> void:
	add_to_group(&"level_root")
	HERO = load("res://data/fighters/hero.tres")
	_configure()
	_build_environment()
	_build_room()
	_decorate()
	camera = IsoCamera.new()
	add_child(camera)
	camera.make_current()
	Juice.camera = camera
	hero = spawn_fighter(HERO, Fighter.Team.PLAYER, hero_spawn)
	controller = PlayerController.new()
	add_child(controller)
	controller.setup(hero, camera)
	controller.equip(talismans)
	camera.snap()
	if with_hud:
		var hud := Hud.new()
		add_child(hud)
		hud.bind(controller)
	_populate()


## Override points for themed rooms (RunRoom).
func _configure() -> void:
	pass


func _decorate() -> void:
	for c in [Vector3(-room_size / 2 + 0.6, 0, -room_size / 2 + 0.6), Vector3(room_size / 2 - 0.6, 0, -room_size / 2 + 0.6)]:
		decor("res://assets/decors/pillar.glb", c)
	decor("res://assets/decors/room_door.glb", Vector3(0, 0, -room_size / 2 + 0.4))


func _populate() -> void:
	reset_props()
	if spawn_enemies:
		spawn_wave()


func spawn_fighter(d: FighterData, team: Fighter.Team, at: Vector3) -> Fighter:
	var f := Fighter.new()
	f.data = d
	f.team = team
	f.position = at   # before add_child: spawning at the origin first makes bodies overlap and pop
	add_child(f)
	if team == Fighter.Team.ENEMY:
		f.set_brain(AIBrain.new())
		f.facing = (Vector3(0, 0, 4) - at).normalized()
	return f


func spawn_wave() -> void:
	wave += 1
	var waves: Array = PRESETS[preset]["waves"]
	var list: Array = waves[(wave - 1) % waves.size()]
	for i in list.size():
		var d: FighterData = load("res://data/fighters/%s.tres" % list[i])
		spawn_fighter(d, Fighter.Team.ENEMY, ENEMY_SPAWNS[i % ENEMY_SPAWNS.size()])


func spawn_prop(id: StringName, at: Vector3) -> Prop:
	var p := Prop.new()
	p.data = load("res://data/props/%s.tres" % id)
	p.position = at + Vector3.UP * 0.05
	add_child(p)
	p.rotation.y = randf() * TAU
	return p


func reset_props() -> void:
	for n in get_tree().get_nodes_in_group(&"props"):
		if (n as Prop).mode != Prop.Mode.HELD:
			n.queue_free()
	for e in PRESETS[preset]["props"]:
		spawn_prop(e[0], e[1])
	for n in get_tree().get_nodes_in_group(&"fixed_props"):
		n.queue_free()
	for e in PRESETS[preset]["fixed"]:
		spawn_fixed(e[0], e[1])


func spawn_fixed(id: StringName, at: Vector3) -> FixedProp:
	var fp := FixedProp.new()
	if id == &"hanging_lantern":
		fp.kind = FixedProp.Kind.HANGING_LANTERN
		fp.drop_data = load("res://data/props/lantern.tres")
	else:
		fp.kind = FixedProp.Kind.WEAPON_RACK
		fp.drop_data = load("res://data/props/spear.tres")
	fp.position = at
	add_child(fp)
	return fp


func living_enemies() -> int:
	var c := 0
	for n in get_tree().get_nodes_in_group(&"fighters"):
		var f := n as Fighter
		if f and not f.is_dead() and f.team == Fighter.Team.ENEMY:
			c += 1
	return c


## Test keys: 1-9, 0, -, = put talisman #1..#12 (Zodiac.ALL order) into the next slot.
var _next_slot := 0


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k == null or not k.pressed or k.echo:
		return
	var keys := [KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9, KEY_0, KEY_MINUS, KEY_EQUAL]
	var i := keys.find(k.physical_keycode)
	if i < 0:
		return
	var ids: Array = controller.equipped.map(func(t: Talisman) -> StringName: return t.id)
	var id: StringName = Zodiac.ALL[i]
	if id in ids:
		return
	while ids.size() < 3:
		ids.append(&"")
	ids[_next_slot] = id
	_next_slot = (_next_slot + 1) % 3
	controller.equip(ids.filter(func(x: StringName) -> bool: return x != &""))


func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_R) and _respawn_t < 0.0:
		get_tree().reload_current_scene()
		return
	if not spawn_enemies:
		return
	if living_enemies() == 0 and controller.host == null:
		if _respawn_t < 0.0:
			_respawn_t = 3.0
			Events.room_cleared.emit(self)
		_respawn_t -= delta
		if _respawn_t <= 0.0:
			_respawn_t = -1.0
			for n in get_tree().get_nodes_in_group(&"fighters"):
				if (n as Fighter).is_dead() and n != hero:
					n.queue_free()
			reset_props()
			spawn_wave()
	if hero.is_dead() and _respawn_t < 0.0:
		_respawn_t = 3.0
	if hero.is_dead():
		_respawn_t -= delta
		if _respawn_t <= 0.0:
			get_tree().reload_current_scene()


# ---------------- build ----------------
func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.06, 0.04, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.45, 0.5)
	env.ambient_light_energy = 0.9
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 1.3
	sun.light_color = Color(1.0, 0.9, 0.85)
	sun.shadow_enabled = true
	add_child(sun)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 4, -8)
	glow.light_color = Color(1.0, 0.25, 0.15)
	glow.light_energy = 3.0
	glow.omni_range = 12.0
	add_child(glow)


func _textured(path: String, uv: Vector3) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if ResourceLoader.exists(path):
		m.albedo_texture = load(path)
	m.uv1_scale = uv
	m.roughness = 0.9
	return m


func _static_box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	cs.shape = shape
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	body.add_child(mi)
	add_child(body)
	body.position = pos


func _build_room() -> void:
	var floor_mat := _textured(floor_tex, Vector3(room_size / 3.0, room_size / 3.0, 1))
	_static_box(Vector3(room_size, 0.2, room_size), Vector3(0, -0.1, 0), floor_mat)
	var wall_mat := _textured(wall_tex, Vector3(room_size / 3.0, 1, 1))
	var h := 2.4
	var low := 0.6   # camera-side walls stay low so they never hide the fight
	_static_box(Vector3(room_size, h, 0.4), Vector3(0, h / 2, -room_size / 2), wall_mat)
	_static_box(Vector3(0.4, h, room_size), Vector3(-room_size / 2, h / 2, 0), wall_mat)
	_static_box(Vector3(room_size, low, 0.4), Vector3(0, low / 2, room_size / 2), wall_mat)
	_static_box(Vector3(0.4, low, room_size), Vector3(room_size / 2, low / 2, 0), wall_mat)


func decor(path: String, at: Vector3, yaw := 0.0, scale_to := 0.0) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var d: Node3D = load(path).instantiate()
	d.position = at
	d.rotation.y = yaw
	add_child(d)
	return d
