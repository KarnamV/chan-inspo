## GoldPickup.gd — a collectable gold coin dropped by defeated enemies.
##
## Fully code-built (no .tscn): draws itself as a small gold coin via _draw().
## Lifecycle:
##   1. SCATTER — on spawn, tweens outward to a random nearby offset with a
##      little pop, so a burst of coins fans out from the death position.
##   2. IDLE    — sits and bobs until the player comes within MAGNET_RANGE.
##   3. MAGNET  — homes toward the player, accelerating.
##   4. COLLECT — within COLLECT_RANGE: awards RunStats.add_gold(value),
##      plays a rise+fade, then frees itself.
##
## Instantiate via the preloaded script, set `value` + `global_position`, then
## add it to the room (see TestRoom._drop_gold).

class_name GoldPickup
extends Node2D

const MAGNET_RANGE:  float = 95.0    # player must be this close to attract the coin
const COLLECT_RANGE: float = 16.0    # awarded once this close
const MAGNET_ACCEL:  float = 900.0   # px/s^2 while homing
const MAGNET_MAX:    float = 520.0   # cap on homing speed
const RADIUS:        float = 7.0

## Gold this coin is worth.
var value: int = 1

var _player: Node2D = null
var _magnet_speed: float = 0.0
var _collected: bool = false
var _scattering: bool = true
var _bob_time: float = 0.0


func _ready() -> void:
	# Random z so overlapping coins don't shimmer; draw above the floor.
	z_index = 5
	_start_scatter()


func _start_scatter() -> void:
	# Fan out to a random offset with a brief pop, then settle.
	var offset: Vector2 = Vector2.RIGHT.rotated(randf() * TAU) * randf_range(14.0, 46.0)
	var target: Vector2 = global_position + offset
	scale = Vector2(0.2, 0.2)

	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "global_position", target, 0.28) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func() -> void: _scattering = false)


func _process(delta: float) -> void:
	if _collected or _scattering:
		# Gentle idle bob even while scattering finishes.
		_bob_time += delta
		return

	var p: Node2D = _get_player()
	if p == null:
		return

	var dist: float = global_position.distance_to(p.global_position)

	if dist <= COLLECT_RANGE:
		_collect()
		return

	if dist <= MAGNET_RANGE:
		# Home toward the player, accelerating up to the cap.
		_magnet_speed = minf(_magnet_speed + MAGNET_ACCEL * delta, MAGNET_MAX)
		var dir: Vector2 = (p.global_position - global_position).normalized()
		global_position += dir * _magnet_speed * delta
	else:
		# Idle bob when the player is out of range.
		_magnet_speed = 0.0
		_bob_time += delta
		position.y += sin(_bob_time * 4.0) * 6.0 * delta


func _collect() -> void:
	if _collected:
		return
	_collected = true
	RunStats.add_gold(value)

	# Rise + fade, then free.
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "position:y", position.y - 18.0, 0.22) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.22)
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.22)
	tween.chain().tween_callback(queue_free)


func _get_player() -> Node2D:
	if _player != null and is_instance_valid(_player):
		return _player
	var nodes: Array = get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		_player = nodes[0] as Node2D
	return _player


func _draw() -> void:
	# Coin body with a darker rim + a highlight for a bit of depth.
	draw_circle(Vector2.ZERO, RADIUS + 1.0, Color(0.45, 0.30, 0.05, 1.0))  # rim
	draw_circle(Vector2.ZERO, RADIUS, Color(0.95, 0.78, 0.20, 1.0))         # gold
	draw_circle(Vector2(-2.0, -2.0), 2.2, Color(1.0, 0.94, 0.6, 1.0))       # highlight
