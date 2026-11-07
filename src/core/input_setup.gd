extends Node

## Ensures default keyboard and gamepad actions are mapped cleanly,
## and provides quick debug reload (R, F5, or Select/Back on gamepad).

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_register_action("move_left", [
		_create_key_event(KEY_A),
		_create_key_event(KEY_LEFT),
		_create_joy_motion_event(JOY_AXIS_LEFT_X, -1.0)
	])
	_register_action("move_right", [
		_create_key_event(KEY_D),
		_create_key_event(KEY_RIGHT),
		_create_joy_motion_event(JOY_AXIS_LEFT_X, 1.0)
	])
	_register_action("up", [
		_create_key_event(KEY_W),
		_create_key_event(KEY_UP),
		_create_joy_motion_event(JOY_AXIS_LEFT_Y, -1.0)
	], 0.55)
	_register_action("down", [
		_create_key_event(KEY_S),
		_create_key_event(KEY_DOWN),
		_create_joy_motion_event(JOY_AXIS_LEFT_Y, 1.0)
	], 0.55)
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
	# Botão X (Xbox) / Quadrado (PlayStation) / Botão Esquerdo Mouse / Tecla J: ARMA ATUAL
	_register_action("attack_primary", [
		_create_mouse_button_event(MOUSE_BUTTON_LEFT),
		_create_key_event(KEY_J),
		_create_joy_button_event(JOY_BUTTON_X)
	])
	# Botão Y (Xbox) / Triângulo (PlayStation) / Botão Direito Mouse / Teclas K, L: DEFESA / ESCUDO
	_register_action("defend", [
		_create_mouse_button_event(MOUSE_BUTTON_RIGHT),
		_create_key_event(KEY_K),
		_create_key_event(KEY_L),
		_create_joy_button_event(JOY_BUTTON_Y)
	])
	# Botão RB (Xbox) / R1 (PlayStation) / Tecla E / Tecla F: INTERAÇÃO
	_register_action("interact", [
		_create_key_event(KEY_E),
		_create_key_event(KEY_F),
		_create_joy_button_event(JOY_BUTTON_RIGHT_SHOULDER)
	])
	# Botão LB (Xbox) / L1 (PlayStation) / Tecla 1 (Teclado): TROCAR ARMA EQUIPADA (SWAP)
	_register_action("swap_weapon", [
		_create_key_event(KEY_1),
		_create_joy_button_event(JOY_BUTTON_LEFT_SHOULDER)
	])
	# D-Pad Down (Gamepad) / Tecla 2 (Teclado): CICLAR ARMA DE RESERVA (DEBUG)
	_register_action("cycle_weapon_debug", [
		_create_key_event(KEY_2),
		_create_joy_button_event(JOY_BUTTON_DPAD_DOWN)
	])
	# Botão Q (Teclado) / D-Pad Up (Gamepad): GARRAFA DE CHÁ DA MÃE (CURA)
	_register_action("heal", [
		_create_key_event(KEY_Q),
		_create_joy_button_event(JOY_BUTTON_DPAD_UP)
	])
	# Tecla 3 (Teclado) / D-Pad Left (Gamepad): TOGGLE MODIFICADOR REPULSÃO DO ESCUDO (DEBUG)
	_register_action("toggle_shield_repulsion_debug", [
		_create_key_event(KEY_3),
		_create_joy_button_event(JOY_BUTTON_DPAD_LEFT)
	])
	# Tecla F3 (Teclado) / Botão Select-Back (Gamepad): PAINEL DE DEBUG DE MÉTRICAS & TELEMETRIA
	_register_action("toggle_debug_metrics", [
		_create_key_event(KEY_F3),
		_create_joy_button_event(JOY_BUTTON_BACK)
	])

	# Right Analog Stick: Camera look-ahead (espiar adiante)
	_register_action("look_left", [
		_create_joy_motion_event(JOY_AXIS_RIGHT_X, -1.0),
		_create_key_event(KEY_KP_4)
	], 0.15)
	_register_action("look_right", [
		_create_joy_motion_event(JOY_AXIS_RIGHT_X, 1.0),
		_create_key_event(KEY_KP_6)
	], 0.15)
	_register_action("look_up", [
		_create_joy_motion_event(JOY_AXIS_RIGHT_Y, -1.0),
		_create_key_event(KEY_KP_8)
	], 0.15)
	_register_action("look_down", [
		_create_joy_motion_event(JOY_AXIS_RIGHT_Y, 1.0),
		_create_key_event(KEY_KP_2)
	], 0.15)

	# UI Navigation: D-Pad, Left Stick, A (Confirmar), B (Cancelar)
	_register_action("ui_accept", [
		_create_key_event(KEY_ENTER),
		_create_key_event(KEY_SPACE),
		_create_joy_button_event(JOY_BUTTON_A)
	])
	_register_action("ui_cancel", [
		_create_key_event(KEY_ESCAPE),
		_create_joy_button_event(JOY_BUTTON_B)
	])
	_register_action("ui_up", [
		_create_key_event(KEY_UP),
		_create_key_event(KEY_W),
		_create_joy_button_event(JOY_BUTTON_DPAD_UP),
		_create_joy_motion_event(JOY_AXIS_LEFT_Y, -1.0)
	], 0.4)
	_register_action("ui_down", [
		_create_key_event(KEY_DOWN),
		_create_key_event(KEY_S),
		_create_joy_button_event(JOY_BUTTON_DPAD_DOWN),
		_create_joy_motion_event(JOY_AXIS_LEFT_Y, 1.0)
	], 0.4)
	_register_action("ui_left", [
		_create_key_event(KEY_LEFT),
		_create_key_event(KEY_A),
		_create_joy_button_event(JOY_BUTTON_DPAD_LEFT),
		_create_joy_motion_event(JOY_AXIS_LEFT_X, -1.0)
	], 0.4)
	_register_action("ui_right", [
		_create_key_event(KEY_RIGHT),
		_create_key_event(KEY_D),
		_create_joy_button_event(JOY_BUTTON_DPAD_RIGHT),
		_create_joy_motion_event(JOY_AXIS_LEFT_X, 1.0)
	], 0.4)

func _unhandled_input(event: InputEvent) -> void:
	# Quick reload inside game window: R, F5, or Select/Back on Gamepad
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.physical_keycode == KEY_R or event.physical_keycode == KEY_F5:
			get_tree().reload_current_scene()
	elif event is InputEventJoypadButton and event.is_pressed():
		if event.button_index == JOY_BUTTON_BACK: # Botão Select / View / Share
			get_tree().reload_current_scene()

func _register_action(action_name: StringName, default_events: Array[InputEvent], deadzone: float = 0.5) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name, deadzone)
	else:
		InputMap.action_set_deadzone(action_name, deadzone)
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
