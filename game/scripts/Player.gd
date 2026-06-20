extends CharacterBody2D

# ---------------------------------------------------------------------------
# Player.gd — 8-direction movement + 4 basic attacks + block/stagger guard
# ---------------------------------------------------------------------------

enum State { IDLE, MOVE, ATTACK, DODGE, BLOCK, HURT, DEAD }

signal attack_landed(attack_name: String, damage: int, hit_position: Vector2)

@export var speed_run: float = 200.0
@export var speed_walk: float = 80.0
@export var dodge_speed: float = 520.0
@export var dodge_duration: float = 0.35
@export var block_speed_mult: float = 0.4

# Stance multipliers — written by the active talisman, read by attacks/dodge.
# Default 1.0 means "no talisman equipped" = neutral stats.
var stance_speed_mult: float = 1.0
var stance_damage_mult: float = 1.0

# Talisman node assigned by the owning scene (e.g. TestRoom).
# Must expose activate(player) and deactivate(player) methods.
var active_talisman: Node = null

# How quickly velocity reaches the target each physics frame (lerp weight).
# Higher = snappier. 18 gives instant-feeling brawler response without
# feeling like a platformer with instant-stop.
const ACCEL_WEIGHT: float = 18.0

# Hitbox reach from player origin per attack type (pixels).
const PUNCH_REACH: float = 28.0
const KICK_REACH: float = 38.0
const THROW_REACH: float = 30.0
const DASH_REACH: float = 80.0

const COUNTER_WINDOW_DURATION: float = 0.2
const COUNTER_DAMAGE_MULT: float = 1.5

var state: State = State.IDLE
var facing_dir: Vector2 = Vector2.RIGHT
var _is_lunging: bool = false
var _is_dodging: bool = false
var in_counter_window: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox_area: Area2D = $HitboxArea
@onready var hitbox_shape: CollisionShape2D = $HitboxArea/HitboxShape


func _ready() -> void:
	hitbox_area.monitoring = false
	hitbox_shape.disabled = true
	hitbox_area.body_entered.connect(_on_hitbox_body_entered)
	_current_attack_name = ""
	_current_attack_damage = 0


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if state == State.HURT or state == State.DEAD:
		return

	# Talisman activation is allowed in any non-dead state (including ATTACK).
	if event.is_action_pressed("talisman_activate") and active_talisman != null:
		active_talisman.activate(self)
		return

	if state == State.ATTACK:
		return

	if event.is_action_pressed("dodge") and state != State.DODGE:
		dodge_roll(facing_dir)
		return

	if event.is_action_pressed("block") and state != State.DODGE:
		state = State.BLOCK
		return
	if event.is_action_released("block") and state == State.BLOCK:
		state = State.IDLE
		return

	if state == State.BLOCK:
		return

	if event.is_action_pressed("attack_punch"):
		attack_punch()
	elif event.is_action_pressed("attack_kick"):
		attack_kick()
	elif event.is_action_pressed("attack_throw"):
		attack_throw()
	elif event.is_action_pressed("attack_dash"):
		attack_dash()


func _handle_movement(delta: float) -> void:
	if state == State.ATTACK or state == State.HURT or state == State.DEAD:
		if not _is_lunging:
			velocity = velocity.lerp(Vector2.ZERO, ACCEL_WEIGHT * delta)
		return
	if state == State.DODGE:
		return

	var raw_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_dir: Vector2 = raw_dir.normalized() if raw_dir.length() > 0.0 else Vector2.ZERO

	var target_speed: float = speed_walk if Input.is_action_pressed("walk_modifier") else speed_run
	if state == State.BLOCK:
		target_speed *= block_speed_mult
	var target_vel: Vector2 = move_dir * target_speed

	velocity = velocity.lerp(target_vel, ACCEL_WEIGHT * delta)

	if move_dir != Vector2.ZERO:
		facing_dir = move_dir
		if state != State.BLOCK:
			state = State.MOVE
		_update_sprite_flip()
	else:
		if state != State.BLOCK:
			state = State.IDLE


func _update_sprite_flip() -> void:
	if facing_dir.x < 0.0:
		sprite.flip_h = true
	elif facing_dir.x > 0.0:
		sprite.flip_h = false


# ---------------------------------------------------------------------------
# Internal hitbox state — set before enabling the hitbox so the body_entered
# callback knows which attack landed.
# ---------------------------------------------------------------------------
var _current_attack_name: String = ""
var _current_attack_damage: int = 0


func _enable_hitbox(offset: Vector2, shape_size: Vector2) -> void:
	hitbox_shape.shape.size = shape_size
	hitbox_area.position = offset
	hitbox_shape.disabled = false
	hitbox_area.monitoring = true


func _disable_hitbox() -> void:
	hitbox_area.monitoring = false
	hitbox_shape.disabled = true


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == self:
		return
	emit_signal("attack_landed", _current_attack_name, _current_attack_damage, body.global_position)


# ---------------------------------------------------------------------------
# Attack implementations
# ---------------------------------------------------------------------------

## Fast, short-range punch. Chains into kick via the combo system (Phase 2).
func attack_punch(dir: Vector2 = Vector2.ZERO) -> void:
	var attack_dir: Vector2 = dir if dir != Vector2.ZERO else facing_dir
	const RECOVERY: float = 0.2
	const ACTIVE_FRACTION: float = 0.6
	const DAMAGE: int = 10
	var recovery: float = RECOVERY * stance_speed_mult

	state = State.ATTACK
	_current_attack_name = "punch"
	var base_dmg: int = int(DAMAGE * stance_damage_mult)
	_current_attack_damage = int(base_dmg * COUNTER_DAMAGE_MULT) if in_counter_window else base_dmg
	in_counter_window = false
	_enable_hitbox(attack_dir * PUNCH_REACH, Vector2(18.0, 18.0))

	await get_tree().create_timer(recovery * ACTIVE_FRACTION).timeout
	_disable_hitbox()
	await get_tree().create_timer(recovery * (1.0 - ACTIVE_FRACTION)).timeout
	_finish_attack()


## Medium-speed, wider-arc kick.
func attack_kick(dir: Vector2 = Vector2.ZERO) -> void:
	var attack_dir: Vector2 = dir if dir != Vector2.ZERO else facing_dir
	const RECOVERY: float = 0.3
	const ACTIVE_FRACTION: float = 0.6
	const DAMAGE: int = 15
	var recovery: float = RECOVERY * stance_speed_mult

	state = State.ATTACK
	_current_attack_name = "kick"
	var base_dmg: int = int(DAMAGE * stance_damage_mult)
	_current_attack_damage = int(base_dmg * COUNTER_DAMAGE_MULT) if in_counter_window else base_dmg
	in_counter_window = false
	var shape: Vector2 = Vector2(20.0, 28.0) if abs(attack_dir.x) > abs(attack_dir.y) else Vector2(28.0, 20.0)
	_enable_hitbox(attack_dir * KICK_REACH, shape)

	await get_tree().create_timer(recovery * ACTIVE_FRACTION).timeout
	_disable_hitbox()
	await get_tree().create_timer(recovery * (1.0 - ACTIVE_FRACTION)).timeout
	_finish_attack()


## Grab-and-launch throw. No effect if no enemy body enters the overlap window.
func attack_throw(dir: Vector2 = Vector2.ZERO) -> void:
	var attack_dir: Vector2 = dir if dir != Vector2.ZERO else facing_dir
	const RECOVERY: float = 0.5
	const ACTIVE_FRACTION: float = 0.6
	const DAMAGE: int = 20
	var recovery: float = RECOVERY * stance_speed_mult

	state = State.ATTACK
	_current_attack_name = "throw"
	var base_dmg: int = int(DAMAGE * stance_damage_mult)
	_current_attack_damage = int(base_dmg * COUNTER_DAMAGE_MULT) if in_counter_window else base_dmg
	in_counter_window = false
	# Square overlap check — grabbing range is close and centered.
	_enable_hitbox(attack_dir * THROW_REACH, Vector2(24.0, 24.0))

	await get_tree().create_timer(recovery * ACTIVE_FRACTION).timeout
	_disable_hitbox()
	await get_tree().create_timer(recovery * (1.0 - ACTIVE_FRACTION)).timeout
	_finish_attack()


## Short lunge forward + hitbox at the end of the lunge. Moves the player ~80 px.
func attack_dash(dir: Vector2 = Vector2.ZERO) -> void:
	var attack_dir: Vector2 = dir if dir != Vector2.ZERO else facing_dir
	const RECOVERY: float = 0.35
	const ACTIVE_FRACTION: float = 0.6
	const DAMAGE: int = 18
	# Speed needed: lunge window = RECOVERY * 0.25 = 0.0875s.
	# Distance = speed * window → 80 / 0.0875 ≈ 915 px/s.
	const LUNGE_SPEED: float = 915.0
	var recovery: float = RECOVERY * stance_speed_mult

	var boosted: bool = in_counter_window
	in_counter_window = false

	state = State.ATTACK
	_is_lunging = true
	facing_dir = attack_dir
	_update_sprite_flip()

	velocity = attack_dir * LUNGE_SPEED

	# Hold full lunge speed for the travel window, then stop and activate hitbox.
	# Lunge travel time scales with speed multiplier so DARK still travels full distance.
	await get_tree().create_timer(recovery * 0.25).timeout
	_is_lunging = false

	_current_attack_name = "dash_attack"
	var base_dmg: int = int(DAMAGE * stance_damage_mult)
	_current_attack_damage = int(base_dmg * COUNTER_DAMAGE_MULT) if boosted else base_dmg
	_enable_hitbox(attack_dir * DASH_REACH * 0.5, Vector2(22.0, 22.0))

	await get_tree().create_timer(recovery * (ACTIVE_FRACTION - 0.25)).timeout
	_disable_hitbox()
	await get_tree().create_timer(recovery * (1.0 - ACTIVE_FRACTION)).timeout
	_finish_attack()


func _finish_attack() -> void:
	_is_lunging = false
	_is_dodging = false
	if state == State.ATTACK:
		state = State.IDLE


# ---------------------------------------------------------------------------
# Remaining hooks (Phase 1 backlog / future phases)
# ---------------------------------------------------------------------------

func dodge_roll(dir: Vector2 = Vector2.ZERO) -> void:
	var roll_dir: Vector2 = dir.normalized() if dir != Vector2.ZERO else facing_dir
	state = State.DODGE
	_is_dodging = true
	velocity = roll_dir * dodge_speed

	var tween: Tween = create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.3, 0.7), 0.08)
	tween.tween_property(sprite, "scale", Vector2(1.0, 1.0), dodge_duration - 0.08)

	await get_tree().create_timer(dodge_duration).timeout

	_is_dodging = false
	velocity = Vector2.ZERO
	if state == State.DODGE:
		state = State.IDLE


func take_hit(knockback_vel: Vector2, damage: int = 0) -> void:
	if _is_dodging:
		return
	if state == State.BLOCK:
		var blocked_damage: int = damage / 2
		emit_signal("attack_landed", "blocked_hit", blocked_damage, global_position)
		_trigger_block_flash()
		_start_counter_window()
		return
	_is_lunging = false
	_disable_hitbox()
	state = State.HURT
	velocity = knockback_vel


func _trigger_block_flash() -> void:
	# Settle back to the current stance tint (or plain white if no talisman).
	var settle_color: Color = Color.WHITE
	if active_talisman != null and active_talisman.has_method("stance_display_text"):
		settle_color = active_talisman.LIGHT_TINT if active_talisman.current_stance == 0 \
				else active_talisman.DARK_TINT
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", Color.WHITE, 0.0)
	tween.tween_property(sprite, "modulate", Color(3.0, 3.0, 3.0, 1.0), 0.05)
	tween.tween_property(sprite, "modulate", settle_color, 0.08)


func _start_counter_window() -> void:
	in_counter_window = true
	await get_tree().create_timer(COUNTER_WINDOW_DURATION).timeout
	in_counter_window = false


func recover_from_hurt() -> void:
	if state == State.HURT:
		state = State.IDLE


func die() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
