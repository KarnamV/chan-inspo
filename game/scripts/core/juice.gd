extends Node
## Game feel: hitstop (brief time freeze on impact) and camera shake. Kept global so any hit can
## call it without knowing about the camera.

var _shake := 0.0
var _stop_until := 0
var _slow_until := 0
var _slow_scale := 1.0
var camera: Camera3D
var enabled := true


func hitstop(seconds: float) -> void:
	if not enabled:
		return
	Engine.time_scale = 0.05
	_stop_until = Time.get_ticks_msec() + int(seconds * 1000.0)


## Slow motion for `seconds` of real time (Rabbit perfect dodge).
func slowmo(seconds: float, scale: float) -> void:
	if not enabled:
		return
	_slow_scale = scale
	_slow_until = Time.get_ticks_msec() + int(seconds * 1000.0)
	Engine.time_scale = scale


func shake(amount: float) -> void:
	_shake = maxf(_shake, amount)


func _process(delta: float) -> void:
	var now := Time.get_ticks_msec()
	if _stop_until > 0 and now >= _stop_until:
		_stop_until = 0
		Engine.time_scale = _slow_scale if _slow_until > now else 1.0
	if _slow_until > 0 and now >= _slow_until:
		_slow_until = 0
		_slow_scale = 1.0
		if _stop_until == 0:
			Engine.time_scale = 1.0
	if camera and _shake > 0.0:
		camera.h_offset = randf_range(-1, 1) * _shake * 0.3
		camera.v_offset = randf_range(-1, 1) * _shake * 0.3
		_shake = maxf(_shake - delta * 1.5, 0.0)
		if _shake == 0.0:
			camera.h_offset = 0.0
			camera.v_offset = 0.0
