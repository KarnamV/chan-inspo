class_name DialoguePanel
extends CanvasLayer
## Simple speaker portrait + text box. Any confirm key / click continues. Pauses the game.

signal finished

var speaker := ""
var text := ""
var portrait := ""


static func open(parent: Node, p_speaker: String, p_text: String, p_portrait := "") -> DialoguePanel:
	var d := DialoguePanel.new()
	d.speaker = p_speaker
	d.text = p_text
	d.portrait = p_portrait
	parent.add_child(d)
	return d


func _ready() -> void:
	layer = 19
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var panel := PanelContainer.new()
	panel.anchor_left = 0.08
	panel.anchor_right = 0.92
	panel.anchor_top = 0.66
	panel.anchor_bottom = 0.95
	add_child(panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	panel.add_child(h)
	if portrait != "" and ResourceLoader.exists(portrait):
		var tr := TextureRect.new()
		tr.texture = load(portrait)
		tr.custom_minimum_size = Vector2(150, 150)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		h.add_child(tr)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var n := Label.new()
	n.text = speaker
	n.add_theme_font_size_override("font_size", 24)
	n.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35))
	v.add_child(n)
	var t := Label.new()
	t.text = text
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_font_size_override("font_size", 18)
	t.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(t)
	var hint := Label.new()
	hint.text = "[J / click] continue"
	hint.modulate = Color(1, 1, 1, 0.6)
	v.add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"attack_light") or event.is_action_pressed(&"interact") \
			or (event is InputEventMouseButton and event.pressed):
		close()


func close() -> void:
	get_tree().paused = false
	finished.emit()
	queue_free()
