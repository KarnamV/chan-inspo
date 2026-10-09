class_name BossBar
extends CanvasLayer
## Big boss health bar at the top of the screen.

var boss: Fighter
var bar := ProgressBar.new()
var lbl := Label.new()


func bind(b: Fighter, title: String) -> void:
	boss = b
	lbl.text = title


func _ready() -> void:
	var box := VBoxContainer.new()
	box.anchor_left = 0.2
	box.anchor_right = 0.8
	box.anchor_top = 0.03
	add_child(box)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 26)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.4))
	box.add_child(lbl)
	bar.custom_minimum_size = Vector2(0, 22)
	bar.show_percentage = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.8, 0.15, 0.1)
	bar.add_theme_stylebox_override("fill", sb)
	box.add_child(bar)


func _process(_d: float) -> void:
	if boss == null or not is_instance_valid(boss):
		visible = false
		return
	bar.max_value = boss.health.max_hp
	bar.value = boss.health.hp
	visible = not boss.is_dead()
