extends GutTest
## Menus must work on a gamepad: A confirms, the panel is centred and fits on screen.

var _picked := -1


func _shop_cards() -> Array:
	var cards: Array = []
	for i in 4:
		cards.append({"title": "Item %d — 50g" % i, "text": "Something to buy.", "icon": "", "enabled": i != 0})
	cards.append({"title": "Leave", "text": "Keep your gold.", "icon": "", "enabled": true})
	return cards


func _press_pad_a() -> void:
	for pressed in [true, false]:
		var e := InputEventJoypadButton.new()
		e.button_index = JOY_BUTTON_A
		e.pressed = pressed
		Input.parse_input_event(e)
		await get_tree().process_frame


func test_pad_a_buys_from_a_five_card_shop() -> void:
	_picked = -1
	var p := ChoicePanel.open(get_tree().root, "Shop", _shop_cards())
	p.chosen.connect(func(i: int) -> void: _picked = i)
	for i in 3:
		await get_tree().process_frame   # deferred grab_focus
	await _press_pad_a()
	assert_eq(_picked, 1, "A picks the first enabled card (card 0 is too expensive)")
	assert_false(get_tree().paused, "game unpaused after buying")


func test_five_cards_fit_and_are_centred() -> void:
	get_tree().root.size = Vector2i(1280, 720)   # headless starts with a tiny window
	var p := ChoicePanel.open(get_tree().root, "Shop", _shop_cards())
	await get_tree().process_frame
	await get_tree().process_frame
	var screen := p.get_viewport().get_visible_rect()
	var first: Button = p._buttons[0]
	var last: Button = p._buttons[-1]
	var left := first.get_global_rect().position.x
	var right := last.get_global_rect().end.x
	var design_w := float(ProjectSettings.get_setting("display/window/size/viewport_width"))
	assert_gte(left, 20.0, "first card on screen")
	assert_lte(right, design_w - 20.0, "last card on screen")
	assert_almost_eq(left, screen.size.x - right, 2.0, "row centred")
	p.choose(4)
