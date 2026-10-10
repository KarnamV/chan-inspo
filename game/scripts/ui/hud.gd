class_name Hud
extends CanvasLayer
## HUD: portrait + HP/chi bars (with a trailing damage chip), status line, 3 talisman slots (icon,
## cooldown sweep, device-aware button), low-HP vignette, controls hint early in a run.

const SLOT_ACTIONS := [&"attack_light", &"attack_heavy", &"grab"]
const PORTRAIT := "res://assets/portraits/portrait_jackie.png"
const HP_COLOR := Color(0.9, 0.22, 0.18)
const CHI_COLOR := Color(0.3, 0.9, 0.65)
const HINT_SECONDS := 25.0

var controller: PlayerController
var hp_bar := ProgressBar.new()
var hp_chip := ProgressBar.new()     ## trails hp_bar so damage reads as a chunk
var spirit_bar := ProgressBar.new()
var name_lbl := Label.new()
var hp_lbl := Label.new()
var info := Label.new()
var hint := Label.new()
var slots_box := HBoxContainer.new()
var vignette := TextureRect.new()
var _slot_nodes: Array = []   # [panel, icon, label, talisman, cd_shade, cd_label]
var _last_hp := -1.0
var _hurt := 0.0
var _hint_t := HINT_SECONDS


func _ready() -> void:
	_build_vignette()
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 14)
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var frame := PanelContainer.new()
	var fs := StyleBoxFlat.new()
	fs.bg_color = Color(0.25, 0.08, 0.06)
	fs.border_color = Color(0.86, 0.64, 0.3)
	fs.set_border_width_all(2)
	fs.set_corner_radius_all(36)
	frame.add_theme_stylebox_override("panel", fs)
	var face := TextureRect.new()
	face.custom_minimum_size = Vector2(68, 68)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	if ResourceLoader.exists(PORTRAIT):
		var at := AtlasTexture.new()   # head and shoulders of the half-body portrait
		at.atlas = load(PORTRAIT)
		at.region = Rect2(300, 40, 420, 420)
		face.texture = at
		var key := ShaderMaterial.new()
		key.shader = load("res://assets/shaders/key_white.gdshader")
		key.set_shader_parameter("circle", 1.0)
		face.material = key
	frame.add_child(face)
	row.add_child(frame)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	row.add_child(col)
	name_lbl.theme_type_variation = &"Header"
	name_lbl.add_theme_font_size_override("font_size", 22)
	col.add_child(name_lbl)
	var hp_stack := Control.new()
	hp_stack.custom_minimum_size = Vector2(300, 20)
	col.add_child(hp_stack)
	for b in [hp_chip, hp_bar]:
		b.set_anchors_preset(Control.PRESET_FULL_RECT)
		b.show_percentage = false
		hp_stack.add_child(b)
	_fill(hp_chip, Color(1.0, 0.85, 0.55))
	_fill(hp_bar, HP_COLOR)
	hp_bar.add_theme_stylebox_override("background", StyleBoxEmpty.new())
	hp_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	hp_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hp_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_lbl.add_theme_font_size_override("font_size", 13)
	hp_stack.add_child(hp_lbl)
	spirit_bar.custom_minimum_size = Vector2(300, 10)
	spirit_bar.show_percentage = false
	_fill(spirit_bar, CHI_COLOR)
	col.add_child(spirit_bar)
	info.add_theme_font_size_override("font_size", 14)
	info.modulate = Color(1, 1, 1, 0.85)
	col.add_child(info)

	slots_box.add_theme_constant_override("separation", 12)
	slots_box.anchor_top = 1.0
	slots_box.anchor_bottom = 1.0
	slots_box.offset_left = 18
	slots_box.offset_top = -132
	add_child(slots_box)

	hint.add_theme_font_size_override("font_size", 14)
	hint.anchor_left = 1.0
	hint.anchor_right = 1.0
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = -900
	hint.offset_right = -18
	hint.offset_top = -34
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(hint)
	if Run.active and Run.room_i > 1:
		_hint_t = 0.0
	Events.talismans_changed.connect(_rebuild_slots)
	Inputs.device_changed.connect(func(_pad: bool) -> void: _hint_t = maxf(_hint_t, 8.0))


func _fill(bar: ProgressBar, c: Color) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.set_corner_radius_all(5)
	sb.border_color = c.lightened(0.35)
	sb.border_width_top = 2   # small highlight on top for a glossy bar
	bar.add_theme_stylebox_override("fill", sb)


func _build_vignette() -> void:
	var g := Gradient.new()
	g.set_color(0, Color(0.6, 0.0, 0.0, 0.0))
	g.add_point(0.55, Color(0.6, 0.0, 0.0, 0.0))
	g.set_color(g.get_point_count() - 1, Color(0.7, 0.02, 0.02, 0.85))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.05, 0.5)
	vignette.texture = tex
	vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	vignette.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vignette.stretch_mode = TextureRect.STRETCH_SCALE
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.modulate.a = 0.0
	add_child(vignette)


func bind(c: PlayerController) -> void:
	controller = c
	_rebuild_slots()


func _rebuild_slots() -> void:
	for n in slots_box.get_children():
		n.queue_free()
	_slot_nodes.clear()
	if controller == null:
		return
	for i in controller.equipped.size():
		var t := controller.equipped[i]
		var col := VBoxContainer.new()
		col.add_theme_constant_override("separation", 2)
		var panel := PanelContainer.new()
		panel.custom_minimum_size = Vector2(78, 78)
		var ps := StyleBoxFlat.new()
		ps.bg_color = Color(0.1, 0.05, 0.05, 0.85)
		ps.border_color = Color(0.86, 0.64, 0.3) if t.is_active_talisman() else Color(0.5, 0.42, 0.35)
		ps.set_border_width_all(2)
		ps.set_corner_radius_all(10)
		ps.set_content_margin_all(6)
		panel.add_theme_stylebox_override("panel", ps)
		var icon := TextureRect.new()
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var path := "res://assets/icons/icon_talisman_%s.png" % t.id
		if ResourceLoader.exists(path):
			icon.texture = load(path)
		panel.add_child(icon)
		var shade_box := Control.new()
		shade_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var shade := ColorRect.new()   # cooldown sweep: shrinks toward the bottom as it recovers
		shade.color = Color(0, 0, 0, 0.62)
		shade.anchor_top = 1.0
		shade.anchor_right = 1.0
		shade.anchor_bottom = 1.0
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		shade_box.add_child(shade)
		panel.add_child(shade_box)
		var cd_lbl := Label.new()
		cd_lbl.theme_type_variation = &"Header"
		cd_lbl.add_theme_font_size_override("font_size", 26)
		cd_lbl.add_theme_color_override("font_color", Color(1, 1, 1))
		cd_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		panel.add_child(cd_lbl)
		col.add_child(panel)
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 13)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		col.add_child(lbl)
		slots_box.add_child(col)
		_slot_nodes.append([panel, icon, lbl, t, shade, cd_lbl])


func _process(delta: float) -> void:
	if controller == null or controller.controlled == null:
		return
	var f := controller.controlled
	hp_bar.max_value = f.health.max_hp
	hp_bar.value = f.health.hp
	hp_chip.max_value = f.health.max_hp
	hp_chip.value = maxf(move_toward(hp_chip.value, f.health.hp, f.health.max_hp * 0.5 * delta), f.health.hp)
	hp_lbl.text = "%d / %d" % [ceili(f.health.hp), int(f.health.max_hp)]
	spirit_bar.max_value = controller.spirit_max
	spirit_bar.value = controller.spirit
	if _last_hp >= 0.0 and f.health.hp < _last_hp - 0.5 and f == controller.hero:
		_hurt = 0.55
	_last_hp = f.health.hp
	var low := f.health.hp / maxf(f.health.max_hp, 1.0) < 0.25
	_hurt = maxf(_hurt - delta, 0.0)
	var pulse := (0.25 + 0.15 * sin(Time.get_ticks_msec() * 0.006)) if low else 0.0
	vignette.modulate.a = maxf(_hurt, pulse)

	var held := String(f.held_prop.data.id).replace("_", " ") if f.held_prop and is_instance_valid(f.held_prop) else "bare hands"
	if f.held_prop and is_instance_valid(f.held_prop) and f.held_prop.ignited > 0.0:
		held += " (burning)"
	var who := "Jackie"
	if controller.host:
		who = "%s  %.0fs" % [String(f.data.id).replace("_", " ").capitalize(), controller.possess_left]
	var monkey := controller.talisman(&"monkey") as Zodiac.Monkey
	if monkey and monkey.form:
		who = "%s  %d attacks left" % [String(f.data.id).replace("_", " ").capitalize(), monkey.attacks_left]
	var tiger := controller.talisman(&"tiger") as Zodiac.Tiger
	if tiger and tiger.twin:
		who = "Jackie (%s)  %.0fs" % ["Yang" if f == controller.hero else "Yin", tiger.left]
	name_lbl.text = who
	info.text = "Holding: %s" % held
	if Run.active:
		info.text += "   ·   Room %d/%d   ·   %d gold   ·   %d extra lives" % [Run.room_i + 1, Run.REALM1.size(), Run.gold, Run.extra_lives]

	for i in _slot_nodes.size():
		var t: Talisman = _slot_nodes[i][3]
		var lbl: Label = _slot_nodes[i][2]
		var icon: TextureRect = _slot_nodes[i][1]
		var shade: ColorRect = _slot_nodes[i][4]
		var cd_lbl: Label = _slot_nodes[i][5]
		var frac := clampf(t.cd_left / maxf(t.cooldown, 0.01), 0.0, 1.0)
		shade.anchor_top = 1.0 - frac
		cd_lbl.text = "%d" % ceili(t.cd_left) if t.cd_left > 0.0 else ""
		lbl.text = "%s\n%s" % [t.title, Inputs.combo(&"talisman_mod", SLOT_ACTIONS[i]) if t.is_active_talisman() else "passive"]
		icon.modulate = Color(1, 1, 1) if t.is_ready() else Color(0.6, 0.6, 0.6)

	_hint_t = maxf(_hint_t - delta, 0.0)
	hint.text = Inputs.controls_line()
	hint.modulate.a = clampf(_hint_t / 3.0, 0.0, 0.8)
