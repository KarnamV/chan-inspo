## Demon.gd — Ranged harasser enemy
##
## FSM states:
##   IDLE  → stays still until player enters detect_range
##   CHASE → moves toward player; transitions to ATTACK when in attack_range
##   ATTACK → stops, fires a projectile every 1.8 s; returns to CHASE when
##            player leaves attack_range; back to IDLE if player leaves detect_range
##   HURT  → brief stagger (0.25 s) after taking a hit
##   DEAD  → handled in EnemyBase._die()
##
## Stats: HP 40, speed 80, dmg 12, detect 300 px, attack_range 220 px

extends EnemyBase

enum State { IDLE, CHASE, ATTACK, WINDUP, HURT, DEAD }

const FIRE_INTERVAL: float = 1.8
const WINDUP_DURATION: float = 0.5   # telegraph before a shot — time to break line/dodge
const HURT_DURATION: float = 0.25

const ProjectileScene: PackedScene = preload("res://scenes/DemonProjectile.tscn")

var _state: State = State.IDLE
var _fire_timer: float = 0.0
var _windup_timer: float = 0.0
var _hurt_timer: float = 0.0


func _ready() -> void:
	# Override base stats for this enemy type.
	max_hp       = 40
	move_speed   = 80.0
	attack_dmg   = 12
	detect_range = 300.0
	attack_range = 220.0
	gold_reward  = 8
	super._ready()

	# Purple tint to distinguish Demon visually.
	sprite.modulate = Color(0.8, 0.4, 1.0, 1.0)


func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	match _state:
		State.IDLE:
			_tick_idle()
		State.CHASE:
			_tick_chase(delta)
		State.ATTACK:
			_tick_attack(delta)
		State.WINDUP:
			_tick_windup(delta)
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
		_state = State.ATTACK
		_fire_timer = 0.0   # fire immediately on next tick
		velocity = Vector2.ZERO
		return
	# Move toward player.
	var dir: Vector2 = _nav_direction(delta)
	velocity = dir * move_speed


func _tick_attack(delta: float) -> void:
	velocity = Vector2.ZERO

	var dist: float = _dist_to_player()
	if dist > detect_range:
		_state = State.IDLE
		return
	if dist > attack_range:
		_state = State.CHASE
		return

	_fire_timer -= delta
	if _fire_timer <= 0.0:
		_enter_windup()


## Telegraph, then fire once the windup elapses. Cancels back to CHASE if the
## player escapes attack range during the wind-up.
func _enter_windup() -> void:
	_state = State.WINDUP
	_windup_timer = WINDUP_DURATION
	velocity = Vector2.ZERO
	_show_telegraph(WINDUP_DURATION)


func _tick_windup(delta: float) -> void:
	velocity = Vector2.ZERO
	var dist: float = _dist_to_player()
	if dist > detect_range:
		_state = State.IDLE
		return
	if dist > attack_range:
		_state = State.CHASE
		return
	_windup_timer -= delta
	if _windup_timer <= 0.0:
		_shoot()
		_fire_timer = FIRE_INTERVAL
		_state = State.ATTACK


func _tick_hurt(delta: float) -> void:
	_hurt_timer -= delta
	if _hurt_timer <= 0.0:
		velocity = Vector2.ZERO
		_state = State.IDLE


# ---------------------------------------------------------------------------
# Shooting
# ---------------------------------------------------------------------------

func _shoot() -> void:
	var p: CharacterBody2D = _get_player()
	if p == null:
		return

	var proj: Node2D = ProjectileScene.instantiate()
	# Add to the same parent so the projectile is not destroyed with the enemy.
	get_parent().add_child(proj)
	proj.global_position = global_position

	var dir: Vector2 = (p.global_position - global_position).normalized()
	proj.init(dir, attack_dmg)


# ---------------------------------------------------------------------------
# Override take_damage to enter HURT state
# ---------------------------------------------------------------------------

func take_damage(dmg: int) -> void:
	if _is_dead:
		return
	super.take_damage(dmg)
	if not _is_dead:
		_state = State.HURT
		_hurt_timer = HURT_DURATION
		velocity = Vector2.ZERO
