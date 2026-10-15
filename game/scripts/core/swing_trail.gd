class_name SwingTrail
extends MeshInstance3D
## Fading ribbon behind a swung prop, so a swing reads as an arc instead of a snap between poses.
## Samples the prop's grip and tip while `fighter` is still in the attack's strike window, then fades
## out and frees itself.

const LIFE := 0.14   ## seconds a sample stays visible

static var _mat: StandardMaterial3D
var fighter: Fighter
var prop: Prop
var attack: AttackData
var color := Color(1.0, 0.95, 0.85, 0.55)
var _base := Vector3.ZERO
var _tip := Vector3(0, 1, 0)
var _samples: Array = []   # [base, tip, time]
var _im := ImmediateMesh.new()
var _clock := 0.0   ## game time (Time.get_ticks would ignore hitstop and slow-mo)


static func follow(f: Fighter, p: Prop, a: AttackData) -> void:
	var lvl := f.get_tree().get_first_node_in_group(&"level_root")
	if lvl == null:
		return
	var t := SwingTrail.new()
	t.fighter = f
	t.prop = p
	t.attack = a
	if p.current_element() == &"fire":
		t.color = Color(1.0, 0.6, 0.2, 0.6)
	elif p.current_element() == &"magic":
		t.color = Color(0.45, 1.0, 0.8, 0.6)
	lvl.add_child(t)


static func material() -> StandardMaterial3D:
	if _mat == null:
		_mat = StandardMaterial3D.new()
		_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_mat.vertex_color_use_as_albedo = true
	return _mat


func _ready() -> void:
	top_level = true
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	layers = 2
	mesh = _im
	material_override = material()
	if is_instance_valid(prop):   # along the long side, from mid-handle out past the far end
		var b := prop.local_aabb()
		var ax := prop.long_axis()
		var half := b.size.dot(ax.abs()) * 0.5
		_base = b.get_center() - ax * half * 0.2
		_tip = b.get_center() + ax * half * 1.1


func _process(delta: float) -> void:
	_clock += delta
	var now := _clock
	if _sampling() and is_instance_valid(prop):
		var base := prop.to_global(_base)
		var tip := prop.to_global(_tip)
		_samples.append([base, tip, now])
	while not _samples.is_empty() and now - float(_samples[0][2]) > LIFE:
		_samples.pop_front()
	if _samples.is_empty() and _over():
		queue_free()
		return
	_im.clear_surfaces()
	if _samples.size() < 2:
		return
	_im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for s in _samples:
		var k := 1.0 - (now - float(s[2])) / LIFE
		var c := color
		c.a *= k * k
		_im.surface_set_color(Color(c, 0.0))
		_im.surface_add_vertex(s[0])
		_im.surface_set_color(c)
		_im.surface_add_vertex(s[1])
	_im.surface_end()


func _in_attack() -> bool:
	return is_instance_valid(fighter) and fighter.attack == attack and fighter.state == Fighter.State.ATTACK


func _sampling() -> bool:
	return _in_attack() and fighter.state_t >= attack.active_start * 0.6 and fighter.state_t <= attack.active_end + 0.04


func _over() -> bool:
	return not _in_attack() or fighter.state_t > attack.active_end + 0.04
