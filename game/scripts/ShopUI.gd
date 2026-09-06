## ShopUI.gd — the merchant overlay shown when the player enters a SHOP room.
##
## Fully code-built (no .tscn). Pauses the game while open (process_mode ALWAYS
## so its buttons still respond), lists items with gold prices, and spends gold
## via RunStats.spend_gold(). Emits `closed` when dismissed.
##
## Usage (see TestRoom._open_shop):
##   var shop := ShopUIScript.new()
##   add_child(shop)
##   shop.closed.connect(_on_shop_closed)
##   shop.open(player, talisman_manager)
##
## Stock: healing (repeatable), a Max-HP upgrade (repeatable), and two talismans
## not in the default loadout (one-time). "Info" items are a future addition.

class_name ShopUI
extends CanvasLayer

signal closed

const PANEL_SIZE: Vector2 = Vector2(560.0, 664.0)

# Talismans the merchant can sell (not in the starting loadout).
const SnakeCoilScript    = preload("res://scripts/SnakeCoil.gd")
const TigerFangScript    = preload("res://scripts/TigerFang.gd")
const MonkeyStepScript   = preload("res://scripts/MonkeyStep.gd")
const CraneWingScript    = preload("res://scripts/CraneWing.gd")
const DemonSealScript    = preload("res://scripts/DemonSeal.gd")
const VoidStarScript     = preload("res://scripts/VoidStar.gd")
const HeavensTokenScript = preload("res://scripts/HeavensToken.gd")

var _player: Node = null
var _talisman_manager: Node = null

var _gold_label: Label = null
# Each entry: { "def": Dictionary, "button": Button, "sold": bool }
var _rows: Array = []


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------

func open(player: Node, talisman_manager: Node) -> void:
	_player = player
	_talisman_manager = talisman_manager

	# Draw above the HUD (layer 10) and keep running while the tree is paused.
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS

	_build_ui()

	RunStats.gold_changed.connect(_on_gold_changed)
	_refresh_gold()
	_refresh_affordability()

	get_tree().paused = true


# ---------------------------------------------------------------------------
# Item catalogue
# ---------------------------------------------------------------------------

func _catalogue() -> Array:
	return [
		{
			"name": "Healing Draught",
			"desc": "Restore 40 HP",
			"price": 20,
			"one_time": false,
			"apply": func() -> void: _player.heal(40),
		},
		{
			"name": "Full Restore",
			"desc": "Heal to full HP",
			"price": 45,
			"one_time": false,
			"apply": func() -> void: _player.heal(_player.max_hp),
		},
		{
			"name": "Vitality Charm",
			"desc": "+25 Max HP (and heal 25)",
			"price": 55,
			"one_time": false,
			"apply": func() -> void: _player.add_max_hp(25),
		},
		{
			"name": "Tiger Fang Talisman",
			"desc": "Dodge-counter burst damage",
			"price": 70,
			"one_time": true,
			"apply": func() -> void: _buy_talisman(TigerFangScript),
		},
		{
			"name": "Snake Coil Talisman",
			"desc": "Next hit chains to nearby foes",
			"price": 80,
			"one_time": true,
			"apply": func() -> void: _buy_talisman(SnakeCoilScript),
		},
		{
			"name": "Monkey Step Talisman",
			"desc": "Extra dodge + speed burst",
			"price": 60,
			"one_time": true,
			"apply": func() -> void: _buy_talisman(MonkeyStepScript),
		},
		{
			"name": "Crane Wing Talisman",
			"desc": "Open a parry counter window",
			"price": 65,
			"one_time": true,
			"apply": func() -> void: _buy_talisman(CraneWingScript),
		},
		{
			"name": "Demon Seal Talisman",
			"desc": "Absorb a hit, then explode",
			"price": 95,
			"one_time": true,
			"apply": func() -> void: _buy_talisman(DemonSealScript),
		},
		{
			"name": "Void Star Talisman",
			"desc": "Blink teleport + decoy",
			"price": 70,
			"one_time": true,
			"apply": func() -> void: _buy_talisman(VoidStarScript),
		},
		{
			"name": "Heaven's Token Talisman",
			"desc": "Call a random power-up",
			"price": 110,
			"one_time": true,
			"apply": func() -> void: _buy_talisman(HeavensTokenScript),
		},
	]


func _buy_talisman(script: Script) -> void:
	# Instantiate the talisman, parent it to the player (talismans read/write
	# player flags), and register it with the manager (fills a free slot or
	# replaces the active one).
	var t: Node = script.new()
	t.name = script.resource_path.get_file().get_basename()
	_player.add_child(t)
	_talisman_manager.add_talisman(t)


# ---------------------------------------------------------------------------
# UI construction
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Full-screen dim that also blocks click-through to the game.
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.6)
	dim.size = Vector2(1280, 720)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# Centred panel.
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

	# Title.
	var title: Label = Label.new()
	title.text = "☯  Merchant"
	title.add_theme_font_size_override("font_size", 26)
	vbox.add_child(title)

	# Gold balance.
	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 16)
	_gold_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.25))
	vbox.add_child(_gold_label)

	vbox.add_child(HSeparator.new())

	# Item rows.
	for def in _catalogue():
		vbox.add_child(_build_row(def))

	vbox.add_child(HSeparator.new())

	# Leave button.
	var leave: Button = Button.new()
	leave.text = "Leave  (Esc)"
	leave.pressed.connect(_close)
	vbox.add_child(leave)


func _build_row(def: Dictionary) -> Control:
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	# Left: name + description, expands to push price/button right.
	var info: VBoxContainer = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var name_label: Label = Label.new()
	name_label.text = def["name"]
	name_label.add_theme_font_size_override("font_size", 16)
	info.add_child(name_label)
	var desc_label: Label = Label.new()
	desc_label.text = def["desc"]
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.7, 0.66, 0.6))
	info.add_child(desc_label)
	row.add_child(info)

	# Price.
	var price_label: Label = Label.new()
	price_label.text = "%d g" % def["price"]
	price_label.add_theme_font_size_override("font_size", 15)
	price_label.add_theme_color_override("font_color", Color(0.95, 0.82, 0.25))
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(price_label)

	# Buy button.
	var buy: Button = Button.new()
	buy.text = "Buy"
	buy.custom_minimum_size = Vector2(80, 0)
	var index: int = _rows.size()
	buy.pressed.connect(func() -> void: _try_buy(index))
	row.add_child(buy)

	_rows.append({ "def": def, "button": buy, "sold": false })
	return row


# ---------------------------------------------------------------------------
# Purchase flow
# ---------------------------------------------------------------------------

func _try_buy(index: int) -> void:
	var row: Dictionary = _rows[index]
	if row["sold"]:
		return
	var def: Dictionary = row["def"]

	if not RunStats.spend_gold(def["price"]):
		_flash_denied(row["button"])
		return

	def["apply"].call()

	if def["one_time"]:
		row["sold"] = true
		row["button"].text = "Sold"
		row["button"].disabled = true

	_refresh_gold()
	_refresh_affordability()


func _flash_denied(button: Button) -> void:
	# Brief red flash to signal "can't afford".
	var tween: Tween = create_tween()
	tween.tween_property(button, "modulate", Color(1.6, 0.4, 0.4, 1.0), 0.0)
	tween.tween_property(button, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.35)


func _refresh_gold() -> void:
	if _gold_label != null:
		_gold_label.text = "Gold: %d" % RunStats.gold


func _refresh_affordability() -> void:
	for row in _rows:
		if row["sold"]:
			continue
		row["button"].disabled = RunStats.gold < row["def"]["price"]


func _on_gold_changed(_current: int) -> void:
	_refresh_gold()
	_refresh_affordability()


# ---------------------------------------------------------------------------
# Close
# ---------------------------------------------------------------------------

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
