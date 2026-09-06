extends CharacterBody2D

# ---------------------------------------------------------------------------
# Player.gd — 8-direction movement + 4 basic attacks + block/stagger guard
#             + combo counter + martial-spirit meter (Phase 2)
# ---------------------------------------------------------------------------

enum State { IDLE, MOVE, ATTACK, DODGE, BLOCK, HURT, DEAD }

signal attack_landed(attack_name: String, damage: int, hit_position: Vector2)

# Emitted whenever HP changes (take_hit, heal, upgrades). Carries the current
# max_hp so the HUD does not need to read the player's fields directly.
signal health_updated(current: int, max_hp: int)

# Emitted once when the player's HP reaches 0.  TestRoom listens to this
# to start the 0.5s pause → fade → Hub transition.
signal player_died

# Emitted whenever the combo counter changes (including resets to 0).
signal combo_updated(count: int)

# Emitted whenever the spirit value changes. max_spirit is always SPIRIT_MAX
# and is included so the HUD does not need to know the constant directly.
signal spirit_updated(current: float, max_spirit: float)

@export var speed_run: float = 200.0
@export var speed_walk: float = 80.0
@export var dodge_speed: float = 520.0
@export var dodge_duration: float = 0.35
@export var block_speed_mult: float = 0.4

# Stance multipliers — written by the active talisman, read by attacks/dodge.
# Default 1.0 means "no talisman equipped" = neutral stats.
var stance_speed_mult: float = 1.0
var stance_damage_mult: float = 1.0

# Permanent run-wide damage multiplier — raised by shrine blessings (e.g. Fury).
# Applied in _apply_damage_flags so it affects every attack uniformly.
var permanent_damage_mult: float = 1.0

# Talisman node currently active (kept in sync by TalismanManager on each cycle).
# Must expose activate(player) and deactivate(player) methods.
var active_talisman: Node = null

# Reference to the TalismanManager child node (assigned by TestRoom after setup).
var talisman_manager: Node = null

# ---------------------------------------------------------------------------
# Talisman effect flags — set by talisman activate(), cleared after one use.
# ---------------------------------------------------------------------------

# DragonClaw: next attack deals x3 damage, ignores counter/block state.
var dragon_claw_active: bool = false

# TigerFang: set true by TigerFang after a dodge roll completes (3s window).
# Next attack deals x2 damage, then this flag clears.
var tiger_fang_ready: bool = false

# SnakeCoil: next hit chains 50% damage to up to 2 nearby enemies.
var snake_coil_active: bool = false

# DemonSeal: absorb the next incoming hit (no damage/knockback), then the seal
# talisman explodes, damaging nearby enemies. Consumed on the absorbed hit.
var demon_seal_active: bool = false

# ---------------------------------------------------------------------------
# HP
# ---------------------------------------------------------------------------
# max_hp is a var (not const) so shop/shrine upgrades can raise it at runtime.
# Starts at 100. health_updated always reports (current_hp, max_hp).
var max_hp: int = 100
var current_hp: int = max_hp

# ---------------------------------------------------------------------------
# Combo + spirit meter
# ---------------------------------------------------------------------------
const SPIRIT_MAX: float = 100.0
const SPIRIT_DECAY_RATE: float = 5.0       # per second, passive, when not attacking
const SPIRIT_COST_TALISMAN: float = 30.0   # cost to activate talisman
const COMBO_RESET_TIME: float = 2.5        # seconds of no hits before combo resets
const OVERDRIVE_THRESHOLD: float = 100.0   # spirit value that triggers overdrive visual
const OVERDRIVE_RELEASE: float = 80.0      # spirit must drop below this to end overdrive

# Spirit gained per confirmed hit (body_entered fired).
# Counter-window hits get COUNTER_SPIRIT_MULT applied on top.
const SPIRIT_PER_ATTACK: Dictionary = {
	"punch":      8.0,
	"kick":      10.0,
	"throw":     15.0,
	"dash_attack": 12.0,
}
const COUNTER_SPIRIT_MULT: float = 1.5

var combo_count: int = 0
var spirit: float = 0.0

var _combo_timer: float = 0.0      # counts down; reset to COMBO_RESET_TIME on each hit
var _in_overdrive: bool = false    # tracks whether the gold-pulse tween is active
var _overdrive_tween: Tween = null # kept so it can be killed when overdrive ends

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
	add_to_group("player")
	hitbox_area.monitoring = false
	hitbox_shape.disabled = true
	hitbox_area.body_entered.connect(_on_hitbox_body_entered)
	_current_attack_name = ""
	_current_attack_damage = 0
	_current_hit_is_counter = false
	combo_count = 0
	spirit = 0.0
	_combo_timer = 0.0
	_in_overdrive = false
	_overdrive_tween = null


func _physics_process(delta: float) -> void:
	_handle_movement(delta)
	move_and_slide()
	_tick_combo(delta)
	_tick_spirit_decay(delta)


func _tick_combo(delta: float) -> void:
	if combo_count == 0:
		return
	_combo_timer -= delta
	if _combo_timer <= 0.0:
		combo_count = 0
		emit_signal("combo_updated", 0)


func _tick_spirit_decay(delta: float) -> void:
	if spirit <= 0.0:
		return
	# Passive decay only applies when the player is not mid-attack.
	if state == State.ATTACK:
		return
	var prev: float = spirit
	spirit = maxf(0.0, spirit - SPIRIT_DECAY_RATE * delta)
	if spirit != prev:
		emit_signal("spirit_updated", spirit, SPIRIT_MAX)
		_check_overdrive_exit()


func _unhandled_input(event: InputEvent) -> void:
	if state == State.HURT or state == State.DEAD:
		return

	# Tab: cycle to the next talisman slot (allowed even mid-attack).
	if event.is_action_pressed("talisman_cycle") and talisman_manager != null:
		talisman_manager.cycle_next()
		return

	# Talisman activation is allowed in any non-dead state (including ATTACK).
	# Spirit cost: reads SPIRIT_COST from the talisman if defined, otherwise
	# falls back to the global SPIRIT_COST_TALISMAN (30 sp).
	if event.is_action_pressed("talisman_activate") and active_talisman != null:
		var cost: float = SPIRIT_COST_TALISMAN
		if "SPIRIT_COST" in active_talisman:
			cost = active_talisman.SPIRIT_COST
		if spirit < cost:
			# Emit current spirit so the HUD knows a blocked attempt happened.
			emit_signal("spirit_updated", spirit, SPIRIT_MAX)
			return
		spirit -= cost
		emit_signal("spirit_updated", spirit, SPIRIT_MAX)
		_check_overdrive_exit()
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
# Captures whether in_counter_window was true at the moment the attack was
# initiated. Each attack reads this before clearing in_counter_window so the
# spirit multiplier can be applied inside _register_hit even though the flag
# has already been cleared by the time body_entered fires.
var _current_hit_is_counter: bool = false


func _enable_hitbox(offset: Vector2, shape_size: Vector2) -> void:
	hitbox_shape.shape.size = shape_size
	hitbox_area.position = offset
	hitbox_shape.disabled = false
	hitbox_area.monitoring = true


func _disable_hitbox() -> void:
	# Deferred: take_hit() can call this from an enemy's body_entered callback,
	# which runs while the physics server is flushing queries. Mutating
	# monitoring/disabled synchronously there throws "Can't change this state
	# while flushing queries." set_deferred applies it safely after the flush.
	hitbox_area.set_deferred("monitoring", false)
	hitbox_shape.set_deferred("disabled", true)


# ---------------------------------------------------------------------------
# Talisman flag application — called after base damage is computed, before
# _enable_hitbox. Applies stacking modifiers from active effect flags.
#
# DragonClaw: x3 damage, also overrides in_counter_window so the block-counter
#             multiplier doesn't stack on top (DragonClaw already ignores block).
# TigerFang:  x2 damage (post-counter so it stacks with counter window bonus).
# Both flags are cleared here so they apply to exactly one hit.
# ---------------------------------------------------------------------------

func _apply_damage_flags() -> void:
	# Permanent shrine buff first, so one-shot talisman flags stack on top of it.
	if permanent_damage_mult != 1.0:
		_current_attack_damage = int(_current_attack_damage * permanent_damage_mult)

	if dragon_claw_active:
		dragon_claw_active = false
		# Override any counter-window state — Dragon Claw bypasses block.
		_current_hit_is_counter = false
		in_counter_window = false
		_current_attack_damage = int(_current_attack_damage * 3.0)
		print("[Player] DragonClaw — damage -> %d (x3)." % _current_attack_damage)

	if tiger_fang_ready:
		tiger_fang_ready = false
		_current_attack_damage = int(_current_attack_damage * 2.0)
		print("[Player] TigerFang — damage -> %d (x2)." % _current_attack_damage)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == self:
		return
	emit_signal("attack_landed", _current_attack_name, _current_attack_damage, body.global_position)
	_register_hit(_current_attack_name)

	# SnakeCoil: chain lightning to nearby enemies after the primary hit.
	# The SnakeCoil talisman may be in any slot (not necessarily the active one),
	# so search all player children for the fire_chain method.
	if snake_coil_active:
		snake_coil_active = false   # clear before the chain so it's one-shot
		for child in get_children():
			if child.has_method("fire_chain"):
				child.fire_chain(self, body, _current_attack_damage)
				break


# Called every time a hitbox overlap confirms a physical hit on a body.
# Increments combo, awards spirit (with counter bonus), resets combo timer.
func _register_hit(attack_name: String) -> void:
	# Combo counter — max display capped at 999 but internally unlimited.
	combo_count = mini(combo_count + 1, 999)
	_combo_timer = COMBO_RESET_TIME
	emit_signal("combo_updated", combo_count)

	# Spirit gain — look up base value; unknown attack names award 0.
	# _current_hit_is_counter was captured before in_counter_window was cleared,
	# so the bonus is correctly applied even though in_counter_window is false now.
	var base_spirit: float = SPIRIT_PER_ATTACK.get(attack_name, 0.0)
	var spirit_gain: float = base_spirit * COUNTER_SPIRIT_MULT if _current_hit_is_counter else base_spirit
	spirit = minf(spirit + spirit_gain, SPIRIT_MAX)
	emit_signal("spirit_updated", spirit, SPIRIT_MAX)
	_check_overdrive_enter()
	# Accumulate spirit gained into the run-wide tracker (AutoLoad).
	if spirit_gain > 0.0:
		RunStats.spirit_collected += spirit_gain


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
	_current_hit_is_counter = in_counter_window
	var base_dmg: int = int(DAMAGE * stance_damage_mult)
	_current_attack_damage = int(base_dmg * COUNTER_DAMAGE_MULT) if in_counter_window else base_dmg
	in_counter_window = false
	_apply_damage_flags()
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
	_current_hit_is_counter = in_counter_window
	var base_dmg: int = int(DAMAGE * stance_damage_mult)
	_current_attack_damage = int(base_dmg * COUNTER_DAMAGE_MULT) if in_counter_window else base_dmg
	in_counter_window = false
	_apply_damage_flags()
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
	_current_hit_is_counter = in_counter_window
	var base_dmg: int = int(DAMAGE * stance_damage_mult)
	_current_attack_damage = int(base_dmg * COUNTER_DAMAGE_MULT) if in_counter_window else base_dmg
	in_counter_window = false
	_apply_damage_flags()
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
	_current_hit_is_counter = boosted
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
	_apply_damage_flags()
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
# Overdrive helpers — triggered when spirit reaches SPIRIT_MAX (100).
# Visual only for now; gameplay effects are Phase 3.
# Uses a self-contained modulate tween on the sprite. The tween loops a gold
# pulse independently of the block-flash and talisman tints; when overdrive
# ends the sprite modulate is restored to Color.WHITE so talisman tints can
# resume their own tweens normally.
# ---------------------------------------------------------------------------

func _check_overdrive_enter() -> void:
	if _in_overdrive or spirit < OVERDRIVE_THRESHOLD:
		return
	_in_overdrive = true
	_start_overdrive_pulse()


func _check_overdrive_exit() -> void:
	if not _in_overdrive or spirit > OVERDRIVE_RELEASE:
		return
	_in_overdrive = false
	if _overdrive_tween != null and _overdrive_tween.is_valid():
		_overdrive_tween.kill()
	_overdrive_tween = null
	# Return sprite to neutral white so talisman tints work without fighting.
	sprite.modulate = Color.WHITE


func _start_overdrive_pulse() -> void:
	if _overdrive_tween != null and _overdrive_tween.is_valid():
		_overdrive_tween.kill()
	_overdrive_tween = create_tween()
	_overdrive_tween.set_loops()   # infinite loop
	# Pulse between a warm gold tint and a brighter gold.
	_overdrive_tween.tween_property(sprite, "modulate", Color(1.8, 1.4, 0.2, 1.0), 0.25)
	_overdrive_tween.tween_property(sprite, "modulate", Color(1.0, 0.8, 0.1, 1.0), 0.25)


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
	# DemonSeal: absorb this hit entirely, then detonate around the player.
	if demon_seal_active:
		demon_seal_active = false
		for child in get_children():
			if child.has_method("demon_seal_explode"):
				child.demon_seal_explode(self)
				break
		return
	_is_lunging = false
	_disable_hitbox()
	state = State.HURT
	velocity = knockback_vel
	# Deduct HP and notify HUD. Block path returns early above, so this only
	# fires for unblocked, non-dodge hits.
	current_hp = max(0, current_hp - damage)
	emit_signal("health_updated", current_hp, max_hp)
	if current_hp <= 0:
		die()


# ---------------------------------------------------------------------------
# Healing / upgrades — used by shops and shrines (spend gold for effect).
# ---------------------------------------------------------------------------

## Restore up to `amount` HP, capped at max_hp. Emits health_updated.
func heal(amount: int) -> void:
	if amount <= 0 or state == State.DEAD:
		return
	current_hp = mini(current_hp + amount, max_hp)
	emit_signal("health_updated", current_hp, max_hp)


## Permanently raise max_hp and grant the same amount of current HP.
func add_max_hp(amount: int) -> void:
	if amount <= 0:
		return
	max_hp += amount
	current_hp = mini(current_hp + amount, max_hp)
	emit_signal("health_updated", current_hp, max_hp)


## Adjust max_hp by a signed delta (temptation curses pass a negative value).
## On an increase the extra HP is granted; on a decrease current HP is clamped.
## max_hp never drops below 1.
func modify_max_hp(delta: int) -> void:
	if delta == 0:
		return
	max_hp = maxi(1, max_hp + delta)
	if delta > 0:
		current_hp = mini(current_hp + delta, max_hp)
	else:
		current_hp = mini(current_hp, max_hp)
	emit_signal("health_updated", current_hp, max_hp)


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

	# Kill any active overdrive tween so the death flash is not fought.
	if _overdrive_tween != null and _overdrive_tween.is_valid():
		_overdrive_tween.kill()
	_overdrive_tween = null

	# Red full-body flash: bright red → deep red → fade dark over ~0.4 s.
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(3.0, 0.2, 0.2, 1.0), 0.05)
	tween.tween_property(sprite, "modulate", Color(1.2, 0.05, 0.05, 1.0), 0.15)
	tween.tween_property(sprite, "modulate", Color(0.3, 0.0, 0.0, 0.6), 0.20)

	emit_signal("player_died")
