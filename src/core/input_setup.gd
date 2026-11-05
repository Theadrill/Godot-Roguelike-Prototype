extends Node

## Ensures default keyboard and gamepad actions are mapped cleanly,
## and provides quick debug reload (R, F5, or Select/Back on gamepad).

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_register_action("move_left", [
		_create_key_event(KEY_A),
		_create_key_event(KEY_LEFT),
		_create_joy_button_event(JOY_BUTTON_DPAD_LEFT),
		_create_joy_motion_event(JOY_AXIS_LEFT_X, -1.0)
	])
	_register_action("move_right", [
		_create_key_event(KEY_D),
		_create_key_event(KEY_RIGHT),
		_create_joy_button_event(JOY_BUTTON_DPAD_RIGHT),
		_create_joy_motion_event(JOY_AXIS_LEFT_X, 1.0)
	])
	_register_action("down", [
		_create_key_event(KEY_S),
		_create_key_event(KEY_DOWN),
		_create_joy_button_event(JOY_BUTTON_DPAD_DOWN),
		_create_joy_motion_event(JOY_AXIS_LEFT_Y, 1.0)
	])
	# Botão A (Xbox) / X (PlayStation) / Espaço: PULO
	_register_action("jump", [
		_create_key_event(KEY_SPACE),
		_create_joy_button_event(JOY_BUTTON_A)
	])
	# Botão B (Xbox) / Círculo (PlayStation) / Shift: ROLAR
	_register_action("roll", [
		_create_key_event(KEY_SHIFT),
		_create_joy_button_event(JOY_BUTTON_B)
	])
	# Botão X (Xbox) / Quadrado (PlayStation) / Botão Esquerdo Mouse: ARMA PRIMÁRIA
	_register_action("attack_primary", [
		_create_mouse_button_event(MOUSE_BUTTON_LEFT),
		_create_joy_button_event(JOY_BUTTON_X)
	])
	# Botão Y (Xbox) / Triângulo (PlayStation) / Botão Direito Mouse: ARMA SECUNDÁRIA / ESCUDO
	_register_action("attack_secondary", [
		_create_mouse_button_event(MOUSE_BUTTON_RIGHT),
		_create_joy_button_event(JOY_BUTTON_Y)
	])

func _unhandled_input(event: InputEvent) -> void:
	# Quick reload inside game window: R, F5, or Select/Back on Gamepad
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.physical_keycode == KEY_R or event.physical_keycode == KEY_F5:
			get_tree().reload_current_scene()
	elif event is InputEventJoypadButton and event.is_pressed():
		if event.button_index == JOY_BUTTON_BACK: # Botão Select / View / Share
			get_tree().reload_current_scene()

func _register_action(action_name: StringName, default_events: Array[InputEvent]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
	for event in default_events:
		if not InputMap.action_has_event(action_name, event):
			InputMap.action_add_event(action_name, event)

func _create_key_event(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = keycode
	return event

func _create_mouse_button_event(button_index: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button_index
	return event

func _create_joy_button_event(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	return event

func _create_joy_motion_event(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event
