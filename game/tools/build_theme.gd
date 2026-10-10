extends SceneTree
## Builds res://assets/ui/theme.tres (project-wide UI theme). Re-run after changing values:
##   godot --headless --path . -s tools/build_theme.gd
## Look: dark red lacquer panels, gold trim, warm off-white text, jade focus ring (gamepad).

const BODY := "res://assets/fonts/Nunito.ttf"
const TITLE := "res://assets/fonts/LilitaOne-Regular.ttf"
const LACQUER := Color(0.13, 0.07, 0.06, 0.94)
const GOLD := Color(0.86, 0.64, 0.3)
const JADE := Color(0.35, 0.95, 0.7)
const TEXT := Color(0.98, 0.93, 0.85)


func _init() -> void:
	var t := Theme.new()
	var body := FontVariation.new()
	body.base_font = load(BODY)
	body.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 700}
	var title: Font = load(TITLE)
	t.default_font = body
	t.default_font_size = 18

	for type in ["Label", "Button", "CheckBox", "LineEdit", "RichTextLabel"]:
		t.set_color("font_color", type, TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.75))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 2)

	# headers / titles: Label with theme_type_variation = "Header" / "Title"
	for v in [["Header", 28, GOLD], ["Title", 46, Color(1.0, 0.78, 0.38)]]:
		t.set_type_variation(v[0], "Label")
		t.set_font("font", v[0], title)
		t.set_font_size("font_size", v[0], v[1])
		t.set_color("font_color", v[0], v[2])
		t.set_color("font_outline_color", v[0], Color(0.2, 0.05, 0.03))
		t.set_constant("outline_size", v[0], 6)

	t.set_stylebox("panel", "PanelContainer", _box(LACQUER, GOLD, 2, 10, 16))
	t.set_stylebox("panel", "Panel", _box(LACQUER, GOLD, 2, 10, 16))

	t.set_stylebox("normal", "Button", _box(Color(0.18, 0.09, 0.07, 0.95), GOLD.darkened(0.35), 2, 8, 10))
	t.set_stylebox("hover", "Button", _box(Color(0.3, 0.12, 0.08, 0.97), GOLD, 2, 8, 10))
	t.set_stylebox("pressed", "Button", _box(Color(0.6, 0.14, 0.1, 0.97), Color(1.0, 0.8, 0.4), 3, 8, 10))
	t.set_stylebox("hover_pressed", "Button", _box(Color(0.66, 0.17, 0.12, 0.97), Color(1.0, 0.85, 0.5), 3, 8, 10))
	t.set_stylebox("disabled", "Button", _box(Color(0.12, 0.1, 0.1, 0.8), Color(0.35, 0.3, 0.3), 2, 8, 10))
	var focus := _box(Color(0, 0, 0, 0), JADE, 3, 9, 10)
	focus.expand_margin_left = 3
	focus.expand_margin_right = 3
	focus.expand_margin_top = 3
	focus.expand_margin_bottom = 3
	t.set_stylebox("focus", "Button", focus)
	t.set_color("font_hover_color", "Button", Color(1, 0.95, 0.8))
	t.set_color("font_pressed_color", "Button", Color(1, 1, 1))
	t.set_color("font_focus_color", "Button", Color(1, 1, 1))
	t.set_color("font_disabled_color", "Button", Color(0.6, 0.55, 0.5))
	t.set_constant("h_separation", "Button", 10)

	var bar_bg := _box(Color(0.05, 0.03, 0.03, 0.85), Color(0, 0, 0, 0.9), 2, 6, 0)
	t.set_stylebox("background", "ProgressBar", bar_bg)
	t.set_stylebox("fill", "ProgressBar", _box(Color(0.85, 0.25, 0.2), Color(0, 0, 0, 0), 0, 5, 0))

	t.set_stylebox("panel", "TooltipPanel", _box(LACQUER, GOLD, 1, 6, 8))
	DirAccess.make_dir_recursive_absolute("res://assets/ui")
	var err := ResourceSaver.save(t, "res://assets/ui/theme.tres")
	print("theme saved: ", err)
	quit()


func _box(bg: Color, border: Color, bw: int, radius: int, pad: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	s.anti_aliasing = true
	return s
