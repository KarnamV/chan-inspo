extends "res://scripts/Talisman.gd"

# ---------------------------------------------------------------------------
# SnakeCoil.gd — Chain lightning: on the NEXT hit, damage also jumps to up
# to 2 nearby enemies within CHAIN_RADIUS pixels, dealing 50% of the hit damage.
#
# The flag player.snake_coil_active is read in Player._on_hitbox_body_entered.
# After the chain fires (or if no enemies are in range), the flag is cleared.
#
# Cost: 35 spirit (via talisman-specific SPIRIT_COST override).
# ---------------------------------------------------------------------------

const DISPLAY_NAME:  String = "Snake Coil"
const CHAIN_RADIUS:  float  = 200.0
const CHAIN_DAMAGE_FRACTION: float = 0.50
const MAX_CHAIN_TARGETS: int = 2

const SPIRIT_COST: float = 35.0


func talisman_display_name() -> String:
	return DISPLAY_NAME


func activate(player: Node) -> void:
	player.snake_coil_active = true
	_flash(player)
	print("[SnakeCoil] Armed — next hit chains to up to %d nearby enemies (%.0f%% dmg, r=%.0fpx)." \
			% [MAX_CHAIN_TARGETS, CHAIN_DAMAGE_FRACTION * 100.0, CHAIN_RADIUS])


func deactivate(player: Node) -> void:
	player.snake_coil_active = false


# ---------------------------------------------------------------------------
# Chain logic — called by Player._on_hitbox_body_entered when snake_coil_active
# is true. Finds up to MAX_CHAIN_TARGETS enemies near hit_target (excluding it),
# calls their take_damage(), clears the flag.
#
# player     — the Player node (has the enemies accessible via its scene parent)
# hit_target — the Node2D that was directly hit (already took full damage)
# damage     — the damage the primary target received
# ---------------------------------------------------------------------------

func fire_chain(player: Node, hit_target: Node2D, damage: int) -> void:
	player.snake_coil_active = false
	var chain_dmg: int = maxi(1, int(damage * CHAIN_DAMAGE_FRACTION))

	# Walk up to the scene root to find all enemies.  We look for nodes that
	# expose take_damage() and are CharacterBody2D, within CHAIN_RADIUS of the
	# primary target.
	var candidates: Array = []
	var root: Node = player.get_tree().get_root()

	_collect_enemies(root, hit_target, candidates)

	# Sort by distance to the primary target and take the closest.
	candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.distance_to(hit_target.global_position) \
			 < b.global_position.distance_to(hit_target.global_position)
	)

	var chained: int = 0
	for enemy in candidates:
		if chained >= MAX_CHAIN_TARGETS:
			break
		enemy.take_damage(chain_dmg)
		chained += 1
		print("[SnakeCoil] Chain -> %s for %d dmg." % [enemy.name, chain_dmg])

	if chained == 0:
		print("[SnakeCoil] No chain targets in range.")


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

func _collect_enemies(node: Node, hit_target: Node2D, out: Array) -> void:
	# Recursively search for CharacterBody2D nodes that:
	# - are not the hit_target
	# - expose take_damage()
	# - are within CHAIN_RADIUS of the hit_target
	if node is CharacterBody2D and node != hit_target and node.has_method("take_damage"):
		var dist: float = (node as Node2D).global_position.distance_to(hit_target.global_position)
		if dist <= CHAIN_RADIUS:
			out.append(node)
	for child in node.get_children():
		_collect_enemies(child, hit_target, out)


func _flash(player: Node) -> void:
	var sprite: Node = player.get_node_or_null("Sprite2D")
	if sprite == null:
		return
	# Cyan-electric flash.
	var tween: Tween = player.create_tween()
	tween.tween_property(sprite, "modulate", Color(0.5, 3.0, 3.0, 1.0), 0.0)
	tween.tween_property(sprite, "modulate", Color(0.3, 1.0, 1.2, 1.0), 0.15)
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)
