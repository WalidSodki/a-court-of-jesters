extends Node
## Registers all input actions in code (controller-first, keyboard fallback).
##
## Doing this here — rather than in the editor's Input Map — keeps the demo
## self-contained and easy to read/extend in one place. Runs before the main
## scene because it is the first autoload. Actions are only added if missing,
## so it is safe if the team later moves these into project settings.

func _ready() -> void:
	# Movement: keyboard (WASD + arrows), D-pad, and left analog stick.
	_action("move_up",    [_key(KEY_W), _key(KEY_UP)],    [_btn(JOY_BUTTON_DPAD_UP)],    [_axis(JOY_AXIS_LEFT_Y, -1.0)])
	_action("move_down",  [_key(KEY_S), _key(KEY_DOWN)],  [_btn(JOY_BUTTON_DPAD_DOWN)],  [_axis(JOY_AXIS_LEFT_Y, 1.0)])
	_action("move_left",  [_key(KEY_A), _key(KEY_LEFT)],  [_btn(JOY_BUTTON_DPAD_LEFT)],  [_axis(JOY_AXIS_LEFT_X, -1.0)])
	_action("move_right", [_key(KEY_D), _key(KEY_RIGHT)], [_btn(JOY_BUTTON_DPAD_RIGHT)], [_axis(JOY_AXIS_LEFT_X, 1.0)])

	# Hold to move faster.
	_action("run", [_key(KEY_SHIFT)], [_btn(JOY_BUTTON_RIGHT_SHOULDER)])

	# Confirm / talk / advance dialogue.
	_action("interact", [_key(KEY_SPACE), _key(KEY_E), _key(KEY_ENTER)], [_btn(JOY_BUTTON_A)])

	# Open the inventory.
	_action("inventory", [_key(KEY_TAB), _key(KEY_I)], [_btn(JOY_BUTTON_Y)])

	# Open the journal (discovered clues).
	_action("journal", [_key(KEY_J)], [_btn(JOY_BUTTON_X)])

	# Back / close menus.
	_action("cancel", [_key(KEY_BACKSPACE)], [_btn(JOY_BUTTON_B)])

	# Pause.
	_action("pause", [_key(KEY_ESCAPE)], [_btn(JOY_BUTTON_START)])

	# Developer overlay toggle (Escape included for now, alongside F1).
	_action("debug_toggle", [_key(KEY_F1), _key(KEY_ESCAPE)], [_btn(JOY_BUTTON_BACK)])


func _action(name: String, keys: Array, buttons: Array, motions: Array = []) -> void:
	if InputMap.has_action(name):
		return
	InputMap.add_action(name, 0.5)
	for e in keys:
		InputMap.action_add_event(name, e)
	for e in buttons:
		InputMap.action_add_event(name, e)
	for e in motions:
		InputMap.action_add_event(name, e)


func _key(keycode: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = keycode
	return e


func _btn(button_index: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = button_index
	return e


func _axis(axis: int, value: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = axis
	e.axis_value = value
	return e
