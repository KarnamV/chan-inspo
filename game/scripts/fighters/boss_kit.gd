class_name BossKit
extends RefCounted
## Boss signature moves. The same functions serve the boss AI and the player's Monkey form, so
## "your attack set fully changes to the boss" is literally the boss's own kit.
## Monkey-form buttons: light = melee combo, heavy = signature heavy, grab = signature grab,
## chi_mod + light/heavy = ranged / special.


static func special(f: Fighter, slot: int) -> bool:
	match f.data.kit:
		&"butcher":
			match slot:
				0: return cleaver_throw(f)
				1: return ground_pound(f)
				2: return meat_hook(f, 8.0)
	return false


## grab button for a kit fighter (Monkey form / boss AI)
static func grab(f: Fighter) -> bool:
	match f.data.kit:
		&"butcher": return meat_hook(f, 8.0)
	return false


# ---------------------------------------------------------------- Butcher King
static func cleaver_throw(f: Fighter) -> bool:
	if not f.can_act():
		return false
	var info := DamageInfo.make(12.0, f)
	info.stun = 0.4
	var from := f.global_position + Vector3(0, 1.6, 0) + f.facing * 0.9
	var p := Projectile.fire(f.get_tree().get_first_node_in_group(&"level_root"), from, f.facing, 13.0, info, f.team)
	p.boomerang_to = f
	p.pierce = true
	p.life = 3.0
	p.scale = Vector3.ONE * 2.2
	f.anim.play(&"throw", 0.06, 0.45)
	f.attack_started.emit(null)
	return true


static func ground_pound(f: Fighter) -> bool:
	var a := AttackData.new()
	a.id = &"ground_pound"
	a.clip = &"heavy"
	a.duration = 1.0
	a.active_start = 0.55
	a.active_end = 0.68
	a.damage = 18.0
	a.knockback = 8.0
	a.knockdown = true
	a.lunge = 0.0
	a.hit_size = Vector3(6.0, 1.4, 6.0)
	a.hit_offset = Vector3(0, 0.6, 0)
	if not f.can_act():
		return false
	f.request_attack(a)
	f.get_tree().create_timer(0.55, false).timeout.connect(func() -> void:
		if is_instance_valid(f):
			Juice.shake(0.35)
			Shockwave.spawn(f, 3.0))
	return true


static func meat_hook(f: Fighter, reach: float) -> bool:
	if not f.can_act():
		return false
	var target: Fighter = null
	var best := reach
	for n in f.get_tree().get_nodes_in_group(&"fighters"):
		var o := n as Fighter
		if o == null or o.team == f.team or o.is_dead() or o.state == Fighter.State.BODY:
			continue
		var to := o.global_position - f.global_position
		var d := to.length()
		if d < best and f.facing.dot(to.normalized()) > 0.3:
			best = d
			target = o
	f.anim.play(&"punch_cross", 0.06, 0.5)
	f.attack_started.emit(null)
	if target == null:
		return true   # whiffed hook still costs the move
	var info := DamageInfo.make(8.0, f)
	info.knockback = (f.global_position - target.global_position).normalized() * (best * 1.6 + 4.0) + Vector3.UP * 1.5
	info.stun = 0.8
	target.receive_hit(info)
	return true


class Shockwave:
	extends MeshInstance3D
	var t := 0.0
	var radius := 3.0

	static func spawn(f: Fighter, r: float) -> void:
		var s := Shockwave.new()
		s.radius = r
		var m := TorusMesh.new()
		m.inner_radius = 0.85
		m.outer_radius = 1.0
		s.mesh = m
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color = Color(1.0, 0.6, 0.3, 0.8)
		s.material_override = mat
		s.position = f.global_position + Vector3(0, 0.1, 0)
		f.get_tree().get_first_node_in_group(&"level_root").add_child(s)

	func _process(delta: float) -> void:
		t += delta
		var k := t / 0.35
		scale = Vector3.ONE * lerpf(0.3, radius, k)
		(material_override as StandardMaterial3D).albedo_color.a = 0.8 * (1.0 - k)
		if k >= 1.0:
			queue_free()
