## EnemyBase.gd
## Base class for all enemy types. Extend this to implement specific enemies.
##
## Responsibilities:
##   - Shared stats: hp, speed, damage, detect_range, attack_range
##   - Shared death sequence: red flash → shrink+fade → queue_free
##   - take_damage(dmg): flash + kill check
##   - _get_player(): looks up the "player" group — returns null if not found
##   - enemy_died signal for room-clear tracking
##
## Navigation:
##   - Prefers NavigationAgent2D (path-avoidance) when it exists as a child.
##   - Falls back to a direct vector toward the player otherwise.
##   - Subclasses call _nav_velocity(delta) to get a movement vector.

class_name EnemyBase
extends CharacterBody2D

# ---------------------------------------------------------------------------
# Signal
# ---------------------------------------------------------------------------
signal enemy_died(enemy: Node)

# ---------------------------------------------------------------------------
# Exported stats — override per enemy type via @export or direct assignment
# in the subclass's _ready()
# ---------------------------------------------------------------------------
@export var max_hp:       int   = 40
@export var move_speed:   float = 80.0
@export var attack_dmg:   int   = 12
@export var detect_range: float = 300.0
@export var attack_range: float = 220.0

## Gold dropped on death (scattered as GoldPickup coins by the room).
@export var gold_reward:  int   = 5

# ---------------------------------------------------------------------------
# Runtime state
# ---------------------------------------------------------------------------
var current_hp: int = 0
var _is_dead: bool = false
var _nav_agent: NavigationAgent2D = null

# Cached player reference — refreshed each frame if null.
var _player: CharacterBody2D = null

# ---------------------------------------------------------------------------
# Child node references (must exist in every subclass scene)
# ---------------------------------------------------------------------------
@onready var sprite: Sprite2D = $Sprite2D
@onready var hp_label: Label  = $HPLabel


func _ready() -> void:
	current_hp = max_hp
	_refresh_label()

	# Wire NavigationAgent2D if present.
	if has_node("NavigationAgent2D"):
		_nav_agent = $NavigationAgent2D


# ---------------------------------------------------------------------------
# Navigation helpers
# ---------------------------------------------------------------------------

## Returns a normalised movement direction toward the player,
## using NavigationAgent2D when available, falling back to a direct vector.
func _nav_direction(_delta: float) -> Vector2:
	var p: CharacterBody2D = _get_player()
	if p == null:
		return Vector2.ZERO

	if _nav_agent != null:
		_nav_agent.target_position = p.global_position
		var next: Vector2 = _nav_agent.get_next_path_position()
		var dir: Vector2 = (next - global_position)
		if dir.length() > 1.0:
			return dir.normalized()
		return Vector2.ZERO
	else:
		# Direct-vector fallback.
		var dir: Vector2 = p.global_position - global_position
		if dir.length() > 1.0:
			return dir.normalized()
		return Vector2.ZERO


## Distance to the player (INF if no player found).
func _dist_to_player() -> float:
	var p: CharacterBody2D = _get_player()
	if p == null:
		return INF
	return global_position.distance_to(p.global_position)


# ---------------------------------------------------------------------------
# Damage + death
# ---------------------------------------------------------------------------

## Called by the player's hitbox via the attack-landed → nearest-enemy search.
func take_damage(dmg: int) -> void:
	if _is_dead:
		return
	current_hp -= dmg
	_refresh_label()
	_flash_red()
	# Impact juice: light shake + a spark burst at the hit location.
	FX.shake(3.5)
	FX.spark(global_position, Color(1.0, 0.85, 0.4, 1.0), 8, 130.0)
	AudioManager.play_sfx("hit")
	if current_hp <= 0:
		_die()


func _die() -> void:
	if _is_dead:
		return
	_is_dead = true

	print("[%s] %s destroyed." % [get_script().resource_path.get_file(), name])

	# Death juice: stronger shake, a brief hitstop, and a red burst.
	FX.shake(8.0)
	FX.hitstop(0.07)
	FX.spark(global_position, Color(1.0, 0.35, 0.3, 1.0), 18, 200.0)
	AudioManager.play_sfx("enemy_death")

	# Disable physics + collision so the enemy stops interacting.
	set_process(false)
	set_physics_process(false)
	_disable_all_collision()

	# Shrink + fade, then free.
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self,   "scale",            Vector2(0.0, 0.0), 0.35) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "modulate",         Color(1.0, 0.3, 0.3, 0.0), 0.35)
	tween.tween_property(hp_label, "modulate",       Color(1.0, 1.0, 1.0, 0.0), 0.2)
	tween.chain().tween_callback(_emit_died_and_free)


func _emit_died_and_free() -> void:
	emit_signal("enemy_died", self)
	queue_free()


# ---------------------------------------------------------------------------
# Visual helpers
# ---------------------------------------------------------------------------

func _flash_red() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(3.0, 0.2, 0.2, 1.0), 0.0)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.08)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.04)
	tween.tween_property(sprite, "modulate", Color(3.0, 0.2, 0.2, 1.0), 0.0)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.08)


## Orange pre-attack telegraph flash — called by subclasses before attack lands.
func _flash_telegraph() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(3.0, 1.5, 0.0, 1.0), 0.0)
	tween.tween_property(sprite, "modulate", Color(2.0, 0.8, 0.0, 1.0), 0.15)
	tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3, 1.0), 0.1)


## Full pre-attack telegraph: the orange flash PLUS a floating "!" that pops
## above the enemy for `duration` seconds. Subclasses call this at the start of
## their windup so the player has a clear, readable window to dodge or parry.
func _show_telegraph(duration: float) -> void:
	_flash_telegraph()

	var mark: Label = Label.new()
	mark.text = "!"
	mark.add_theme_font_size_override("font_size", 30)
	mark.add_theme_color_override("font_color", Color(1.0, 0.78, 0.1))
	mark.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0))
	mark.add_theme_constant_override("outline_size", 5)
	mark.position = Vector2(-7, -84)
	mark.z_index = 50
	add_child(mark)

	var t: Tween = create_tween()
	t.tween_property(mark, "scale", Vector2(1.3, 1.3), duration * 0.35) \
		.from(Vector2(0.3, 0.3)).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(mark, "modulate:a", 0.0, duration * 0.65)
	t.tween_callback(mark.queue_free)


func _refresh_label() -> void:
	if hp_label == null:
		return
	hp_label.text = "HP: %d/%d" % [maxi(current_hp, 0), max_hp]


# ---------------------------------------------------------------------------
# Player lookup
# ---------------------------------------------------------------------------

## Returns the player node via the "player" group, caching the result.
func _get_player() -> CharacterBody2D:
	if _player != null and is_instance_valid(_player):
		return _player
	var nodes: Array = get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		_player = nodes[0] as CharacterBody2D
	return _player


# ---------------------------------------------------------------------------
# Collision helpers
# ---------------------------------------------------------------------------

func _disable_all_collision() -> void:
	# Disable the enemy's own CharacterBody2D collision.
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = true
		# Also disable any Area2D children (hitboxes).
		if child is Area2D:
			child.monitoring = false
			child.monitorable = false
			for sub in child.get_children():
				if sub is CollisionShape2D:
					sub.disabled = true
