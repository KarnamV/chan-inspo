class_name FixedProp
extends StaticBody3D
## Room fixtures that react to hits.
##  HANGING_LANTERN: hit it and the lantern drops, bursting into fire where it lands.
##  WEAPON_RACK: hit it (or grab next to it) and it hands out a spear, up to `stock` times.

enum Kind { HANGING_LANTERN, WEAPON_RACK }

const NEUTRAL_TEAM := 2

@export var kind: Kind = Kind.HANGING_LANTERN
@export var drop_data: PropData        ## lantern / spear prop that gets released
@export var stock := 3

var hurtbox: Hurtbox
var _visual: Node3D
var _used := false


func _ready() -> void:
	add_to_group(&"fixed_props")
	collision_layer = 1
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 0.8, 0.6) if kind == Kind.HANGING_LANTERN else Vector3(1.6, 1.6, 0.5)
	cs.shape = box
	cs.position.y = 0.4 if kind == Kind.HANGING_LANTERN else 0.8
	if kind == Kind.WEAPON_RACK:
		add_child(cs)   # lanterns hang overhead: no body collision
	hurtbox = Hurtbox.new()
	hurtbox.setup(self, NEUTRAL_TEAM, box.duplicate(), cs.position)
	add_child(hurtbox)
	if drop_data and drop_data.model:
		_visual = drop_data.model.instantiate()
		add_child(_visual)
	if kind == Kind.HANGING_LANTERN:
		var cord := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.015
		cm.bottom_radius = 0.015
		cm.height = 3.0
		cord.mesh = cm
		cord.position.y = 1.5 + 0.5
		add_child(cord)
		var light := OmniLight3D.new()
		light.light_color = Color(1.0, 0.55, 0.25)
		light.light_energy = 1.5
		light.omni_range = 4.0
		light.position.y = 0.3
		add_child(light)


func receive_hit(info: DamageInfo) -> float:
	match kind:
		Kind.HANGING_LANTERN:
			if _used:
				return 0.0
			_used = true
			var p := _release_prop()
			p.fire_burst = true
			queue_free()
		Kind.WEAPON_RACK:
			give_to(info.source as Fighter)
	return 0.0


func give_to(f: Fighter) -> bool:
	if kind != Kind.WEAPON_RACK or stock <= 0:
		return false
	stock -= 1
	var p := _release_prop()
	p.global_position = global_position + Vector3(0, 1.2, 0) + (f.global_position - global_position).normalized() * 0.8 if f else global_position + Vector3(0, 1.2, 0.8)
	if f and f.held_prop == null and f.can_act():
		p.attach_to(f)
		f.held_prop = p
	return true


func _release_prop() -> Prop:
	var p := Prop.new()
	p.data = drop_data
	p.position = global_position + Vector3(0, 0.1, 0)
	var level := get_tree().get_first_node_in_group(&"level_root")
	(level if level else get_parent()).add_child(p)
	return p
