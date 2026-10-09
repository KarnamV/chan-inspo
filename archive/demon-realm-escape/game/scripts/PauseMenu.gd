## PauseMenu.gd — the pause overlay shown when the player presses Esc.
##
## Fully code-built (no .tscn), same pattern as ShopUI/ShrineUI: pauses the game
## while open (get_tree().paused + process_mode ALWAYS so its own buttons still
## respond). Offers Resume, Restart Room, and Quit to Hub.
##
## "Restart Room" resets the run stats and reloads the current scene, so the
## room regenerates fresh with a full-HP player — a clean retry.

class_name PauseMenu
extends CanvasLayer

signal closed

const PANEL_SIZE: Vector2 = Vector2(360.0, 300.0)


func open() -> void:
	layer = 60   # above shop/shrine (50) so Esc-during-nothing always wins
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	get_tree().paused = true


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel: Panel = Panel.new()
	panel.custom_minimum_size = PANEL_SIZE
	panel.size = PANEL_SIZE
	panel.position = (Vector2(1280, 720) - PANEL_SIZE) * 0.5
	add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.text = "⏸  Paused"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	var resume: Button = Button.new()
	resume.text = "Resume  (Esc)"
	resume.pressed.connect(_close)
	vbox.add_child(resume)

	var restart: Button = Button.new()
	restart.text = "Restart Room"
	restart.pressed.connect(_on_restart)
	vbox.add_child(restart)

	var quit_hub: Button = Button.new()
	quit_hub.text = "Quit to Hub"
	quit_hub.pressed.connect(_on_quit_to_hub)
	vbox.add_child(quit_hub)


# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------

func _on_restart() -> void:
	# Clean retry: clear run stats so the reloaded room starts from scratch.
	get_tree().paused = false
	RunStats.reset()
	get_tree().reload_current_scene()


func _on_quit_to_hub() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Hub.tscn")


# ---------------------------------------------------------------------------
# Close / input
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo \
			and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	get_tree().paused = false
	emit_signal("closed")
	queue_free()
