class_name Hitbox
extends Area3D
## Damage volume for one attack. While active it hits each enemy hurtbox at most once per swing.
## Polls overlaps every physics frame (robust for targets already inside when it switches on).

signal landed(hurtbox: Hurtbox, info: DamageInfo, amount: float)

var team := 0
var active := false
var template: DamageInfo
var _hit: Array[Hurtbox] = []
var _shape := CollisionShape3D.new()


func _init() -> void:
	collision_layer = 0
	collision_mask = 1 << 5   # sees hurtboxes
	monitorable = false
	monitoring = true
	_shape.shape = BoxShape3D.new()
	_shape.disabled = true
	add_child(_shape)


func activate(info: DamageInfo, size: Vector3, offset: Vector3) -> void:
	template = info
	(_shape.shape as BoxShape3D).size = size
	_shape.position = offset
	_shape.disabled = false
	_hit.clear()
	active = true


func deactivate() -> void:
	active = false
	_shape.disabled = true


func _physics_process(_delta: float) -> void:
	if not active:
		return
	for area in get_overlapping_areas():
		var hb := area as Hurtbox
		if hb == null or hb.team == team or hb in _hit:
			continue
		if hb.owner_fighter == template.source:
			continue
		_hit.append(hb)
		var info := _copy(template)
		var amount := hb.receive(info)
		landed.emit(hb, info, amount)


static func _copy(t: DamageInfo) -> DamageInfo:
	var d := DamageInfo.make(t.amount, t.source, t.type)
	d.knockback = t.knockback
	d.knockdown = t.knockdown
	d.stun = t.stun
	d.shatter = t.shatter
	d.element = t.element
	return d
