extends "res://scripts/Talisman.gd"

# ---------------------------------------------------------------------------
# HeavensToken.gd — Call a random power-up.
#
# On activation, grants one of several beneficial effects at random: a heal, a
# spirit refill, a small permanent damage boost, or extra Max HP. The spirit
# cost plus regen acts as the effective cooldown.
# Cost: 30 spirit.
# ---------------------------------------------------------------------------

const DISPLAY_NAME: String = "Heaven's Token"
const SPIRIT_COST:  float  = 30.0


func talisman_display_name() -> String:
	return DISPLAY_NAME


func activate(player: Node) -> void:
	match randi() % 4:
		0:
			player.heal(35)
			print("[HeavensToken] Boon: heal 35 HP.")
		1:
			player.spirit = player.SPIRIT_MAX
			player.emit_signal("spirit_updated", player.spirit, player.SPIRIT_MAX)
			print("[HeavensToken] Boon: spirit refilled.")
		2:
			player.permanent_damage_mult *= 1.08
			print("[HeavensToken] Boon: +8% permanent damage.")
		3:
			player.add_max_hp(15)
			print("[HeavensToken] Boon: +15 Max HP.")
	_flash(player)


func _flash(player: Node) -> void:
	var sprite: Node = player.get_node_or_null("Sprite2D")
	if sprite == null:
		return
	var tween: Tween = player.create_tween()
	tween.tween_property(sprite, "modulate", Color(2.0, 2.0, 1.4, 1.0), 0.0)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)
