class_name Projectile
extends Area3D
## Simple straight-flying projectile (archer knife). Hits the first hurtbox of another team.

var velocity := Vector3.ZERO
var team := 1
var info: DamageInfo
var life := 2.5
var pierce := false          ## keeps flying through targets (each hit once)
var boomerang_to: Node3D     ## flies back to this node after half its life
var _hit: Array = []
var _t := 0.0
var _life0 := 0.0


static func fire(level: Node, from: Vector3, dir: Vector3, speed: float, p_info: DamageInfo, p_team: int) -> Projectile:
	var p := Projectile.new()
	p.velocity = dir.normalized() * speed
	p.info = p_info
	p.team = p_team
	p.position = from
	level.add_child(p)
	return p


func _ready() -> void:
	_life0 = life
	collision_layer = 0
	collision_mask = (1 << 5) | 1
	var cs := CollisionShape3D.new()
	var s := SphereShape3D.new()
	s.radius = 0.15
	cs.shape = s
	add_child(cs)
	var mi := MeshInstance3D.new()
	var m := CapsuleMesh.new()
	m.radius = 0.05
	m.height = 0.45
	mi.mesh = m
	mi.rotation.x = PI / 2
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.8, 0.85)
	mat.metallic = 0.8
	mi.material_override = mat
	add_child(mi)
	look_at_from_position(position, position + velocity, Vector3.UP)
	area_entered.connect(_on_area)
	body_entered.connect(_on_body)


func _physics_process(delta: float) -> void:
	_t += delta
	if boomerang_to and is_instance_valid(boomerang_to) and _t > _life0 * 0.45:
		var back := (boomerang_to.global_position + Vector3(0, 1.4, 0)) - global_position
		if back.length() < 0.8:
			queue_free()
			return
		velocity = velocity.lerp(back.normalized() * velocity.length(), clampf(6.0 * delta, 0, 1))
		if _hit.size() > 0 and _t < _life0 * 0.5:
			_hit.clear()   # can hit again on the way back
	rotation.y += 18.0 * delta if boomerang_to else 0.0
	position += velocity * delta
	life -= delta
	if life <= 0.0:
		queue_free()


func _on_area(a: Area3D) -> void:
	var hb := a as Hurtbox
	if hb == null or hb.team == team or hb in _hit:
		return
	_hit.append(hb)
	info.knockback = velocity.normalized() * 3.0
	hb.receive(info)
	if not pierce:
		queue_free()


func _on_body(b: Node) -> void:
	if b is StaticBody3D and not boomerang_to:
		queue_free()
