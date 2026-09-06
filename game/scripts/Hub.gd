## Hub.gd — Post-death hub screen.
##
## Reads RunStats (AutoLoad) and displays the run summary.
## Two buttons: "New Run" (resets stats, reloads TestRoom) and "Quit".

extends Control

const RealmDefs = preload("res://scripts/RealmDefs.gd")

@onready var title_label:          Label  = $VBox/TitleLabel
@onready var rooms_label:          Label  = $VBox/Stats/RoomsLabel
@onready var enemies_label:        Label  = $VBox/Stats/EnemiesLabel
@onready var spirit_label:         Label  = $VBox/Stats/SpiritLabel
@onready var shards_label:         Label  = $VBox/Stats/ShardsLabel
@onready var new_run_button:       Button = $VBox/Buttons/NewRunButton
@onready var quit_button:          Button = $VBox/Buttons/QuitButton


func _ready() -> void:
	# Populate run summary from the RunStats singleton.
	rooms_label.text   = "Rooms visited:    %d"   % RunStats.rooms_visited
	enemies_label.text = "Enemies defeated: %d"   % RunStats.enemies_killed
	spirit_label.text  = "Spirit collected: %d"   % int(RunStats.spirit_collected)
	shards_label.text  = "Spirit Shards earned: %d" % RunStats.spirit_shards_earned()

	# Gold is run-only (lost on death) — show what the run generated. Label is
	# created in code so the Hub scene file stays unchanged.
	var gold_line: Label = shards_label.duplicate()
	gold_line.name = "GoldLabel"
	gold_line.text = "Gold earned:      %d" % RunStats.gold_earned
	var stats: Node = shards_label.get_parent()
	stats.add_child(gold_line)
	stats.move_child(gold_line, shards_label.get_index() + 1)

	# Persistent Spirit Shard bank (survives across runs).
	var bank_line: Label = shards_label.duplicate()
	bank_line.name = "ShardBankLabel"
	bank_line.text = "Spirit Shards (bank): %d" % MetaProgress.total_shards
	stats.add_child(bank_line)
	stats.move_child(bank_line, gold_line.get_index() + 1)

	new_run_button.pressed.connect(_on_new_run_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	_build_upgrade_menu()
	_build_realm_menu()

	# Grab focus on the primary button so keyboard navigation works immediately.
	new_run_button.grab_focus()


# ---------------------------------------------------------------------------
# Realm selection — pick which realm the next run starts in. Unlocked realms
# only; beating a realm's boss unlocks the next (MetaProgress.max_realm_unlocked).
# ---------------------------------------------------------------------------

var _realm_buttons: Array = []


func _build_realm_menu() -> void:
	var panel: Panel = Panel.new()
	panel.name = "RealmPanel"
	panel.size = Vector2(360, 544)
	panel.position = Vector2(24, 88)
	add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.text = "Select Realm"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	for i in RealmDefs.count():
		var btn: Button = Button.new()
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var idx: int = i
		btn.pressed.connect(func() -> void: _on_select_realm(idx))
		vbox.add_child(btn)
		_realm_buttons.append(btn)

	_refresh_realms()


func _on_select_realm(index: int) -> void:
	MetaProgress.select_realm(index)
	_refresh_realms()


func _refresh_realms() -> void:
	for i in _realm_buttons.size():
		var btn: Button = _realm_buttons[i]
		var unlocked: bool = MetaProgress.is_realm_unlocked(i)
		var marker: String = "  ◄" if MetaProgress.selected_realm == i else ""
		if unlocked:
			btn.text = "%d.  %s%s" % [i + 1, RealmDefs.realm_name(i), marker]
			btn.disabled = false
		else:
			btn.text = "%d.  %s   \U0001F512" % [i + 1, RealmDefs.realm_name(i)]
			btn.disabled = true


# ---------------------------------------------------------------------------
# Perma-upgrade menu — spend banked Spirit Shards on permanent perks.
# Built in code so Hub.tscn stays unchanged. Applied to each run by
# TestRoom._apply_meta_upgrades().
# ---------------------------------------------------------------------------

const UPGRADE_KEYS: Array = ["max_hp", "damage", "speed", "slots"]

var _shard_label: Label = null
# Each entry: { "key": String, "level": Label, "cost": Label, "button": Button }
var _upgrade_rows: Array = []


func _build_upgrade_menu() -> void:
	var panel: Panel = Panel.new()
	panel.name = "UpgradePanel"
	panel.size = Vector2(400, 544)
	panel.position = Vector2(858, 88)
	add_child(panel)

	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title: Label = Label.new()
	title.text = "Perma-Upgrades"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	_shard_label = Label.new()
	_shard_label.add_theme_font_size_override("font_size", 16)
	_shard_label.add_theme_color_override("font_color", Color(0.90, 0.72, 0.10))
	vbox.add_child(_shard_label)

	vbox.add_child(HSeparator.new())

	for key in UPGRADE_KEYS:
		vbox.add_child(_build_upgrade_row(key))

	_refresh_upgrades()


func _build_upgrade_row(key: String) -> Control:
	var row: VBoxContainer = VBoxContainer.new()
	row.add_theme_constant_override("separation", 2)

	var name_label: Label = Label.new()
	name_label.text = MetaProgress.UPGRADE_LABELS.get(key, key)
	name_label.add_theme_font_size_override("font_size", 14)
	row.add_child(name_label)

	var line: HBoxContainer = HBoxContainer.new()
	line.add_theme_constant_override("separation", 10)

	var level_label: Label = Label.new()
	level_label.add_theme_font_size_override("font_size", 13)
	level_label.add_theme_color_override("font_color", Color(0.72, 0.68, 0.62))
	level_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(level_label)

	var cost_label: Label = Label.new()
	cost_label.add_theme_font_size_override("font_size", 13)
	cost_label.add_theme_color_override("font_color", Color(0.90, 0.72, 0.10))
	line.add_child(cost_label)

	var buy: Button = Button.new()
	buy.text = "Buy"
	buy.custom_minimum_size = Vector2(70, 0)
	buy.pressed.connect(func() -> void: _on_buy_upgrade(key))
	line.add_child(buy)

	row.add_child(line)

	_upgrade_rows.append({ "key": key, "level": level_label, "cost": cost_label, "button": buy })
	return row


func _on_buy_upgrade(key: String) -> void:
	if MetaProgress.buy_upgrade(key):
		_refresh_upgrades()


func _refresh_upgrades() -> void:
	_shard_label.text = "Spirit Shards: %d" % MetaProgress.total_shards
	for row in _upgrade_rows:
		var key: String = row["key"]
		var lvl: int = MetaProgress.upgrade_level(key)
		var maxl: int = MetaProgress.upgrade_max(key)
		row["level"].text = "Lv %d / %d" % [lvl, maxl]
		if MetaProgress.is_maxed(key):
			row["cost"].text = "MAX"
			row["button"].disabled = true
		else:
			row["cost"].text = "%d sh" % MetaProgress.upgrade_cost(key)
			row["button"].disabled = not MetaProgress.can_buy_upgrade(key)


func _on_new_run_pressed() -> void:
	# Reset all run stats before the scene loads so TestRoom starts clean.
	RunStats.reset()
	get_tree().change_scene_to_file("res://scenes/TestRoom.tscn")


func _on_quit_pressed() -> void:
	get_tree().quit()
