## TemptationUI.gd — the cursed-power-up overlay for TEMPTATION rooms.
##
## Same code-built, pause-the-game pattern as ShopUI/ShrineUI. The player risks
## gold and/or Spirit Shards for a powerful pact that always carries a curse.
## One pact per room; they may also refuse and leave untouched.

class_name TemptationUI
extends CanvasLayer

signal closed

const PANEL_SIZE: Vector2 = Vector2(600.0, 480.0)

var _player: Node = null

var _cost_label: Label = null
var _result_label: Label = null
var _taken: bool = false
# Each entry: { "def": Dictionary, "button": Button }
var _rows: Array = []


func open(player: Node) -> void:
	_player = player
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build_ui()

	RunStats.gold_changed.connect(_on_currency_changed)
	MetaProgress.shards_changed.connect(_on_currency_changed)
	_refresh_costs()
	_refresh_affordability()

	get_tree().paused = true


# ---------------------------------------------------------------------------
# Cursed pacts — each has a powerful boon and a matching curse.
# ---------------------------------------------------------------------------

func _pacts() -> Array:
	return [
		{
			"name": "Reckless Might",
			"boon": "+30% damage",
			"curse": "-25% Max HP",
			"gold": 15, "shards": 0,
			"apply": func() -> void:
				_player.permanent_damage_mult *= 1.30
				_player.modify_max_hp(-int(_player.max_hp * 0.25)),
		},
		{
			"name": "Hollow Speed",
			"boon": "+20% move speed, +15% damage",
			"curse": "-20% Max HP",
			"gold": 25, "shards": 0,
			"apply": func() -> void:
				_player.speed_run *= 1.20
				_player.speed_walk *= 1.20
				_player.permanent_damage_mult *= 1.15
				_player.modify_max_hp(-int(_player.max_hp * 0.20)),
		},
		{
			"name": "Soul Barter",
			"boon": "+50 Max HP, heal to full",
			"curse": "-20% damage",
			"gold": 0, "shards": 2,
			"apply": func() -> void:
				_player.modify_max_hp(50)
				_player.heal(_player.max_hp)
				_player.permanent_damage_mult *= 0.80,
		},
	]


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.10, 0.0, 0.10, 0.6)
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
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.text = "☠  Temptation"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(1.0, 0.4, 0.9))
	vbox.add_child(title)

	var flavor: Label = Label.new()
	flavor.text = "Power always has a price. Take one pact — or refuse."
	flavor.add_theme_font_size_override("font_size", 13)
	flavor.add_theme_color_override("font_color", Color(0.75, 0.66, 0.75))
	vbox.add_child(flavor)

	_cost_label = Label.new()
	_cost_label.add_theme_font_size_override("font_size", 14)
	_cost_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.25))
	vbox.add_child(_cost_label)

	vbox.add_child(HSeparator.new())

	for def in _pacts():
		vbox.add_child(_build_pact_row(def))

	_result_label = Label.new()
	_result_label.add_theme_font_size_override("font_size", 15)
	_result_label.add_theme_color_override("font_color", Color(1.0, 0.55, 0.85))
	vbox.add_child(_result_label)

	vbox.add_child(HSeparator.new())

	var leave: Button = Button.new()
	leave.text = "Refuse and leave  (Esc)"
	leave.pressed.connect(_close)
	vbox.add_child(leave)


func _build_pact_row(def: Dictionary) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label: Label = Label.new()
	name_label.text = def["name"]
	name_label.add_theme_font_size_override("font_size", 16)
	info.add_child(name_label)

	var boon_label: Label = Label.new()
	boon_label.text = "Boon:  %s" % def["boon"]
	boon_label.add_theme_font_size_override("font_size", 12)
	boon_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.6))
	info.add_child(boon_label)

	var curse_label: Label = Label.new()
	curse_label.text = "Curse: %s" % def["curse"]
	curse_label.add_theme_font_size_override("font_size", 12)
	curse_label.add_theme_color_override("font_color", Color(1.0, 0.45, 0.45))
	info.add_child(curse_label)

	row.add_child(info)

	var price_label: Label = Label.new()
	price_label.text = _cost_text(def)
	price_label.add_theme_font_size_override("font_size", 14)
	price_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.25))
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(price_label)

	var take: Button = Button.new()
	take.text = "Take"
	take.custom_minimum_size = Vector2(80, 0)
	var index: int = _rows.size()
	take.pressed.connect(func() -> void: _try_take(index))
	row.add_child(take)

	_rows.append({ "def": def, "button": take })
	return row


func _cost_text(def: Dictionary) -> String:
	var parts: Array = []
	if def["gold"] > 0:
		parts.append("%d g" % def["gold"])
	if def["shards"] > 0:
		parts.append("%d sh" % def["shards"])
	return "  ".join(parts) if parts.size() > 0 else "free"


# ---------------------------------------------------------------------------
# Take a pact
# ---------------------------------------------------------------------------

func _try_take(index: int) -> void:
	if _taken:
		return
	var def: Dictionary = _rows[index]["def"]

	if not _can_afford(def):
		_flash_denied(_rows[index]["button"])
		return

	# Deduct gold then shards (both already checked affordable).
	RunStats.spend_gold(def["gold"])
	MetaProgress.spend_shards(def["shards"])

	def["apply"].call()
	AudioManager.play_sfx("purchase")

	_taken = true
	_result_label.text = "You take %s. %s, but %s." % [def["name"], def["boon"], def["curse"]]
	for row in _rows:
		row["button"].disabled = true

	_refresh_costs()


func _can_afford(def: Dictionary) -> bool:
	return RunStats.gold >= def["gold"] and MetaProgress.total_shards >= def["shards"]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _flash_denied(button: Button) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.6, 0.4, 0.4, 1.0), 0.0)
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.35)


func _refresh_costs() -> void:
	if _cost_label != null:
		_cost_label.text = "Gold: %d      Spirit Shards: %d" % [RunStats.gold, MetaProgress.total_shards]


func _refresh_affordability() -> void:
	if _taken:
		return
	for row in _rows:
		row["button"].disabled = not _can_afford(row["def"])


func _on_currency_changed(_v: int) -> void:
	_refresh_costs()
	_refresh_affordability()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		_close()


func _close() -> void:
	if RunStats.gold_changed.is_connected(_on_currency_changed):
		RunStats.gold_changed.disconnect(_on_currency_changed)
	if MetaProgress.shards_changed.is_connected(_on_currency_changed):
		MetaProgress.shards_changed.disconnect(_on_currency_changed)
	get_tree().paused = false
	emit_signal("closed")
	queue_free()
