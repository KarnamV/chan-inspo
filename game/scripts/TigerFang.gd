extends "res://scripts/Talisman.gd"

# ---------------------------------------------------------------------------
# TigerFang.gd — Dodge counter: for 3 seconds after a successful dodge roll
# completes, the NEXT attack deals 2x damage.
#
# Activation (E key): arms the talisman. The next dodge roll triggers a 3-second
# window. During that window player.tiger_fang_ready = true, which Player.gd
# reads when a hit connects to double the damage (then clears the flag).
#
# Cost: 25 spirit (via talisman-specific SPIRIT_COST override).
# ---------------------------------------------------------------------------

const DISPLAY_NAME:    String = "Tiger Fang"
const DAMAGE_MULT:     float  = 2.0
const WINDOW_DURATION: float  = 3.0

# Lower cost than the default 30 sp.
const SPIRIT_COST: float = 25.0

# Internal state.
var _armed:        bool  = false   # set true by activate(); cleared once dodge fires or expires
var _window_timer: float = 0.0     # counts down the active window
var _player_ref:   Node  = null


func talisman_display_name() -> String:
	return DISPLAY_NAME


func activate(player: Node) -> void:
	_armed = true
	_window_timer = 0.0
	_player_ref = player
	# Ensure the ready flag is cleared until the next dodge completes.
	player.tiger_fang_ready = false
	_flash(player, Color(3.0, 2.0, 0.4, 1.0), Color(1.0, 0.7, 0.1, 1.0))
	print("[TigerFang] Armed — next dodge opens a %.0fs damage window." % WINDOW_DURATION)


func deactivate(player: Node) -> void:
	_armed = false
	_window_timer = 0.0
	player.tiger_fang_ready = false


# ---------------------------------------------------------------------------
# Per-frame: poll the player's dodge state so we can detect when a dodge roll
# begins and then completes.  We track the dodge ourselves rather than hooking
# a signal (Player doesn't currently emit one for dodge end).
# ---------------------------------------------------------------------------

var _was_dodging: bool = false

func _process(delta: float) -> void:
	if _player_ref == null:
		return

	# --- Arm phase: waiting for a dodge roll to start --------------------
	if _armed:
		var is_dodging: bool = (_player_ref.state == 3)   # State.DODGE == 3
		if _was_dodging and not is_dodging:
			# Dodge roll just finished. Open the counter window.
			_armed = false
			_window_timer = WINDOW_DURATION
			_player_ref.tiger_fang_ready = true
			_flash(_player_ref, Color(2.5, 1.2, 0.0, 1.0), Color(1.0, 0.6, 0.0, 1.0))
			print("[TigerFang] Dodge complete — %.0fs counter window open." % WINDOW_DURATION)
		_was_dodging = is_dodging
		return

	# --- Counter window active -------------------------------------------
	if _window_timer > 0.0:
		_window_timer -= delta
		if _window_timer <= 0.0:
			# Window expired without a hit connecting.
			_window_timer = 0.0
			_player_ref.tiger_fang_ready = false
			print("[TigerFang] Counter window expired.")


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _flash(player: Node, start_color: Color, mid_color: Color) -> void:
	var sprite: Node = player.get_node_or_null("Sprite2D")
	if sprite == null:
		return
	var tween: Tween = player.create_tween()
	tween.tween_property(sprite, "modulate", start_color, 0.0)
	tween.tween_property(sprite, "modulate", mid_color,   0.15)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
