extends "res://scripts/Talisman.gd"

# ---------------------------------------------------------------------------
# DemonSeal.gd — Absorb one hit, then explode.
#
# On activation, arms player.demon_seal_active. The next incoming hit is fully
# absorbed (no damage/knockback) by Player.take_hit, which then calls back into
# demon_seal_explode() to damage all enemies within BLAST_RADIUS of the player.
# Cost: 30 spirit.
# ---------------------------------------------------------------------------

const DISPLAY_NAME: String = "Demon Seal"
const SPIRIT_COST:  float  = 30.0
const BLAST_RADIUS: float  = 190.0
const BLAST_DAMAGE: int    = 60


func talisman_display_name() -> String:
	return DISPLAY_NAME


func activate(player: Node) -> void:
	player.demon_seal_active = true
	_flash(player, Color(1.4, 0.3, 1.4, 1.0))


func deactivate(player: Node) -> void:
	player.demon_seal_active = false


# Called by Player.take_hit when the seal absorbs a hit.
func demon_seal_explode(player: Node) -> void:
	var enemies: Array = []
	_collect(player.get_tree().get_root(), player, enemies)
	for e in enemies:
		e.take_damage(BLAST_DAMAGE)
	print("[DemonSeal] Absorbed a hit and detonated — %d enemies caught." % enemies.size())
	_flash(player, Color(2.0, 0.4, 2.0, 1.0))


func _collect(node: Node, player: Node, out: Array) -> void:
	if node is CharacterBody2D and node != player and node.has_method("take_damage"):
		var d: float = (node as Node2D).global_position.distance_to(player.global_position)
		if d <= BLAST_RADIUS:
			out.append(node)
	for c in node.get_children():
		_collect(c, player, out)


func _flash(player: Node, color: Color) -> void:
	var sprite: Node = player.get_node_or_null("Sprite2D")
	if sprite == null:
		return
	var tween: Tween = player.create_tween()
	tween.tween_property(sprite, "modulate", color, 0.0)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.25)
