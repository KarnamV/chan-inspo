class_name ChoicePanel
extends CanvasLayer
## Modal "pick one" panel (rewards, shop, shrine). Pauses the game while open.
## Keys 1-4, click, or gamepad focus + accept. Bots call `choose(i)` directly.

signal chosen(index: int)

var title := ""
var cards: Array = []     # [{title, text, icon (path or ""), enabled}]
var cancel_index := -1    ## >= 0: B / Esc / Start picks this card (e.g. Resume)
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
	var center := CenterContainer.new()   # centred for any number of cards (the shop has 5)
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 18)
	center.add_child(root)
	var card_w := 210.0 if cards.size() <= 4 else 180.0
	var t := Label.new()
	t.text = title
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.theme_type_variation = &"Title"
	t.add_theme_font_size_override("font_size", 38)
	root.add_child(t)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 16)
	root.add_child(row)
	for i in cards.size():
		var c: Dictionary = cards[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(card_w, 280)
		b.disabled = not c.get("enabled", true)
		b.focus_mode = Control.FOCUS_ALL
		var v := VBoxContainer.new()
		v.set_anchors_preset(Control.PRESET_FULL_RECT)
		v.offset_left = 12
		v.offset_top = 14
		v.offset_right = -12
		v.offset_bottom = -12
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
		ct.text = c.get("title", "") if Inputs.using_pad else "%d. %s" % [i + 1, c.get("title", "")]
		ct.theme_type_variation = &"Header"
		ct.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		ct.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ct.add_theme_font_size_override("font_size", 21)
		ct.mouse_filter = Control.MOUSE_FILTER_IGNORE
		v.add_child(ct)
		var body := Label.new()
		body.text = c.get("text", "")
		body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.add_theme_font_size_override("font_size", 15)
		body.mouse_filter = Control.MOUSE_FILTER_IGNORE
		body.custom_minimum_size = Vector2(card_w - 30.0, 0)   # inside the 12 px padding
		v.add_child(body)
		b.pressed.connect(choose.bind(i))
		row.add_child(b)
		_buttons.append(b)
	for b in _buttons:
		if not b.disabled:
			b.grab_focus.call_deferred()
			break


func _unhandled_input(event: InputEvent) -> void:
	if cancel_index >= 0 and (event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"pause")):
		choose(cancel_index)
		get_viewport().set_input_as_handled()
		return
	var k := event as InputEventKey
	if k and k.pressed and not k.echo:
		var i := k.physical_keycode - KEY_1
		if i >= 0 and i < _buttons.size() and not _buttons[i].disabled:
			choose(i)
			get_viewport().set_input_as_handled()


func choose(i: int) -> void:
	if i < 0 or i >= cards.size() or not cards[i].get("enabled", true):
		return
	Inputs.release_gameplay()
	get_tree().paused = false
	chosen.emit(i)
	queue_free()
