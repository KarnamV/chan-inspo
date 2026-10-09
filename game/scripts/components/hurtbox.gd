class_name Hurtbox
extends Area3D
## The part of a fighter that can be hit. Forwards hits to its owner's `receive_hit`.

var team := 0
var owner_fighter: Node = null


func setup(p_owner: Node, p_team: int, shape: Shape3D, offset: Vector3) -> void:
	owner_fighter = p_owner
	team = p_team
	collision_layer = 1 << 5   # hurtbox layer (6)
	collision_mask = 0
	monitoring = false
	monitorable = true
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = offset
	add_child(cs)


func receive(info: DamageInfo) -> float:
	if owner_fighter and owner_fighter.has_method("receive_hit"):
		return owner_fighter.receive_hit(info)
	return 0.0
