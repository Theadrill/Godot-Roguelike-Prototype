@tool
extends EditorInspectorPlugin

func _can_handle(object: Object) -> bool:
	return object != null and object.get_script() != null and object.get_script().resource_path.ends_with("weapon_socket_calibrator.gd")

func _parse_property(object: Object, _type: Variant.Type, name: String, _hint_type: PropertyHint, _hint_string: String, _usage_flags: int, _wide: bool) -> bool:
	if name == "btn_nudge_x_minus_1":
		var calibrator = object
		var container := VBoxContainer.new()
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var grid := GridContainer.new()
		grid.columns = 2
		grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Linha 1: X (1.0 px)
		_add_button(grid, "◄ -1.0 px (X)", func(): calibrator._nudge_x(-1.0))
		_add_button(grid, "► +1.0 px (X)", func(): calibrator._nudge_x(1.0))

		# Linha 2: X (0.1 px)
		_add_button(grid, "◄ -0.1 px (X)", func(): calibrator._nudge_x(-0.1))
		_add_button(grid, "► +0.1 px (X)", func(): calibrator._nudge_x(0.1))

		# Linha 3: Y (1.0 px)
		_add_button(grid, "▲ -1.0 px (Y)", func(): calibrator._nudge_y(-1.0))
		_add_button(grid, "▼ +1.0 px (Y)", func(): calibrator._nudge_y(1.0))

		# Linha 4: Y (0.1 px)
		_add_button(grid, "▲ -0.1 px (Y)", func(): calibrator._nudge_y(-0.1))
		_add_button(grid, "▼ +0.1 px (Y)", func(): calibrator._nudge_y(0.1))

		container.add_child(grid)
		add_custom_control(container)
		return true
	elif name.begins_with("btn_nudge_"):
		return true
	return false

func _add_button(parent: Control, text: String, on_click: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(on_click)
	parent.add_child(btn)
