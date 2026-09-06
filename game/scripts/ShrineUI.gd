## ShrineUI.gd — the shrine overlay shown when the player enters a SHRINE room.
##
## Fully code-built (no .tscn), same pattern as ShopUI: pauses the game while
## open (process_mode ALWAYS), spends gold via RunStats.spend_gold().
##
## The player sacrifices gold for ONE boon, then the shrine is spent:
##   - Pray for Renewal (25g) — heal to full HP.
##   - Offer to the Shrine (40g) — a random permanent blessing (Iron Body /
##     Fury / Swiftness).
## They may also Leave without offering anything.

class_name ShrineUI
extends CanvasLayer

signal closed

const PANEL_SIZE: Vector2 = Vector2(520.0, 380.0)

const HEAL_COST:     int = 25
const BLESSING_COST: int = 40

var _player: Node = null

var _gold_label: Label = null
var _result_label: Label = null
var _heal_button: Button = null
var _bless_button: Button = null
var _spent: bool = false


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

func open(player: Node) -> void:
	_player = player
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build_ui()

	RunStats.gold_changed.connect(_on_gold_changed)
	_refresh_gold()
	_refresh_affordability()

	get_tree().paused = true


# ---------------------------------------------------------------------------
# Blessings — each is { name, desc, apply }. One is chosen at random.
# ---------------------------------------------------------------------------

func _blessings() -> Array:
	return [
		{
			"name": "Iron Body",
			"desc": "+25 Max HP",
			"apply": func() -> void: _player.add_max_hp(25),
		},
		{
			"name": "Fury",
			"desc": "+15% damage",
			"apply": func() -> void: _player.permanent_damage_mult *= 1.15,
		},
		{
			"name": "Swiftness",
			"desc": "+12% move speed",
			"apply": func() -> void:
				_player.speed_run *= 1.12
				_player.speed_walk *= 1.12,
		},
	]


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.6)
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
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.text = "⛩  Shrine"
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)

	var flavor: Label = Label.new()
	flavor.text = "Sacrifice gold for a single boon."
	flavor.add_theme_font_size_override("font_size", 13)
	flavor.add_theme_color_override("font_color", Color(0.7, 0.66, 0.6))
	vbox.add_child(flavor)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 16)
	_gold_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.25))
	vbox.add_child(_gold_label)

	vbox.add_child(HSeparator.new())

	_heal_button = Button.new()
	_heal_button.text = "Pray for Renewal — heal to full  (%d g)" % HEAL_COST
	_heal_button.pressed.connect(_on_pray)
	vbox.add_child(_heal_button)

	_bless_button = Button.new()
	_bless_button.text = "Offer to the Shrine — random blessing  (%d g)" % BLESSING_COST
	_bless_button.pressed.connect(_on_offer)
	vbox.add_child(_bless_button)

	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 15)
	_result_label.add_theme_color_override("font_color", Color(0.55, 0.85, 0.55))
	vbox.add_child(_result_label)

	vbox.add_child(HSeparator.new())

	var leave: Button = Button.new()
	leave.text = "Leave  (Esc)"
	leave.pressed.connect(_close)
	vbox.add_child(leave)


# ---------------------------------------------------------------------------
# Choices
# ---------------------------------------------------------------------------

func _on_pray() -> void:
	if _spent:
		return
	if not RunStats.spend_gold(HEAL_COST):
		_flash_denied(_heal_button)
		return
	_player.heal(_player.max_hp)
	_finish("The shrine restores your body to full.")


func _on_offer() -> void:
	if _spent:
		return
	if not RunStats.spend_gold(BLESSING_COST):
		_flash_denied(_bless_button)
		return
	var pool: Array = _blessings()
	var boon: Dictionary = pool[randi() % pool.size()]
	boon["apply"].call()
	_finish("Blessing granted: %s (%s)." % [boon["name"], boon["desc"]])


func _finish(message: String) -> void:
	_spent = true
	_result_label.text = message
	_heal_button.disabled = true
	_bless_button.disabled = true


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _flash_denied(button: Button) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.6, 0.4, 0.4, 1.0), 0.0)
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.35)


func _refresh_gold() -> void:
	if _gold_label != null:
		_gold_label.text = "Gold: %d" % RunStats.gold


func _refresh_affordability() -> void:
	if _spent:
		return
	if _heal_button != null:
		# Also disable heal when already at full HP — nothing to gain.
		var full: bool = _player != null and _player.current_hp >= _player.max_hp
		_heal_button.disabled = RunStats.gold < HEAL_COST or full
	if _bless_button != null:
		_bless_button.disabled = RunStats.gold < BLESSING_COST


func _on_gold_changed(_current: int) -> void:
	_refresh_gold()
	_refresh_affordability()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	if RunStats.gold_changed.is_connected(_on_gold_changed):
		RunStats.gold_changed.disconnect(_on_gold_changed)
	get_tree().paused = false
	emit_signal("closed")
	queue_free()
