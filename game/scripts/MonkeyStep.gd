extends "res://scripts/Talisman.gd"

# ---------------------------------------------------------------------------
# MonkeyStep.gd — Extra dodge-dash + faster reposition.
#
# On activation: performs an immediate dodge roll in the facing direction and
# grants a short move-speed boost so the player can reposition quickly.
# Cost: 15 spirit.
# ---------------------------------------------------------------------------

const DISPLAY_NAME: String = "Monkey Step"
const SPIRIT_COST:  float  = 15.0
const BOOST_MULT:   float  = 1.6
const BOOST_TIME:   float  = 3.0

var _player_ref: Node = null
var _timer: float = 0.0
var _active: bool = false
var _base_run: float = 0.0
var _base_walk: float = 0.0


func talisman_display_name() -> String:
	return DISPLAY_NAME


func activate(player: Node) -> void:
	_player_ref = player

	# Immediate extra dodge (State.DODGE == 3 means already dodging — skip then).
	if player.has_method("dodge_roll") and player.state != 3:
		player.dodge_roll(player.facing_dir)

	# Temporary speed boost. Capture the base only on the first (re)activation so
	# repeated presses refresh the timer without compounding the multiplier.
	if not _active:
		_base_run = player.speed_run
		_base_walk = player.speed_walk
		player.speed_run *= BOOST_MULT
		player.speed_walk *= BOOST_MULT
		_active = true
	_timer = BOOST_TIME
	_flash(player)


func deactivate(player: Node) -> void:
	_restore()


func _process(delta: float) -> void:
	if not _active:
		return
	_timer -= delta
	if _timer <= 0.0:
		_restore()


func _restore() -> void:
	if _active and _player_ref != null:
		_player_ref.speed_run = _base_run
		_player_ref.speed_walk = _base_walk
	_active = false
	_timer = 0.0


func _flash(player: Node) -> void:
	var sprite: Node = player.get_node_or_null("Sprite2D")
	if sprite == null:
		return
	var tween: Tween = player.create_tween()
	tween.tween_property(sprite, "modulate", Color(1.6, 1.4, 0.6, 1.0), 0.0)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
