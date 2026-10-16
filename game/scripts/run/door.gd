class_name RunDoor
extends Area3D
## Exit door: a lacquered double door built in code (the generated gate meshes can't animate).
## Stands sealed against the back wall from the start of the room; `unlock` shows its reward;
## walking up swings the leaves out toward you onto a glowing doorway; walking into it takes it.
## Flush with the wall on purpose: an inward swing needed a gap behind, and bodies got wedged there.

signal taken(option: Dictionary)

const ICONS := {&"talisman": "icon_door_talisman", &"boon": "icon_door_boon", &"draft": "icon_door_draft",
	&"gold": "icon_door_gold", &"shop": "icon_door_shop", &"shrine": "icon_boon_hearty_heal",
	&"vault": "icon_door_talisman", &"story": "icon_door_boon", &"boss": "icon_door_shop"}
const WIDTH := 2.2        # doorway, between the pillars
const HEIGHT := 2.8
const OPEN_RANGE := 3.4   # the leaves swing open when the hero is this close
const OPEN_ANGLE := 1.6   # radians each leaf swings out toward the room
const SEAL_LOCKED := Color(1.0, 0.18, 0.1)
const SEAL_OPEN := Color(1.0, 0.72, 0.3)

var option: Dictionary
var unlocked := false
var opened := false
var _taken := false
var _leaves: Array[Node3D] = []
var _seal: OmniLight3D
var _glow: OmniLight3D
var _portal: StandardMaterial3D
var _seal_mats: Array[StandardMaterial3D] = []


func setup(opt: Dictionary) -> void:
	option = opt


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1   # player bodies
	monitoring = true
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(WIDTH + 1.6, 2.5, 1.4)   # covers the pillars and reaches out in front: touching the frame takes it
	cs.shape = box
	cs.position = Vector3(0, 1.25, 0.45)
	add_child(cs)
	_build_frame()
	_build_leaves()
	body_entered.connect(_on_body)


## Seals the reward in: label + icon appear, the seal turns warm, the door can be opened.
func unlock() -> void:
	if unlocked:
		return
	unlocked = true
	var lbl := Label3D.new()
	lbl.text = String(option.get("label", ""))
	lbl.position = Vector3(0, HEIGHT + 1.35, 0.4)
	lbl.font_size = 64
	lbl.outline_size = 12
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(lbl)
	_pop_in(lbl)
	var icon_name: String = ICONS.get(option.get("reward", &""), "")
	var path := "res://assets/icons/%s.png" % icon_name
	if icon_name != "" and ResourceLoader.exists(path):
		var spr := Sprite3D.new()
		spr.texture = load(path)
		spr.pixel_size = 0.0011
		spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		spr.position = Vector3(0, HEIGHT + 0.55, 0.5)
		add_child(spr)
		_pop_in(spr)
	var tw := create_tween().set_parallel()
	tw.tween_property(_seal, "light_color", SEAL_OPEN, 0.5)
	tw.tween_property(_seal, "light_energy", 2.2, 0.5)
	for m in _seal_mats:
		tw.tween_property(m, "emission", SEAL_OPEN, 0.5)


func _pop_in(n: Node3D) -> void:
	n.scale = Vector3.ONE * 0.01
	create_tween().tween_property(n, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func open() -> void:
	if opened or not unlocked:
		return
	opened = true
	var tw := create_tween().set_parallel()
	for i in _leaves.size():
		var to := -OPEN_ANGLE if i == 0 else OPEN_ANGLE
		tw.tween_property(_leaves[i], "rotation:y", to, 0.75).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_glow, "light_energy", 4.0, 0.6)
	tw.tween_property(_portal, "emission_energy_multiplier", 2.2, 0.6)
	Vfx.dust(global_position + Vector3(0, 0, 0.3))
	Juice.shake(0.08)


func _physics_process(_delta: float) -> void:
	if not unlocked or _taken:
		return
	for body in get_overlapping_bodies():   # already standing in the doorway when it unlocked
		_on_body(body)
	if opened:
		return
	for n in get_tree().get_nodes_in_group(&"fighters"):
		var f := n as Fighter
		if f and f.team == Fighter.Team.PLAYER and not f.is_dead() and not (f.brain is AllyBrain) \
				and f.global_position.distance_to(global_position) < OPEN_RANGE:
			open()
			return


func _on_body(b: Node) -> void:
	var f := b as Fighter
	if _taken or not unlocked or f == null or f.team != Fighter.Team.PLAYER or f.brain == null:
		return
	if f.brain is AllyBrain:
		return
	open()
	_taken = true
	taken.emit(option)


# ---------------------------------------------------------------- build
static var _mats := {}


static func _mat(key: String, color: Color, rough := 0.6, metal := 0.0) -> StandardMaterial3D:
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = rough
		m.metallic = metal
		_mats[key] = m
	return _mats[key]


func _box(size: Vector3, pos: Vector3, mat: Material, parent: Node3D = self) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _build_frame() -> void:
	var wood := _mat("wood", Color(0.22, 0.1, 0.08), 0.85)
	var lacquer := _mat("lacquer", Color(0.6, 0.07, 0.05), 0.35)
	var gold := _mat("gold", Color(0.95, 0.68, 0.25), 0.3, 0.8)
	var roof := _mat("roof", Color(0.13, 0.12, 0.15), 0.7)
	var px := WIDTH / 2 + 0.2
	var solid := StaticBody3D.new()
	solid.collision_layer = 1
	add_child(solid)
	for s in [-1.0, 1.0]:
		_box(Vector3(0.4, HEIGHT + 0.5, 0.4), Vector3(s * px, (HEIGHT + 0.5) / 2, 0), lacquer)
		var pcs := CollisionShape3D.new()
		var pb := BoxShape3D.new()
		pb.size = Vector3(0.4, HEIGHT + 0.5, 0.4)
		pcs.shape = pb
		pcs.position = Vector3(s * px, (HEIGHT + 0.5) / 2, 0)
		solid.add_child(pcs)
		_box(Vector3(0.5, 0.25, 0.5), Vector3(s * px, 0.125, 0), wood)   # plinth
	_box(Vector3(WIDTH + 1.1, 0.35, 0.5), Vector3(0, HEIGHT + 0.25, 0), lacquer)   # lintel
	_box(Vector3(WIDTH + 0.6, 0.08, 0.52), Vector3(0, HEIGHT + 0.02, 0), gold)
	var top := MeshInstance3D.new()
	var pr := PrismMesh.new()
	pr.size = Vector3(WIDTH + 1.8, 0.55, 0.95)
	top.mesh = pr
	top.material_override = roof
	top.position = Vector3(0, HEIGHT + 0.7, 0)
	add_child(top)
	_box(Vector3(WIDTH + 0.4, 0.12, 0.6), Vector3(0, 0.06, -0.15), wood)   # threshold
	# the doorway behind the leaves: dark red glow, brighter once opened
	_portal = StandardMaterial3D.new()
	_portal.albedo_color = Color(0.05, 0.01, 0.01)
	_portal.emission_enabled = true
	_portal.emission = Color(0.9, 0.3, 0.1)
	_portal.emission_energy_multiplier = 0.25
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(WIDTH, HEIGHT)
	q.mesh = qm
	q.material_override = _portal
	q.position = Vector3(0, HEIGHT / 2, -0.22)   # just in front of the wall behind
	add_child(q)
	_glow = OmniLight3D.new()
	_glow.light_color = Color(1.0, 0.55, 0.25)
	_glow.light_energy = 0.0
	_glow.omni_range = 5.0
	_glow.position = Vector3(0, 1.4, 0.3)
	add_child(_glow)
	_seal = OmniLight3D.new()
	_seal.light_color = SEAL_LOCKED
	_seal.light_energy = 0.8
	_seal.omni_range = 3.0
	_seal.position = Vector3(0, 1.6, 0.8)
	add_child(_seal)
	_box(Vector3(0.5, 0.4, 0.06), Vector3(0, HEIGHT + 0.25, 0.27), gold)   # name plaque


func _build_leaves() -> void:
	var lacquer := _mat("leaf", Color(0.5, 0.05, 0.04), 0.4)
	var gold := _mat("gold", Color(0.95, 0.68, 0.25), 0.3, 0.8)
	var leaf_w := WIDTH / 2
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var hinge := Node3D.new()
		hinge.position = Vector3(side * WIDTH / 2, 0, 0)
		add_child(hinge)
		_leaves.append(hinge)
		var cx := -side * leaf_w / 2   # leaf extends from the hinge toward the middle
		_box(Vector3(leaf_w - 0.02, HEIGHT - 0.1, 0.12), Vector3(cx, HEIGHT / 2, 0), lacquer, hinge)
		_box(Vector3(leaf_w - 0.02, 0.1, 0.14), Vector3(cx, HEIGHT * 0.33, 0), gold, hinge)   # bands
		_box(Vector3(leaf_w - 0.02, 0.1, 0.14), Vector3(cx, HEIGHT * 0.75, 0), gold, hinge)
		var stud := SphereMesh.new()
		stud.radius = 0.045
		stud.height = 0.09
		for r in 4:
			for c in 3:
				var s := MeshInstance3D.new()
				s.mesh = stud
				s.material_override = gold
				s.position = Vector3(cx + (c - 1) * leaf_w * 0.28, 0.45 + r * 0.6, 0.07)
				hinge.add_child(s)
		# half of the talisman seal on each leaf, glowing red while locked
		var seal := StandardMaterial3D.new()
		seal.albedo_color = Color(0.95, 0.85, 0.6)
		seal.emission_enabled = true
		seal.emission = SEAL_LOCKED
		seal.emission_energy_multiplier = 1.4
		_seal_mats.append(seal)
		_box(Vector3(0.22, 0.75, 0.02), Vector3(-side * (leaf_w - 0.13), 1.5, 0.075), seal, hinge)
		var ring := MeshInstance3D.new()
		var tm := TorusMesh.new()
		tm.inner_radius = 0.06
		tm.outer_radius = 0.1
		ring.mesh = tm
		ring.material_override = gold
		ring.rotation.x = PI / 2
		ring.position = Vector3(-side * (leaf_w - 0.32), 1.25, 0.09)
		hinge.add_child(ring)
