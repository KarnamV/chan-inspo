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

## Godot 4.7's built-in ui_accept / ui_cancel have no gamepad buttons, so menus ignore A / B
## unless we add them (added on top of the defaults, not replacing them).
const UI_BUTTONS := {
	"ui_accept": [JOY_BUTTON_A],
	"ui_cancel": [JOY_BUTTON_B],
}

const AXES := {
	"move_left": [JOY_AXIS_LEFT_X, -1.0],
	"move_right": [JOY_AXIS_LEFT_X, 1.0],
	"move_up": [JOY_AXIS_LEFT_Y, -1.0],
	"move_down": [JOY_AXIS_LEFT_Y, 1.0],
	"chi_mod": [JOY_AXIS_TRIGGER_LEFT, 1.0],
}


## Button names shown in prompts. Pad names follow the Xbox layout (Windows default).
const KEY_NAMES := {
	"move": "WASD", "attack_light": "J", "attack_heavy": "K", "grab": "L", "dodge": "Space", "parry": "I",
	"chi_mod": "Shift", "talisman_mod": "Ctrl", "interact": "E", "pause": "Esc",
}
const PAD_NAMES := {
	"move": "Left stick", "attack_light": "X", "attack_heavy": "Y", "grab": "B", "dodge": "A", "parry": "RB",
	"chi_mod": "LT", "talisman_mod": "LB", "interact": "D-pad Up", "pause": "Start",
}

signal device_changed(pad: bool)

## True after the last input came from a gamepad (prompts and rumble follow it).
var using_pad := false


func _init() -> void:
	register()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	using_pad = not Input.get_connected_joypads().is_empty()
	Input.joy_connection_changed.connect(func(_d: int, connected: bool) -> void:
		_set_pad(connected or not Input.get_connected_joypads().is_empty()))


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		_set_pad(true)
	elif event is InputEventKey or event is InputEventMouseButton:
		_set_pad(false)


func _set_pad(pad: bool) -> void:
	if pad != using_pad:
		using_pad = pad
		device_changed.emit(pad)


## Prompt name of an action's button for the current device, e.g. "X" or "J".
func label(action: StringName) -> String:
	return (PAD_NAMES if using_pad else KEY_NAMES).get(String(action), String(action))


## "LB+X" / "Ctrl+J"
func combo(mod: StringName, action: StringName) -> String:
	return "%s+%s" % [label(mod), label(action)]


## One-line control reference for the current device.
func controls_line() -> String:
	return "%s move · %s light · %s heavy · %s grab/throw · %s dodge · %s parry · hold %s chi · hold %s talismans · %s pause" % [
		label(&"move"), label(&"attack_light"), label(&"attack_heavy"), label(&"grab"), label(&"dodge"),
		label(&"parry"), label(&"chi_mod"), label(&"talisman_mod"), label(&"pause")]


var _mute_until := -1


## Call when a menu closes and unpauses: the button that confirmed it (A = dodge, X = light)
## must not also act in the game. Releasing alone isn't enough: since Godot 4.3
## is_action_just_pressed stays true for the rest of the frame, so presses are muted for two frames.
func release_gameplay() -> void:
	for action: String in BUTTONS:
		Input.action_release(action)
	_mute_until = Engine.get_process_frames() + 1


## Input.is_action_just_pressed, minus the press that just closed a menu. Gameplay code uses this.
func just_pressed(action: StringName) -> bool:
	return Engine.get_process_frames() > _mute_until and Input.is_action_just_pressed(action)


## Gamepad rumble (no-op on keyboard). weak/strong 0..1.
func rumble(weak: float, strong: float, seconds: float) -> void:
	if not using_pad:
		return
	for d in Input.get_connected_joypads():
		Input.start_joy_vibration(d, weak, strong, seconds)


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
	for action: String in UI_BUTTONS:
		for b: int in UI_BUTTONS[action]:
			var jb := InputEventJoypadButton.new()
			jb.button_index = b
			if not InputMap.action_has_event(action, jb):
				InputMap.action_add_event(action, jb)
