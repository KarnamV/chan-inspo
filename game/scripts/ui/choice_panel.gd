class_name ChoicePanel
extends CanvasLayer
## Modal "pick one" panel (rewards, shop, shrine). Pauses the game while open.
## Keys 1-4, click, or gamepad focus + accept. Bots call `choose(i)` directly.

signal chosen(index: int)

var title := ""
var cards: Array = []     # [{title, text, icon (path or ""), enabled}]
var _buttons: Array[Button] = []


static func open(parent: Node, p_title: String, p_cards: Array) -> ChoicePanel:
	var p := ChoicePanel.new()
	p.title = p_title
	p.cards = p_cards
	parent.add_child(p)
	return p


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_CENTER)
	root.position = Vector2(-460, -190)
	root.custom_minimum_size = Vector2(920, 380)
	root.add_theme_constant_override("separation", 18)
	add_child(root)
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 30)
	root.add_child(t)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	root.add_child(row)
	for i in cards.size():
		var c: Dictionary = cards[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(210, 280)
		b.disabled = not c.get("enabled", true)
		b.focus_mode = Control.FOCUS_ALL
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_theme_constant_override("separation", 8)
		b.add_child(v)
		var icon_path: String = c.get("icon", "")
		if icon_path != "" and ResourceLoader.exists(icon_path):
			var tr := TextureRect.new()
			tr.texture = load(icon_path)
			tr.custom_minimum_size = Vector2(96, 96)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			v.add_child(tr)
		var ct := Label.new()
		ct.text = "%d. %s" % [i + 1, c.get("title", "")]
		ct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ct.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ct.add_theme_font_size_override("font_size", 18)
		ct.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(ct)
		var body := Label.new()
		body.text = c.get("text", "")
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_size_override("font_size", 14)
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.custom_minimum_size = Vector2(190, 0)
		v.add_child(body)
		b.pressed.connect(choose.bind(i))
		row.add_child(b)
		_buttons.append(b)
	for b in _buttons:
		if not b.disabled:
			b.grab_focus.call_deferred()
			break


func _unhandled_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k and k.pressed and not k.echo:
		var i := k.physical_keycode - KEY_1
		if i >= 0 and i < _buttons.size() and not _buttons[i].disabled:
			choose(i)
			get_viewport().set_input_as_handled()


func choose(i: int) -> void:
	if i < 0 or i >= cards.size() or not cards[i].get("enabled", true):
		return
	get_tree().paused = false
	chosen.emit(i)
	queue_free()
