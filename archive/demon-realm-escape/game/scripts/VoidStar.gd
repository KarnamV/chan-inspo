extends "res://scripts/Talisman.gd"

# ---------------------------------------------------------------------------
# VoidStar.gd — Blink teleport with an afterimage decoy.
#
# On activation, teleports the player TP_DIST pixels in the facing direction and
# leaves a fading translucent copy of the player's sprite at the old position.
# Cost: 20 spirit.
# ---------------------------------------------------------------------------

const DISPLAY_NAME: String = "Void Star"
const SPIRIT_COST:  float  = 20.0
const TP_DIST:      float  = 220.0


func talisman_display_name() -> String:
	return DISPLAY_NAME


func activate(player: Node) -> void:
	var old_pos: Vector2 = player.global_position
	_spawn_decoy(player, old_pos)

	var dir: Vector2 = player.facing_dir
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	player.global_position = old_pos + dir.normalized() * TP_DIST
	_flash(player)


func _spawn_decoy(player: Node, pos: Vector2) -> void:
	var decoy: Sprite2D = Sprite2D.new()
	var src: Node = player.get_node_or_null("Sprite2D")
	if src != null and src is Sprite2D and src.texture != null:
		decoy.texture = src.texture
		decoy.offset = src.offset
	decoy.global_position = pos
	decoy.modulate = Color(0.6, 0.4, 1.0, 0.7)
	# Add to the player's parent (the room) so it stays put as the player blinks.
	var parent: Node = player.get_parent()
	if parent == null:
		return
	parent.add_child(decoy)

	var tween: Tween = decoy.create_tween()
	tween.tween_property(decoy, "modulate:a", 0.0, 1.2)
	tween.tween_callback(decoy.queue_free)


func _flash(player: Node) -> void:
	var sprite: Node = player.get_node_or_null("Sprite2D")
	if sprite == null:
		return
	var tween: Tween = player.create_tween()
	tween.tween_property(sprite, "modulate", Color(0.7, 0.5, 1.6, 1.0), 0.0)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.2)
