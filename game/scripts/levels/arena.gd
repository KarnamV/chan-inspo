class_name Arena
extends Node3D
## M1 prototype room, built in code: shader floor + walls, street outside, decor, Jackie, props, brutes.
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
const FLOOR_SHADER := "res://assets/shaders/flagstone.gdshader"
const WALL_SHADER := "res://assets/shaders/lacquer_wall.gdshader"
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
	Events.damage_dealt.connect(_on_damage_vfx)
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
	_prewarm()


## Draws every first-use material once, out of sight under the floor, so the first hit, the first
## hurt demon and later waves' demon types don't stall the frame compiling shaders mid-fight.
func _prewarm() -> void:
	var warm := Node3D.new()
	warm.position = hero_spawn + Vector3(0, -4.0, 0)
	add_child(warm)
	var flash := Fighter.flash_material()
	for f in ResourceLoader.list_directory("res://data/fighters"):   # export-safe (sees remapped .tres)
		if not f.ends_with(".tres"):
			continue
		var d := load("res://data/fighters/" + f) as FighterData
		if d == null or d.model == null:
			continue
		var m: Node3D = d.model.instantiate()
		warm.add_child(m)
		for mi in m.find_children("*", "MeshInstance3D", true, false):
			(mi as MeshInstance3D).material_overlay = flash
	var bar := MeshInstance3D.new()
	bar.mesh = QuadMesh.new()
	bar.material_override = Fighter.hp_material()
	warm.add_child(bar)
	var trail := MeshInstance3D.new()
	trail.mesh = QuadMesh.new()
	trail.material_override = SwingTrail.material()
	warm.add_child(trail)
	for kind in [[DamageInfo.Type.PHYSICAL, &""], [DamageInfo.Type.MAGIC, &""], [DamageInfo.Type.PHYSICAL, &"fire"]]:
		var info := DamageInfo.make(1.0, null, kind[0])
		info.element = kind[1]
		Vfx.hit(warm, info)
	Vfx.dust(warm.global_position)
	get_tree().create_timer(0.4).timeout.connect(warm.queue_free)


func _on_damage_vfx(target: Node, info: DamageInfo, amount: float) -> void:
	if amount > 0.0 and target is Node3D and is_instance_valid(target):
		Vfx.hit(target, info)


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
	f.dodged.connect(func() -> void: Vfx.dust(f.global_position))
	f.knocked_down.connect(func() -> void: Vfx.dust(f.global_position, true))
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
	env.background_color = Color(0.035, 0.02, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.32, 0.42)
	env.ambient_light_energy = 0.75
	env.tonemap_mode = Environment.TONE_MAPPER_AGX
	env.tonemap_exposure = 1.1
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.04
	env.glow_hdr_threshold = 1.1
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 2.2
	env.fog_enabled = true   # fades the street outside into night
	env.fog_light_color = Color(0.16, 0.06, 0.07)
	env.fog_density = 0.012
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.06
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var moon := DirectionalLight3D.new()   # cool key light: lanterns supply the warm colour
	moon.rotation_degrees = Vector3(-58, 30, 0)
	moon.light_energy = 0.9
	moon.light_color = Color(0.72, 0.78, 1.0)
	moon.shadow_enabled = true
	moon.shadow_blur = 1.5
	moon.directional_shadow_max_distance = 60.0
	add_child(moon)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0, 4, -room_size / 2 + 1.0)
	glow.light_color = Color(1.0, 0.35, 0.18)
	glow.light_energy = 3.0
	glow.omni_range = room_size * 0.8
	add_child(glow)


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


func _shader_mat(path: String, params := {}) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load(path)
	for k in params:
		m.set_shader_parameter(k, params[k])
	return m


func _build_room() -> void:
	var floor_mat := _shader_mat(FLOOR_SHADER)
	_static_box(Vector3(room_size, 0.2, room_size), Vector3(0, -0.1, 0), floor_mat)
	_build_street()
	var wall_mat := _shader_mat(WALL_SHADER)
	var h := 2.4
	var low := 0.6   # camera-side walls stay low so they never hide the fight
	_static_box(Vector3(room_size, h, 0.4), Vector3(0, h / 2, -room_size / 2), wall_mat)
	_static_box(Vector3(0.4, h, room_size), Vector3(-room_size / 2, h / 2, 0), wall_mat)
	_static_box(Vector3(room_size, low, 0.4), Vector3(0, low / 2, room_size / 2), wall_mat)
	_static_box(Vector3(0.4, low, room_size), Vector3(room_size / 2, low / 2, 0), wall_mat)


## Outside the walls: a dark street that fades into fog, and shop-house silhouettes with lit
## windows behind the two far walls, so the room sits in a night market instead of a black void.
func _build_street() -> void:
	var street := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(160, 160)
	street.mesh = pm
	street.material_override = _shader_mat(FLOOR_SHADER, {"dim": 0.45, "tile": 1.6})
	street.position = Vector3(0, -0.03, 0)
	add_child(street)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(room_size * 13.0)
	var h := room_size / 2
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.3, 0.14, 0.11)
	wood.roughness = 0.9
	var roof := StandardMaterial3D.new()
	roof.albedo_color = Color(0.16, 0.14, 0.17)
	roof.roughness = 0.7
	var lit := StandardMaterial3D.new()
	lit.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lit.albedo_color = Color(0.85, 0.5, 0.25)
	# rows behind the far (-Z) and left (-X) walls; the camera-side walls stay open
	for side in 2:
		var along := -h - 2.0
		while along < h + 6.0:
			var w := rng.randf_range(3.2, 5.5)
			var tall := rng.randf_range(4.5, 9.0)
			var depth := rng.randf_range(4.0, 6.0)
			var off := h + 1.4 + depth / 2 + rng.randf_range(0.0, 1.2)
			var c := Vector3(along + w / 2, 0, -off) if side == 0 else Vector3(-off, 0, along + w / 2)
			var size := Vector3(w - 0.3, tall, depth) if side == 0 else Vector3(depth, tall, w - 0.3)
			var body := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = size
			body.mesh = bm
			body.material_override = wood
			body.position = c + Vector3(0, tall / 2, 0)
			add_child(body)
			var top := MeshInstance3D.new()
			var pr := PrismMesh.new()
			pr.size = Vector3(size.x + 0.8, 1.4, size.z + 0.8)
			top.mesh = pr
			top.material_override = roof
			top.position = c + Vector3(0, tall + 0.7, 0)
			if side == 1:
				top.rotation.y = PI / 2
				pr.size = Vector3(size.z + 0.8, 1.4, size.x + 0.8)
			add_child(top)
			# lit windows on the face toward the room
			var face := (Vector3(0, 0, size.z / 2 + 0.02) if side == 0 else Vector3(size.x / 2 + 0.02, 0, 0))
			for row in int(tall / 2.4):
				if rng.randf() < 0.35:
					continue
				var win := MeshInstance3D.new()
				var q := QuadMesh.new()
				q.size = Vector2(rng.randf_range(0.6, 1.0), 0.7)
				win.mesh = q
				win.material_override = lit
				win.position = c + face + Vector3(0, 2.6 + row * 2.4, 0)
				win.rotation.y = 0.0 if side == 0 else PI / 2
				add_child(win)
			if rng.randf() < 0.5:
				var l := OmniLight3D.new()
				l.light_color = Color(1.0, 0.45, 0.2)
				l.light_energy = 1.4
				l.omni_range = 6.0
				l.position = c + face * 1.4 + Vector3(0, 3.0, 0)
				add_child(l)
			along += w
	Vfx.embers(self, h)


func decor(path: String, at: Vector3, yaw := 0.0, scale_to := 0.0) -> Node3D:
	if not ResourceLoader.exists(path):
		return null
	var d: Node3D = load(path).instantiate()
	d.position = at
	d.rotation.y = yaw
	add_child(d)
	return d
