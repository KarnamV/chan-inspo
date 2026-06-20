extends "res://scripts/Talisman.gd"

# ---------------------------------------------------------------------------
# DragonClaw.gd — Next attack after activation deals 3x damage and
# ignores the block counter-window (bypasses in_counter_window check).
#
# Duration: one hit only. The flag is cleared in Player._on_hitbox_body_entered.
# Cost: 30 spirit (handled by Player._unhandled_input via SPIRIT_COST_TALISMAN).
# ---------------------------------------------------------------------------

const DISPLAY_NAME: String = "Dragon Claw"
const DAMAGE_MULT:  float  = 3.0


func talisman_display_name() -> String:
	return DISPLAY_NAME


func activate(player: Node) -> void:
	# Set a flag that Player.gd reads when the next hit connects.
	player.dragon_claw_active = true
	_flash(player)
	print("[DragonClaw] Activated — next attack x%.0f, ignores block." % DAMAGE_MULT)


func deactivate(player: Node) -> void:
	player.dragon_claw_active = false


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _flash(player: Node) -> void:
	var sprite: Node = player.get_node_or_null("Sprite2D")
	if sprite == null:
		return
	# Brief red-gold flash.
	var tween: Tween = player.create_tween()
	tween.tween_property(sprite, "modulate", Color(3.0, 1.5, 0.3, 1.0), 0.0)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.5, 0.2, 1.0), 0.18)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.18)
