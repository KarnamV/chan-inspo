class_name Prop
extends RigidBody3D
## A breakable prop. FREE on the floor -> HELD in a fighter's hand -> swung (wears it down) or
## THROWN (damages whatever it hits). At 0 durability it degrades into `data.pieces`.

enum Mode { FREE, HELD, THROWN, BROKEN }

const LIGHT_MASS := 3.0
const HEAVY_MASS := 14.0

@export var data: PropData

var mode: Mode = Mode.FREE
var durability := 0
var thrower: Node = null
var _visual: Node3D
var _shape := CollisionShape3D.new()
var _size := Vector3.ONE * 0.5


func _ready() -> void:
	add_to_group(&"props")
	durability = data.durability
	mass = HEAVY_MASS if data.weight == PropData.Weight.HEAVY else LIGHT_MASS
	collision_layer = 1 << 3
	collision_mask = 1 | (1 << 3)          # world + other props
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = true
	body_entered.connect(_on_body_entered)
	if data.model:
		_visual = data.model.instantiate()
		add_child(_visual)
		_size = _measure(_visual)
	var box := BoxShape3D.new()
	box.size = _size
	_shape.shape = box
	_shape.position = Vector3(0, _size.y * 0.5, 0)
	add_child(_shape)


static func _measure(root: Node3D) -> Vector3:
	var aabb := AABB()
	var first := true
	for n in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var b := mi.transform * mi.get_aabb()
		aabb = b if first else aabb.merge(b)
		first = false
	return aabb.size.max(Vector3.ONE * 0.08) if not first else Vector3.ONE * 0.5


## Where loose props and pieces live: the node in group "level_root", else the current scene.
func _level() -> Node:
	var r := get_tree().get_first_node_in_group(&"level_root")
	if r:
		return r
	return get_tree().current_scene if get_tree().current_scene else get_tree().root


func can_pick_up() -> bool:
	return mode == Mode.FREE


func durability_left() -> int:
	return durability


func attach_to(f: Node3D) -> void:
	mode = Mode.HELD
	freeze = true
	collision_layer = 0
	collision_mask = 0
	var parent: Node3D = f.hand_attach if f.get("hand_attach") else f
	reparent(parent, false)
	if parent == f:
		position = Vector3(0.35, 1.0, 0.45)
		rotation = Vector3(deg_to_rad(80), 0, 0)
	else:
		position = data.grip_offset
		rotation = Vector3.ZERO


## Leaves the hand. With a thrower it becomes a damaging projectile; without one it just drops.
func release(impulse: Vector3, by: Node) -> void:
	var xf := global_transform
	reparent(_level(), false)
	global_transform = xf
	freeze = false
	collision_layer = 1 << 3
	collision_mask = 1 | (1 << 3) | (1 << 2) | (1 << 1)   # thrown props also hit fighters
	thrower = by
	mode = Mode.THROWN if by else Mode.FREE
	linear_velocity = impulse
	angular_velocity = Vector3(randf_range(-6, 6), randf_range(-3, 3), randf_range(-6, 6)) if by else Vector3.ZERO


## Uses up durability; returns true if this broke the prop.
func wear(amount: int, _by: Node = null) -> bool:
	if mode == Mode.BROKEN:
		return true
	durability -= amount
	if durability <= 0:
		shatter()
		return true
	return false


func shatter() -> void:
	if mode == Mode.BROKEN:
		return
	mode = Mode.BROKEN
	var at := global_transform
	var pieces: Array = []
	var level := _level()
	var i := 0
	for pd in data.pieces:
		var p := Prop.new()
		p.data = pd
		p.position = at.origin + Vector3(randf_range(-0.3, 0.3), 0.4 + 0.15 * i, randf_range(-0.3, 0.3))
		level.add_child(p)   # level root sits at the origin, so local == global here
		p.linear_velocity = Vector3(randf_range(-2.5, 2.5), 3.0, randf_range(-2.5, 2.5))
		p.angular_velocity = Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))
		pieces.append(p)
		i += 1
	Events.prop_broken.emit(self, pieces)
	queue_free()


func _on_body_entered(body: Node) -> void:
	if mode != Mode.THROWN:
		return
	if body == thrower:
		return
	var f := body as Fighter
	if f and not f.is_dead() and (thrower == null or f.team != thrower.team):
		var info := DamageInfo.make(data.damage * data.throw_mult, thrower)
		info.knockback = linear_velocity.normalized() * data.knockback * 1.4 + Vector3.UP * 2.0
		info.knockdown = true
		info.stun = 0.5
		info.shatter = durability <= 2
		info.element = data.element
		var amount := f.receive_hit(info)
		if thrower and thrower.has_signal("attack_landed"):
			thrower.attack_landed.emit(info, amount)
		Juice.hitstop(0.07)
		wear(2)
	else:
		wear(1)
	if mode != Mode.BROKEN:
		mode = Mode.FREE
		thrower = null
		collision_mask = 1 | (1 << 3)
