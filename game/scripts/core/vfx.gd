class_name Vfx
extends RefCounted
## Small code-built effects: hit sparks, dust puffs, drifting embers, blob shadows. CPU particles for
## one-shots (no shader compile hitch on the first hit).

static var _mats := {}
static var _dot: GradientTexture2D


## Round soft-edged sprite so particle quads read as sparks/puffs, not squares.
static func _soft_dot() -> GradientTexture2D:
	if _dot == null:
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.add_point(0.45, Color(1, 1, 1, 0.8))
		g.set_color(g.get_point_count() - 1, Color(1, 1, 1, 0))
		_dot = GradientTexture2D.new()
		_dot.gradient = g
		_dot.fill = GradientTexture2D.FILL_RADIAL
		_dot.fill_from = Vector2(0.5, 0.5)
		_dot.fill_to = Vector2(1.0, 0.5)
		_dot.width = 64
		_dot.height = 64
	return _dot


static func _mat(c: Color, unshaded := true) -> StandardMaterial3D:
	if _mats.has(c):
		return _mats[c]
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED if unshaded else BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.albedo_color = c
	m.albedo_texture = _soft_dot()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.vertex_color_use_as_albedo = true
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_mats[c] = m
	return m


static func _burst(parent: Node, at: Vector3, amount: int, life: float, mesh: Mesh, color: Color) -> CPUParticles3D:
	var p := CPUParticles3D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = life
	p.mesh = mesh
	p.material_override = _mat(color)
	p.position = at
	p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 1))
	fade.set_color(1, Color(1, 1, 1, 0))
	p.color_ramp = fade
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p


## Sparks where a hit lands. Magic = jade, fire = orange, physical = white-gold.
static func hit(target: Node3D, info: DamageInfo) -> void:
	var lvl := target.get_tree().get_first_node_in_group(&"level_root")
	if lvl == null:
		return
	var c := Color(1.0, 0.92, 0.7)
	if info.type == DamageInfo.Type.MAGIC:
		c = Color(0.4, 1.0, 0.75)
	if info.element == &"fire":
		c = Color(1.0, 0.55, 0.15)
	var q := QuadMesh.new()
	q.size = Vector2(0.09, 0.09)
	var p := _burst(lvl, target.global_position + Vector3(0, 1.1, 0), 18 if info.knockdown else 10, 0.32, q, c)
	p.direction = Vector3.UP
	p.spread = 180.0
	p.initial_velocity_min = 3.5
	p.initial_velocity_max = 7.5 if info.knockdown else 5.5
	p.gravity = Vector3(0, -14, 0)
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	# a quick flash ring for weight
	var ring := QuadMesh.new()
	ring.size = Vector2(0.9, 0.9) * (1.5 if info.knockdown else 1.0)
	var f := _burst(lvl, target.global_position + Vector3(0, 1.1, 0), 1, 0.12, ring, Color(c, 0.55))
	f.initial_velocity_min = 0.0
	f.initial_velocity_max = 0.0
	f.gravity = Vector3.ZERO


## Dust puff at the feet (knockdowns, dodges, heavy landings).
static func dust(at: Vector3, big := false) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var lvl := tree.get_first_node_in_group(&"level_root") if tree else null
	if lvl == null:
		return
	var q := QuadMesh.new()
	q.size = Vector2(0.4, 0.4)
	# low alpha, kept near the floor: stacked puffs used to merge into one opaque white blob
	var p := _burst(lvl, at + Vector3(0, 0.1, 0), 10 if big else 5, 0.5, q, Color(0.62, 0.55, 0.52, 0.16))
	p.direction = Vector3.UP
	p.spread = 80.0
	p.flatness = 0.7
	p.initial_velocity_min = 1.2
	p.initial_velocity_max = 2.8 if big else 1.8
	p.gravity = Vector3(0, -1.5, 0)
	p.damping_min = 2.0
	p.damping_max = 3.0
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.6


## Embers drifting up through the room (night-market ambience).
static func embers(parent: Node, half: float) -> void:
	var p := GPUParticles3D.new()
	p.amount = 70
	p.lifetime = 7.0
	p.preprocess = 7.0
	p.visibility_aabb = AABB(Vector3(-half, -1, -half), Vector3(half * 2, 10, half * 2))
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(half, 0.2, half)
	pm.direction = Vector3.UP
	pm.spread = 25.0
	pm.initial_velocity_min = 0.25
	pm.initial_velocity_max = 0.7
	pm.gravity = Vector3(0.15, 0.05, 0.1)
	pm.turbulence_enabled = true
	pm.turbulence_noise_strength = 0.6
	pm.scale_min = 0.5
	pm.scale_max = 1.3
	var fade := Gradient.new()
	fade.set_color(0, Color(1, 1, 1, 0))
	fade.add_point(0.2, Color(1, 1, 1, 1))
	fade.set_color(fade.get_point_count() - 1, Color(1, 1, 1, 0))
	var ramp := GradientTexture1D.new()
	ramp.gradient = fade
	pm.color_ramp = ramp
	p.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.06, 0.06)
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.55, 0.2)
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.emission_enabled = true
	m.emission = Color(1.0, 0.45, 0.15)
	m.emission_energy_multiplier = 3.0
	m.albedo_texture = _soft_dot()
	q.material = m
	p.draw_pass_1 = q
	p.position = Vector3(0, 0.3, 0)
	parent.add_child(p)


## Soft round shadow under a character (grounds it on the busy floor). `ring` adds a coloured rim.
static func blob_shadow(owner: Node3D, radius: float, ring := Color(0, 0, 0, 0)) -> Decal:
	var g := Gradient.new()
	g.set_color(0, Color(0, 0, 0, 0.6))
	g.set_color(1, Color(0, 0, 0, 0))
	if ring.a > 0.0:
		g.set_color(0, Color(0, 0, 0, 0.45))
		g.add_point(0.72, Color(0, 0, 0, 0.2))
		g.add_point(0.84, ring)
		g.add_point(0.92, Color(ring, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var d := Decal.new()
	d.texture_albedo = tex
	d.size = Vector3(radius * 2.0, 0.6, radius * 2.0)
	d.cull_mask = 1   # floor/world only: character meshes render on layer 2 (Fighter)
	d.upper_fade = 0.2
	d.lower_fade = 0.2
	owner.add_child(d)
	return d


## Coloured floor ring with no shadow (marks a possessed host the way Jackie's jade ring marks her).
static func ring(owner: Node3D, radius: float, color: Color) -> Decal:
	var g := Gradient.new()
	g.set_color(0, Color(color, 0.0))
	g.add_point(0.72, Color(color, 0.0))
	g.add_point(0.84, color)
	g.set_color(g.get_point_count() - 1, Color(color, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 128
	tex.height = 128
	var d := Decal.new()
	d.texture_albedo = tex
	d.size = Vector3(radius * 2.0, 0.6, radius * 2.0)
	d.cull_mask = 1
	d.upper_fade = 0.2
	d.lower_fade = 0.2
	owner.add_child(d)
	return d


## "+N gold" that rises and fades where gold was earned, with a few coin glints.
static func gold_pop(at: Vector3, amount: int) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var lvl := tree.get_first_node_in_group(&"level_root") if tree else null
	if lvl == null or amount <= 0:
		return
	var l := Label3D.new()
	l.text = "+%d gold" % amount
	l.font_size = 48
	l.outline_size = 10
	l.modulate = Color(1.0, 0.82, 0.3)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.position = at + Vector3(0, 2.0, 0)
	lvl.add_child(l)
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, "position:y", l.position.y + 1.2, 0.9).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.9).set_delay(0.35)
	tw.chain().tween_callback(l.queue_free)
	var s := SphereMesh.new()
	s.radius = 0.05
	s.height = 0.1
	var p := _burst(lvl, at + Vector3(0, 1.0, 0), 6 + amount, 0.6, s, Color(1.0, 0.78, 0.25))
	p.direction = Vector3.UP
	p.spread = 40.0
	p.initial_velocity_min = 2.5
	p.initial_velocity_max = 4.0
	p.gravity = Vector3(0, -9.0, 0)


## Perfect dodge: a bright ring bursts out from under the dodger.
static func ring_flash(owner: Node3D) -> void:
	var d := ring(owner, 0.6, Color(1.0, 0.85, 0.45, 0.9))
	d.position.y = 0.1
	var tw := d.create_tween().set_parallel()
	tw.tween_property(d, "size", Vector3(5.0, 0.6, 5.0), 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_property(d, "modulate:a", 0.0, 0.35)
	tw.chain().tween_callback(d.queue_free)


## Ground slam: a dusty ring racing outward along the floor.
static func shockwave(at: Vector3) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var lvl := tree.get_first_node_in_group(&"level_root") if tree else null
	if lvl == null:
		return
	var holder := Node3D.new()
	lvl.add_child(holder)
	holder.global_position = at
	var d := ring(holder, 0.5, Color(0.95, 0.8, 0.6, 0.85))
	var tw := d.create_tween().set_parallel()
	tw.tween_property(d, "size", Vector3(6.5, 0.6, 6.5), 0.4).set_ease(Tween.EASE_OUT)
	tw.tween_property(d, "modulate:a", 0.0, 0.4)
	tw.chain().tween_callback(holder.queue_free)
