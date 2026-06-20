## PossessedWarrior.gd — Melee bruiser enemy
##
## FSM states:
##   IDLE     → stands still until player enters detect_range
##   CHASE    → walks toward player; enters WINDUP when in attack_range
##   WINDUP   → 0.4 s telegraph (orange flash) — player can react/dodge
##   ATTACK   → melee hitbox active for a brief window; calls player.take_hit
##   RECOVERY → 0.3 s recovery before returning to CHASE or IDLE
##   HURT     → 0.25 s stagger after taking damage
##   DEAD     → handled in EnemyBase._die()
##
## Stats: HP 70, speed 110, dmg 18, detect 250 px, attack_range 55 px
##
## Melee hit: An Area2D child named "MeleeHitbox" is enabled only during ATTACK.
## The hitbox's body_entered checks for the "player" group and calls take_hit.

extends EnemyBase

enum State { IDLE, CHASE, WINDUP, ATTACK, RECOVERY, HURT, DEAD }

const WINDUP_DURATION:   float = 0.4
const ATTACK_DURATION:   float = 0.15   # hitbox-active window
const RECOVERY_DURATION: float = 0.3
const HURT_DURATION:     float = 0.25

var _state: State = State.IDLE
var _state_timer: float = 0.0

@onready var _melee_hitbox: Area2D = $MeleeHitbox
@onready var _melee_shape:  CollisionShape2D = $MeleeHitbox/MeleeShape


func _ready() -> void:
	max_hp       = 70
	move_speed   = 110.0
	attack_dmg   = 18
	detect_range = 250.0
	attack_range = 55.0
	super._ready()

	# Dark green/grey tint — possessed soldier look.
	sprite.modulate = Color(0.5, 0.8, 0.4, 1.0)

	# Melee hitbox starts disabled.
	_melee_hitbox.monitoring = false
	_melee_shape.disabled    = true
	_melee_hitbox.body_entered.connect(_on_melee_hit)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	match _state:
		State.IDLE:
			_tick_idle()
		State.CHASE:
			_tick_chase(delta)
		State.WINDUP:
			_tick_windup(delta)
		State.ATTACK:
			_tick_attack(delta)
		State.RECOVERY:
			_tick_recovery(delta)
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
		_enter_windup()
		return
	var dir: Vector2 = _nav_direction(delta)
	velocity = dir * move_speed


func _enter_windup() -> void:
	_state = State.WINDUP
	_state_timer = WINDUP_DURATION
	velocity = Vector2.ZERO
	_flash_telegraph()


func _tick_windup(delta: float) -> void:
	velocity = Vector2.ZERO
	_state_timer -= delta
	if _state_timer <= 0.0:
		_enter_attack()


func _enter_attack() -> void:
	_state = State.ATTACK
	_state_timer = ATTACK_DURATION
	velocity = Vector2.ZERO
	# Enable melee hitbox.
	_melee_shape.disabled    = false
	_melee_hitbox.monitoring = true


func _tick_attack(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		# Disable hitbox and enter recovery.
		_melee_shape.disabled    = true
		_melee_hitbox.monitoring = false
		_state = State.RECOVERY
		_state_timer = RECOVERY_DURATION


func _tick_recovery(delta: float) -> void:
	velocity = Vector2.ZERO
	_state_timer -= delta
	if _state_timer <= 0.0:
		# Return to CHASE or IDLE depending on player distance.
		if _dist_to_player() <= detect_range:
			_state = State.CHASE
		else:
			_state = State.IDLE


func _tick_hurt(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		velocity = Vector2.ZERO
		if _dist_to_player() <= detect_range:
			_state = State.CHASE
		else:
			_state = State.IDLE


# ---------------------------------------------------------------------------
# Melee hit callback
# ---------------------------------------------------------------------------

func _on_melee_hit(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	# Knockback pushes player away from the warrior.
	var dir: Vector2 = (body.global_position - global_position).normalized()
	body.take_hit(dir * 300.0, attack_dmg)


# ---------------------------------------------------------------------------
# Override take_damage to enter HURT state
# ---------------------------------------------------------------------------

func take_damage(dmg: int) -> void:
	if _is_dead:
		return
	# Disable hitbox if mid-attack.
	_melee_shape.disabled    = true
	_melee_hitbox.monitoring = false
	super.take_damage(dmg)
	if not _is_dead:
		_state = State.HURT
		_state_timer = HURT_DURATION
		velocity = Vector2.ZERO
