extends "res://scripts/Talisman.gd"

# ---------------------------------------------------------------------------
# CraneWing.gd — Parry stance: opens an extended counter window.
#
# On activation the player enters a ~2s "parry window" (player.in_counter_window
# = true). While it lasts, the next attack lands as a counter (1.5x damage — the
# same bonus the block-counter grants). Attacking consumes the window early.
# Cost: 20 spirit.
# ---------------------------------------------------------------------------

const DISPLAY_NAME: String = "Crane Wing"
const SPIRIT_COST:  float  = 20.0
const WINDOW:       float  = 2.0

var _player_ref: Node = null
var _timer: float = 0.0


func talisman_display_name() -> String:
	return DISPLAY_NAME


func activate(player: Node) -> void:
	_player_ref = player
	player.in_counter_window = true
	_timer = WINDOW
	_flash(player)


func deactivate(player: Node) -> void:
	_timer = 0.0


func _process(delta: float) -> void:
	if _timer <= 0.0 or _player_ref == null:
		return
	# If the player already attacked, the window was consumed — stop tracking.
	if not _player_ref.in_counter_window:
		_timer = 0.0
		return
	_timer -= delta
	if _timer <= 0.0:
		_player_ref.in_counter_window = false


func _flash(player: Node) -> void:
	var sprite: Node = player.get_node_or_null("Sprite2D")
	if sprite == null:
		return
	var tween: Tween = player.create_tween()
	tween.tween_property(sprite, "modulate", Color(0.9, 1.6, 1.9, 1.0), 0.0)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
