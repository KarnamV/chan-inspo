## Beast.gd — Fast rusher enemy
##
## FSM states:
##   IDLE     → stands still until player enters detect_range
##   CHASE    → approaches player; enters RUSH when in attack_range
##   RUSH     → straight-line dash at 350 px/s toward the player's position
##              at the moment the rush starts; hits player on body_entered
##   COOLDOWN → 0.8 s stunned after the rush regardless of whether it hit
##   HURT     → 0.25 s stagger on taking damage (can interrupt CHASE/COOLDOWN)
##   DEAD     → handled in EnemyBase._die()
##
## Stats: HP 30, speed 200 (rush 350), dmg 22, detect 320 px, attack_range 60 px
##
## Melee hit during rush: Area2D child "RushHitbox" is enabled only during RUSH.
## Hitting the player calls take_hit; then the rush continues to its end
## (COOLDOWN begins regardless of hit).

extends EnemyBase

enum State { IDLE, CHASE, RUSH, COOLDOWN, HURT, DEAD }

const RUSH_SPEED:         float = 350.0
const RUSH_MAX_DURATION:  float = 0.55   # safety cap so it doesn't fly forever
const COOLDOWN_DURATION:  float = 0.8
const HURT_DURATION:      float = 0.25

var _state: State = State.IDLE
var _state_timer: float = 0.0
var _rush_dir: Vector2 = Vector2.ZERO
var _rush_hit_registered: bool = false

@onready var _rush_hitbox: Area2D = $RushHitbox
@onready var _rush_shape:  CollisionShape2D = $RushHitbox/RushShape


func _ready() -> void:
	max_hp       = 30
	move_speed   = 200.0
	attack_dmg   = 22
	detect_range = 320.0
	attack_range = 60.0
	super._ready()

	# Red-orange tint for the feral beast.
	sprite.modulate = Color(1.0, 0.5, 0.2, 1.0)

	_rush_hitbox.monitoring = false
	_rush_shape.disabled    = true
	_rush_hitbox.body_entered.connect(_on_rush_hit)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	match _state:
		State.IDLE:
			_tick_idle()
		State.CHASE:
			_tick_chase(delta)
		State.RUSH:
			_tick_rush(delta)
		State.COOLDOWN:
			_tick_cooldown(delta)
		State.HURT:
			_tick_hurt(delta)

	move_and_slide()


# ---------------------------------------------------------------------------
# State ticks
# ---------------------------------------------------------------------------

func _tick_idle() -> void:
	velocity = Vector2.ZERO
	if _dist_to_player() <= detect_range:
		_state = State.CHASE


func _tick_chase(delta: float) -> void:
	var dist: float = _dist_to_player()
	if dist > detect_range:
		_state = State.IDLE
		velocity = Vector2.ZERO
		return
	if dist <= attack_range:
		_start_rush()
		return
	var dir: Vector2 = _nav_direction(delta)
	velocity = dir * move_speed


func _start_rush() -> void:
	var p: CharacterBody2D = _get_player()
	if p == null:
		_state = State.IDLE
		return

	# Lock in the rush direction at the moment of launch.
	_rush_dir = (p.global_position - global_position).normalized()
	_state = State.RUSH
	_state_timer = RUSH_MAX_DURATION
	_rush_hit_registered = false

	# Enable hitbox.
	_rush_shape.disabled    = false
	_rush_hitbox.monitoring = true

	# Orange pre-rush telegraph (very brief — beast telegraphs less than warrior).
	_flash_telegraph()

	velocity = _rush_dir * RUSH_SPEED


func _tick_rush(delta: float) -> void:
	_state_timer -= delta
	velocity = _rush_dir * RUSH_SPEED

	# End rush if we've timed out.
	if _state_timer <= 0.0:
		_end_rush()


func _end_rush() -> void:
	_rush_shape.disabled    = true
	_rush_hitbox.monitoring = false
	velocity = Vector2.ZERO
	_state = State.COOLDOWN
	_state_timer = COOLDOWN_DURATION


func _tick_cooldown(delta: float) -> void:
	velocity = Vector2.ZERO
	_state_timer -= delta
	if _state_timer <= 0.0:
		if _dist_to_player() <= detect_range:
			_state = State.CHASE
		else:
			_state = State.IDLE


func _tick_hurt(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		velocity = Vector2.ZERO
		# Always cool down briefly after a hurt to avoid instant re-rush.
		_state = State.COOLDOWN
		_state_timer = COOLDOWN_DURATION * 0.5


# ---------------------------------------------------------------------------
# Rush hit callback — fires once per rush via _rush_hit_registered guard
# ---------------------------------------------------------------------------

func _on_rush_hit(body: Node) -> void:
	if _rush_hit_registered:
		return
	if not body.is_in_group("player"):
		return
	_rush_hit_registered = true
	var knockback: Vector2 = _rush_dir * 420.0
	body.take_hit(knockback, attack_dmg)
	# Rush continues; COOLDOWN begins at end of rush timer regardless.


# ---------------------------------------------------------------------------
# Override take_damage to enter HURT state
# ---------------------------------------------------------------------------

func take_damage(dmg: int) -> void:
	if _is_dead:
		return
	# Cancel rush mid-flight if hit.
	if _state == State.RUSH:
		_rush_shape.disabled    = true
		_rush_hitbox.monitoring = false
		velocity = Vector2.ZERO
	super.take_damage(dmg)
	if not _is_dead:
		_state = State.HURT
		_state_timer = HURT_DURATION
		velocity = Vector2.ZERO
