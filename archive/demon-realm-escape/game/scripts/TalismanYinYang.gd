extends "res://scripts/Talisman.gd"

# ---------------------------------------------------------------------------
# TalismanYinYang.gd — Starter talisman for Phase 1.
#
# Toggles the player between two stances on each E-key press:
#
#   LIGHT (default)
#     attack speed  × 0.75  (faster — lower recovery times)
#     attack damage × 0.85  (slightly weaker hits)
#     sprite tint   → bright white-gold  Color(1.2, 1.1, 0.8)
#
#   DARK
#     attack speed  × 1.30  (slower)
#     attack damage × 1.35  (harder hits)
#     sprite tint   → deep purple-red   Color(0.9, 0.4, 1.0)
#
# The stance label is owned by TestRoom (not this node) so Player.tscn stays
# reusable. TestRoom connects to the stance_changed signal to update the label.
# ---------------------------------------------------------------------------

enum Stance { LIGHT, DARK }

signal stance_changed(new_stance: Stance)

# Stat multipliers per stance --------------------------------------------------
const LIGHT_SPEED_MULT:  float = 0.75
const LIGHT_DAMAGE_MULT: float = 0.85
const DARK_SPEED_MULT:   float = 1.30
const DARK_DAMAGE_MULT:  float = 1.35

# Sprite tints ----------------------------------------------------------------
const LIGHT_TINT: Color = Color(1.2, 1.1, 0.8)
const DARK_TINT:  Color = Color(0.9, 0.4, 1.0)

# Flash colour briefly shown at the moment of switching ----------------------
const FLASH_TINT: Color = Color(2.5, 2.5, 2.5)  # white overexpose

var current_stance: Stance = Stance.LIGHT


# ---------------------------------------------------------------------------
# Talisman interface
# ---------------------------------------------------------------------------

func activate(player: Node) -> void:
	if current_stance == Stance.LIGHT:
		_apply_stance(player, Stance.DARK)
	else:
		_apply_stance(player, Stance.LIGHT)


func deactivate(player: Node) -> void:
	# Remove talisman effects: reset multipliers and sprite tint to neutral.
	player.stance_speed_mult  = 1.0
	player.stance_damage_mult = 1.0
	var sprite: Node = player.get_node("Sprite2D")
	if sprite:
		sprite.modulate = Color.WHITE


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

func _apply_stance(player: Node, new_stance: Stance) -> void:
	current_stance = new_stance

	match new_stance:
		Stance.LIGHT:
			player.stance_speed_mult  = LIGHT_SPEED_MULT
			player.stance_damage_mult = LIGHT_DAMAGE_MULT
			_flash_and_tint(player, LIGHT_TINT)
		Stance.DARK:
			player.stance_speed_mult  = DARK_SPEED_MULT
			player.stance_damage_mult = DARK_DAMAGE_MULT
			_flash_and_tint(player, DARK_TINT)

	emit_signal("stance_changed", new_stance)


func _flash_and_tint(player: Node, target_tint: Color) -> void:
	var sprite: Node = player.get_node("Sprite2D")
	if not sprite:
		return

	# Brief white flash, then settle on the stance colour.
	var tween: Tween = player.create_tween()
	tween.tween_property(sprite, "modulate", FLASH_TINT, 0.0)
	tween.tween_property(sprite, "modulate", target_tint, 0.12)


# ---------------------------------------------------------------------------
# Helpers for external callers
# ---------------------------------------------------------------------------

func stance_display_text() -> String:
	return "☯ LIGHT" if current_stance == Stance.LIGHT else "☯ DARK"
