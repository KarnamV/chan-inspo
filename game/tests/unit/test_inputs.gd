extends GutTest
## Gamepad bindings that menus depend on.


func _pad(button: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button
	return e


func test_a_confirms_in_menus() -> void:
	Inputs.register()
	assert_true(InputMap.action_has_event(&"ui_accept", _pad(JOY_BUTTON_A)))


func test_b_backs_out_of_menus() -> void:
	Inputs.register()
	assert_true(InputMap.action_has_event(&"ui_cancel", _pad(JOY_BUTTON_B)))


func test_keyboard_confirm_kept() -> void:
	Inputs.register()
	var enter := InputEventKey.new()
	enter.keycode = KEY_ENTER
	assert_true(InputMap.action_has_event(&"ui_accept", enter))


func test_register_twice_adds_no_duplicates() -> void:
	Inputs.register()
	Inputs.register()
	var n := InputMap.action_get_events(&"ui_accept").filter(
		func(e: InputEvent) -> bool: return e is InputEventJoypadButton and e.button_index == JOY_BUTTON_A).size()
	assert_eq(n, 1)


func test_closing_a_menu_does_not_dodge() -> void:
	Input.action_press(&"dodge")
	Inputs.release_gameplay()
	assert_false(Input.is_action_pressed(&"dodge"))
	assert_false(Inputs.just_pressed(&"dodge"))
