class_name CharacterLook
## Readability pass for characters: a soft rim light plus a thin dark outline, chained as next_pass
## on each model material (art pass 2: dark trousers and demon hides merged with the night floor). Model materials are shared per .glb, so this runs once per material.

enum Mode { NONE, RIM, OUTLINE, BOTH }
static var mode := Mode.BOTH

const HERO_RIM := Color(1.0, 0.82, 0.55)
const ENEMY_RIM := Color(1.0, 0.36, 0.22)


static func apply(meshes: Array[MeshInstance3D], rim: Color) -> void:
	if mode == Mode.NONE:
		return
	for mi in meshes:
		if mi.mesh == null:
			continue
		for s in mi.mesh.get_surface_count():
			var m := mi.get_active_material(s)
			if m == null or m.has_meta(&"look") or m.next_pass != null:
				continue
			m.set_meta(&"look", true)
			m.next_pass = _chain(rim)


static func _chain(rim: Color) -> Material:
	var first: ShaderMaterial = null
	if mode == Mode.RIM or mode == Mode.BOTH:
		first = ShaderMaterial.new()
		first.shader = preload("res://assets/shaders/character_rim.gdshader")
		first.set_shader_parameter(&"rim_color", rim)
	if mode == Mode.OUTLINE or mode == Mode.BOTH:
		var o := ShaderMaterial.new()
		o.shader = preload("res://assets/shaders/character_outline.gdshader")
		if first:
			first.next_pass = o
		else:
			first = o
	return first
