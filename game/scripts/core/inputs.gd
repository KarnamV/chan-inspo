extends Node
## Registers every input action in code (keyboard + gamepad), so bindings live in one readable place.
## Layout (design/concept.md → Controls): □ light, △ heavy, ○ grab/throw, × dodge, R1 parry,
## L2 hold = chi modifier, L1 hold = talisman modifier (L1 + □/△/○ = talisman 1/2/3).

const DEADZONE := 0.25

const KEYS := {
	"move_left": [KEY_A, KEY_LEFT],
	"move_right": [KEY_D, KEY_RIGHT],
	"move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN],
	"attack_light": [KEY_J],
	"attack_heavy": [KEY_K],
	"grab": [KEY_L],
	"dodge": [KEY_SPACE],
	"parry": [KEY_I],
	"chi_mod": [KEY_SHIFT],
	"talisman_mod": [KEY_CTRL],
	"interact": [KEY_E],
	"pause": [KEY_ESCAPE],
}

const BUTTONS := {
	"attack_light": [JOY_BUTTON_X],
	"attack_heavy": [JOY_BUTTON_Y],
	"grab": [JOY_BUTTON_B],
	"dodge": [JOY_BUTTON_A],
	"parry": [JOY_BUTTON_RIGHT_SHOULDER],
	"talisman_mod": [JOY_BUTTON_LEFT_SHOULDER],
	"interact": [JOY_BUTTON_DPAD_UP],
	"pause": [JOY_BUTTON_START],
}

const AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	"chi_mod": [JOY_AXIS_TRIGGER_LEFT, 1.0],
}


func _init() -> void:
	register()


static func register() -> void:
	var actions: Array = KEYS.keys()
	for a: String in BUTTONS.keys() + AXES.keys():
		if a not in actions:
			actions.append(a)
	for action: String in actions:
		if InputMap.has_action(action):
			InputMap.erase_action(action)
		InputMap.add_action(action, DEADZONE)
		for k: int in KEYS.get(action, []):
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
		for b: int in BUTTONS.get(action, []):
			var jb := InputEventJoypadButton.new()
			jb.button_index = b
			InputMap.action_add_event(action, jb)
		if AXES.has(action):
			var jm := InputEventJoypadMotion.new()
			jm.axis = AXES[action][0]
			jm.axis_value = AXES[action][1]
			InputMap.action_add_event(action, jm)
