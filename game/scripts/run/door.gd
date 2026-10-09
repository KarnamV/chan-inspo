class_name RunDoor
extends Area3D
## Exit door shown after a room is cleared. Displays its reward; walking into it takes it.

signal taken(option: Dictionary)

const ICONS := {&"talisman": "icon_door_talisman", &"boon": "icon_door_boon", &"draft": "icon_door_draft",
	&"gold": "icon_door_gold", &"shop": "icon_door_shop", &"shrine": "icon_boon_hearty_heal",
	&"vault": "icon_door_talisman", &"story": "icon_door_boon", &"boss": "icon_door_shop"}

var option: Dictionary
var _taken := false


func setup(opt: Dictionary) -> void:
	option = opt


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 1   # player bodies
	monitoring = true
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 2.5, 1.2)
	cs.shape = box
	cs.position.y = 1.25
	add_child(cs)
	var gate_path := "res://assets/decors/market_gate.glb"
	if not ResourceLoader.exists(gate_path):
		gate_path = "res://assets/decors/room_door.glb"
	if ResourceLoader.exists(gate_path):
		var g: Node3D = load(gate_path).instantiate()
		g.scale = Vector3.ONE * (0.75 if gate_path.ends_with("market_gate.glb") else 1.0)
		add_child(g)
	var lbl := Label3D.new()
	lbl.text = String(option.get("label", ""))
	lbl.position = Vector3(0, 3.4, 0.4)
	lbl.font_size = 64
	lbl.outline_size = 12
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(lbl)
	var icon_name: String = ICONS.get(option.get("reward", &""), "")
	var path := "res://assets/icons/%s.png" % icon_name
	if icon_name != "" and ResourceLoader.exists(path):
		var spr := Sprite3D.new()
		spr.texture = load(path)
		spr.pixel_size = 0.0011
		spr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		spr.position = Vector3(0, 2.4, 0.5)
		add_child(spr)
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.75, 0.35)
	light.light_energy = 2.0
	light.omni_range = 4.0
	light.position = Vector3(0, 2.0, 1.0)
	add_child(light)
	body_entered.connect(_on_body)


func _on_body(b: Node) -> void:
	var f := b as Fighter
	if _taken or f == null or f.team != Fighter.Team.PLAYER or f.brain == null:
		return
	if f.brain is AllyBrain:
		return
	_taken = true
	taken.emit(option)
