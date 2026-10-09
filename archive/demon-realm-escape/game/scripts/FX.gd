## FX.gd — AutoLoad juice helper: screen shake, hitstop, and particle bursts.
##
## Call from anywhere:
##   FX.shake(6.0)                       # kick the camera
##   FX.hitstop(0.06)                    # brief time freeze on impact
##   FX.spark(pos, Color.ORANGE, 12)     # one-shot particle burst at a world pos
##
## The Player registers its Camera2D via FX.register_camera() on _ready.
##
## AutoLoad name: FX
## Register in project.godot: autoload/FX="*res://scripts/FX.gd"

extends Node

# ---------------------------------------------------------------------------
# Screen shake
# ---------------------------------------------------------------------------
var _camera: Camera2D = null
var _shake_strength: float = 0.0
const SHAKE_DECAY: float = 58.0   # pixels per second the shake fades

# ---------------------------------------------------------------------------
# Hitstop
# ---------------------------------------------------------------------------
var _hitstop_token: int = 0


func _process(delta: float) -> void:
	if _shake_strength <= 0.0:
		return
	if not is_instance_valid(_camera):
		_shake_strength = 0.0
		return
	_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * _shake_strength
	_shake_strength = move_toward(_shake_strength, 0.0, SHAKE_DECAY * delta)
	if _shake_strength <= 0.1:
		_shake_strength = 0.0
		_camera.offset = Vector2.ZERO


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## The Player calls this so shake can drive its camera.
func register_camera(cam: Camera2D) -> void:
	_camera = cam


## Kick the camera. Repeated calls take the strongest pending strength.
func shake(strength: float) -> void:
	_shake_strength = maxf(_shake_strength, strength)


## Briefly slow time for impact. Uses a real-time (time-scale-ignoring) timer so
## the freeze has a fixed wall-clock length. Overlapping calls are token-guarded
## so an earlier, shorter hitstop can't restore time mid-way through a later one.
func hitstop(duration: float = 0.06, scale: float = 0.05) -> void:
	_hitstop_token += 1
	var my_token: int = _hitstop_token
	Engine.time_scale = scale
	# create_timer(sec, process_always, process_in_physics, ignore_time_scale)
	await get_tree().create_timer(duration, true, false, true).timeout
	if my_token == _hitstop_token:
		Engine.time_scale = 1.0


## One-shot particle burst at a world position, parented to the current scene.
func spark(world_pos: Vector2, color: Color = Color.WHITE, amount: int = 10, speed: float = 150.0) -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		return

	var p: CPUParticles2D = CPUParticles2D.new()
	p.emitting = false
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = 0.35
	p.direction = Vector2.ZERO
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.4
	p.initial_velocity_max = speed
	p.gravity = Vector2.ZERO
	p.damping_min = 40.0
	p.damping_max = 80.0
	p.scale_amount_min = 1.5
	p.scale_amount_max = 3.0
	p.color = color
	p.z_index = 10

	scene.add_child(p)
	p.global_position = world_pos
	p.emitting = true

	# Free once the burst has finished playing.
	get_tree().create_timer(0.8).timeout.connect(p.queue_free)
