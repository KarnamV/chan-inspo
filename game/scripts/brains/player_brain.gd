class_name PlayerBrain
extends Brain
## Reads the controller and drives whichever body the player currently controls.
## Talisman inputs (talisman_mod + face button) go to the PlayerController instead of the body.

var controller: Node   ## PlayerController
var camera: IsoCamera
## A press made while the body is busy (mid-attack, stagger, getup) fires as soon as it can act,
## instead of being dropped.
const BUFFERED := [&"parry", &"attack_light", &"attack_heavy", &"grab", &"dodge"]
const BUFFER_TIME := 0.25
var _buffer: StringName = &""
var _buffer_t := 0.0


func _init(p_controller: Node, p_camera: IsoCamera) -> void:
	controller = p_controller
	camera = p_camera


func think(f: Fighter, delta: float) -> void:
	var v := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	f.intent_move = camera.input_to_world(v) if camera else Vector3(v.x, 0, v.y)
	if Input.is_action_pressed(&"talisman_mod"):
		for i in 4:
			var act: StringName = [&"attack_light", &"attack_heavy", &"grab", &"dodge"][i]
			if Inputs.just_pressed(act):
				controller.use_talisman(i)
		return
	if Input.is_action_pressed(&"chi_mod") and f.data.kit != &"":
		for i in 3:   # boss forms (Monkey): chi_mod + button = boss specials
			var act: StringName = [&"attack_light", &"attack_heavy", &"grab"][i]
			if Inputs.just_pressed(act):
				BossKit.special(f, i)
		return
	if Input.is_action_pressed(&"chi_mod"):
		for i in 4:
			var act: StringName = [&"attack_light", &"attack_heavy", &"grab", &"dodge"][i]
			if Inputs.just_pressed(act):
				controller.use_chi(i)
		return
	for act in BUFFERED:
		if Inputs.just_pressed(act):
			_buffer = act
			_buffer_t = BUFFER_TIME
	if _buffer == &"":
		return
	_buffer_t -= delta
	if _buffer_t <= 0.0:
		_buffer = &""
		return
	match _buffer:
		&"parry": f.request_dodge()   # parry is now the perfect dodge
		&"attack_light": f.request_light()
		&"attack_heavy": f.request_heavy()
		&"grab": f.request_grab()
		&"dodge": f.request_dodge()
	# accepted = the body changed state this frame (or queued the next combo hit)
	if f.state_t == 0.0 or (_buffer == &"attack_light" and f.queued_light):
		_buffer = &""
