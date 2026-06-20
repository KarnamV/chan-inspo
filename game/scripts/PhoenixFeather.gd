extends "res://scripts/Talisman.gd"

# ---------------------------------------------------------------------------
# PhoenixFeather.gd — Heal 20% of MAX_HP immediately on activation.
#
# Cost: 40 spirit.
# Note: The base SPIRIT_COST_TALISMAN is 30. PhoenixFeather overrides the
# cost to 40 via a constant that Player.gd checks before calling activate().
# ---------------------------------------------------------------------------

const DISPLAY_NAME:  String = "Phoenix Feather"
const HEAL_FRACTION: float  = 0.20

# Player.gd reads this constant (if it exists) instead of SPIRIT_COST_TALISMAN
# to determine the activation cost for the currently selected talisman.
const SPIRIT_COST: float = 40.0


func talisman_display_name() -> String:
	return DISPLAY_NAME


func activate(player: Node) -> void:
	var heal_amount: int = int(player.MAX_HP * HEAL_FRACTION)
	var old_hp: int = player.current_hp
	player.current_hp = mini(player.current_hp + heal_amount, player.MAX_HP)
	var actual_heal: int = player.current_hp - old_hp
	player.emit_signal("health_updated", player.current_hp, player.MAX_HP)
	_flash(player)
	print("[PhoenixFeather] Healed %d HP (%d -> %d)." % [actual_heal, old_hp, player.current_hp])


func deactivate(_player: Node) -> void:
	pass


# ---------------------------------------------------------------------------
# Internal
# ---------------------------------------------------------------------------

func _flash(player: Node) -> void:
	var sprite: Node = player.get_node_or_null("Sprite2D")
	if sprite == null:
		return
	# Warm orange-gold heal flash.
	var tween: Tween = player.create_tween()
	tween.tween_property(sprite, "modulate", Color(3.0, 2.0, 0.5, 1.0), 0.0)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.8, 0.3, 1.0), 0.20)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.20)
