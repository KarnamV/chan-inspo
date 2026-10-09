class_name PlayerBrain
extends Brain
## Reads the controller and drives whichever body the player currently controls.
## Talisman inputs (talisman_mod + face button) go to the PlayerController instead of the body.

var controller: Node   ## PlayerController
var camera: IsoCamera


func _init(p_controller: Node, p_camera: IsoCamera) -> void:
	controller = p_controller
	camera = p_camera


func think(f: Fighter, _delta: float) -> void:
	var v := Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	f.intent_move = camera.input_to_world(v) if camera else Vector3(v.x, 0, v.y)
	if Input.is_action_pressed(&"talisman_mod"):
		for i in 3:
			var act: StringName = [&"attack_light", &"attack_heavy", &"grab"][i]
			if Input.is_action_just_pressed(act):
				controller.use_talisman(i)
		return
	if Input.is_action_just_pressed(&"attack_light"):
		f.request_light()
	if Input.is_action_just_pressed(&"attack_heavy"):
		f.request_heavy()
	if Input.is_action_just_pressed(&"grab"):
		f.request_grab()
	if Input.is_action_just_pressed(&"dodge"):
		f.request_dodge()
