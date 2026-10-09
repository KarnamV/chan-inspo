extends CanvasLayer

# ---------------------------------------------------------------------------
# HUD.gd — Heads-up display for Demon Realm Escape.
#
# Displays three meters, all wired via signals from Player:
#   HP bar     — health_updated(current: int, max_hp: int)
#   Spirit bar — spirit_updated(current: float, max_val: float)
#   Combo      — combo_updated(count: int)
#
# Usage (from TestRoom._ready):
#   hud.connect_player(player)
# ---------------------------------------------------------------------------

# Width of each meter bar (pixels). Fill nodes are tweened to BAR_WIDTH * ratio.
const BAR_WIDTH: float = 200.0

@onready var hp_bar_fill:  ColorRect = $VBox/HPRow/HPBarBG/HPBarFill
@onready var hp_label:     Label     = $VBox/HPRow/HPLabel

@onready var spirit_bar_fill: ColorRect = $VBox/SpiritRow/SpiritBarBG/SpiritBarFill
@onready var spirit_label:    Label     = $VBox/SpiritRow/SpiritLabel

@onready var combo_label:    Label = $VBox/ComboLabel
@onready var talisman_label: Label = $VBox/TalismanLabel

# Gold label is created in code and inserted into VBox (kept out of the .tscn
# so the scene stays as-is). Driven by the RunStats.gold_changed signal.
var gold_label: Label = null

# Track last tween for combo pop so we can cancel it on reset.
var _combo_tween: Tween = null


func _ready() -> void:
	# Ensure bars start at max visually (player emits on first hit).
	_set_bar_fill(hp_bar_fill, 1.0)
	_set_bar_fill(spirit_bar_fill, 0.0)
	combo_label.text = "x0"
	combo_label.modulate.a = 0.0   # invisible until first hit
	talisman_label.text = ""

	_build_gold_label()

	# RunStats is an AutoLoad — drive the gold label off its signal and prime it
	# with the current balance (survives scene reloads within a run).
	RunStats.gold_changed.connect(_on_gold_changed)
	_on_gold_changed(RunStats.gold)


func _build_gold_label() -> void:
	gold_label = Label.new()
	gold_label.name = "GoldLabel"
	if combo_label.label_settings != null:
		# Reuse the small bar label styling for readability against the floor.
		gold_label.label_settings = talisman_label.label_settings
	var vbox: VBoxContainer = $VBox
	vbox.add_child(gold_label)
	# Place it just under the bars, above the combo counter.
	vbox.move_child(gold_label, talisman_label.get_index())


# Call this from the owning scene after the player node is ready.
func connect_player(player: CharacterBody2D) -> void:
	player.health_updated.connect(_on_health_updated)
	player.spirit_updated.connect(_on_spirit_updated)
	player.combo_updated.connect(_on_combo_updated)


# Call this from TalismanManager.active_talisman_changed signal.
func set_active_talisman_name(display_name: String) -> void:
	talisman_label.text = display_name


# ---------------------------------------------------------------------------
# Signal handlers
# ---------------------------------------------------------------------------

func _on_health_updated(current: int, max_hp: int) -> void:
	var ratio: float = float(current) / float(max_hp) if max_hp > 0 else 0.0
	_tween_bar(hp_bar_fill, ratio)
	hp_label.text = "HP  %d / %d" % [current, max_hp]


func _on_spirit_updated(current: float, max_val: float) -> void:
	var ratio: float = current / max_val if max_val > 0.0 else 0.0
	_tween_bar(spirit_bar_fill, ratio)
	spirit_label.text = "SP  %d / %d" % [int(current), int(max_val)]


func _on_gold_changed(current: int) -> void:
	if gold_label != null:
		gold_label.text = "Gold  %d" % current


func _on_combo_updated(count: int) -> void:
	combo_label.text = "x%d" % count

	# Cancel any in-flight tween first.
	if _combo_tween != null and _combo_tween.is_valid():
		_combo_tween.kill()

	if count == 0:
		# Fade out the counter when combo resets.
		_combo_tween = create_tween()
		_combo_tween.tween_property(combo_label, "modulate:a", 0.0, 0.4)
	else:
		# Pop scale 1.4 → 1.0 and ensure fully visible.
		combo_label.modulate.a = 1.0
		combo_label.scale = Vector2(1.4, 1.4)
		_combo_tween = create_tween()
		_combo_tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.15) \
				.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Animate the bar fill width. ratio is clamped to [0, 1].
func _tween_bar(fill: ColorRect, ratio: float) -> void:
	ratio = clampf(ratio, 0.0, 1.0)
	var target_w: float = BAR_WIDTH * ratio
	var tw: Tween = create_tween()
	tw.tween_property(fill, "size:x", target_w, 0.15).set_trans(Tween.TRANS_SINE)


# Set bar fill width instantly (no tween) — used during _ready.
func _set_bar_fill(fill: ColorRect, ratio: float) -> void:
	fill.size.x = BAR_WIDTH * clampf(ratio, 0.0, 1.0)
