class_name DialoguePanel
extends CanvasLayer
## Simple speaker portrait + text box. Any confirm key / click continues. Pauses the game.

signal finished

var speaker := ""
var text := ""
var portrait := ""
var _open_ms := 0


static func open(parent: Node, p_speaker: String, p_text: String, p_portrait := "") -> DialoguePanel:
	var d := DialoguePanel.new()
	d.speaker = p_speaker
	d.text = p_text
	d.portrait = p_portrait
	parent.add_child(d)
	return d


## Shows lines one after another: [[speaker, text, portrait path], ...]; `done` runs after the last.
static func sequence(parent: Node, lines: Array, done := Callable()) -> void:
	if lines.is_empty():
		if done.is_valid():
			done.call()
		return
	var l: Array = lines[0]
	var d := open(parent, l[0], l[1], l[2] if l.size() > 2 else "")
	d.finished.connect(func() -> void: sequence(parent, lines.slice(1), done))


func _ready() -> void:
	_open_ms = Time.get_ticks_msec()
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
		var key := ShaderMaterial.new()
		key.shader = load("res://assets/shaders/key_white.gdshader")
		tr.material = key
		h.add_child(tr)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var n := Label.new()
	n.text = speaker
	n.theme_type_variation = &"Header"
	v.add_child(n)
	var t := Label.new()
	t.text = text
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_font_size_override("font_size", 18)
	t.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(t)
	var hint := Label.new()
	hint.text = "[%s] continue" % ("A" if Inputs.using_pad else "Enter / click")
	hint.modulate = Color(1, 1, 1, 0.6)
	v.add_child(hint)


func _unhandled_input(event: InputEvent) -> void:
	if Time.get_ticks_msec() - _open_ms < 150:   # the press that opened/closed the last line
		return
	if event.is_action_pressed(&"attack_light") or event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept") \
			or (event is InputEventMouseButton and event.pressed):
		close()


func close() -> void:
	Inputs.release_gameplay()
	get_tree().paused = false
	finished.emit()
	queue_free()
