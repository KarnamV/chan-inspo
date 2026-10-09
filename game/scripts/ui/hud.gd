class_name Hud
extends CanvasLayer
## Prototype HUD: HP, spirit, what you're holding, possession status, controls hint.

var controller: PlayerController
var hp_bar := ProgressBar.new()
var spirit_bar := ProgressBar.new()
var info := Label.new()
var hint := Label.new()


func _ready() -> void:
	var box := VBoxContainer.new()
	box.position = Vector2(20, 18)
	box.custom_minimum_size = Vector2(320, 0)
	add_child(box)
	for pair in [[hp_bar, Color(0.85, 0.2, 0.2)], [spirit_bar, Color(0.25, 0.85, 0.55)]]:
		var bar: ProgressBar = pair[0]
		bar.custom_minimum_size = Vector2(320, 18)
		bar.show_percentage = false
		var sb := StyleBoxFlat.new()
		sb.bg_color = pair[1]
		bar.add_theme_stylebox_override("fill", sb)
		box.add_child(bar)
	info.add_theme_font_size_override("font_size", 18)
	box.add_child(info)
	hint.add_theme_font_size_override("font_size", 14)
	hint.modulate = Color(1, 1, 1, 0.7)
	hint.text = "WASD move · J light · K heavy · L grab/throw · Space dodge · Ctrl+J Sheep (possess a knocked-down demon) · R reset"
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.position = Vector2(20, -34)
	add_child(hint)


func bind(c: PlayerController) -> void:
	controller = c


func _process(_d: float) -> void:
	if controller == null or controller.controlled == null:
		return
	var f := controller.controlled
	hp_bar.max_value = f.health.max_hp
	hp_bar.value = f.health.hp
	spirit_bar.max_value = controller.spirit_max
	spirit_bar.value = controller.spirit
	var held := String(f.held_prop.data.id) if f.held_prop and is_instance_valid(f.held_prop) else "bare hands"
	var who := "POSSESSING %s" % String(f.data.id).to_upper() if controller.host else "Jackie"
	var sheep := ""
	if controller.host == null:
		sheep = "  ·  Sheep ready!" if controller.sheep_target() and controller.spirit >= controller.sheep_cost else ""
	info.text = "%s  ·  %s%s" % [who, held, sheep]
