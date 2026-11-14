@tool
extends EditorInspectorPlugin

func _can_handle(object: Object) -> bool:
	return object != null and object.get_script() != null and object.get_script().resource_path.ends_with("weapon_socket_calibrator.gd")

func _parse_property(object: Object, _type: Variant.Type, name: String, _hint_type: PropertyHint, _hint_string: String, _usage_flags: int, _wide: bool) -> bool:
	if name == "btn_nudge_x_minus_1":
		var calibrator = object
		var container := VBoxContainer.new()
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_theme_constant_override("separation", 8)

		# Cruz 1: Ajuste Fino (0.1 px)
		var dpad_fine := _create_cross_dpad("Ajuste Fino (±0.1 px)", 0.1, calibrator, false)
		container.add_child(dpad_fine)

		var sep := HSeparator.new()
		container.add_child(sep)

		# Cruz 2: Ajuste Rápido (1.0 px)
		var dpad_coarse := _create_cross_dpad("Ajuste Rápido (±1.0 px)", 1.0, calibrator, false)
		container.add_child(dpad_coarse)

		add_custom_control(container)
		return true
	elif name.begins_with("btn_nudge_"):
		return true
	elif name == "btn_slash_x_m1":
		var calibrator = object
		var container := VBoxContainer.new()
		container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		container.add_theme_constant_override("separation", 8)

		# Cruz 1: Ajuste Fino do Slash (0.1 px)
		var dpad_fine := _create_cross_dpad("Ajuste Fino (±0.1 px)", 0.1, calibrator, true)
		container.add_child(dpad_fine)

		var sep := HSeparator.new()
		container.add_child(sep)

		# Cruz 2: Ajuste Rápido do Slash (1.0 px)
		var dpad_coarse := _create_cross_dpad("Ajuste Rápido (±1.0 px)", 1.0, calibrator, true)
		container.add_child(dpad_coarse)

		add_custom_control(container)
		return true
	elif name.begins_with("btn_slash_"):
		return true
	return false

func _create_cross_dpad(title: String, step_val: float, calibrator: Object, is_slash: bool = false) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 3)

	var label := Label.new()
	label.text = title
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color(0.75, 0.8, 0.9))
	box.add_child(label)

	var step_str := ("%.1f" if step_val < 1.0 else "%.0f") % step_val

	# Linha 1: 1 botão centralizado (▲ Y)
	var row1 := HBoxContainer.new()
	row1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_spacer(row1, 1)
	_add_nudge_btn(row1, "▲  -%s px" % step_str, func():
		if is_slash: calibrator._nudge_slash_y(-step_val)
		else: calibrator._nudge_y(-step_val)
	, 2)
	_add_spacer(row1, 1)
	box.add_child(row1)

	# Linha 2: 2 botões (◄ X e ► X)
	var row2 := HBoxContainer.new()
	row2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_nudge_btn(row2, "◄  -%s px" % step_str, func():
		if is_slash: calibrator._nudge_slash_x(-step_val)
		else: calibrator._nudge_x(-step_val)
	, 1)
	_add_nudge_btn(row2, "►  +%s px" % step_str, func():
		if is_slash: calibrator._nudge_slash_x(step_val)
		else: calibrator._nudge_x(step_val)
	, 1)
	box.add_child(row2)

	# Linha 3: 1 botão centralizado (▼ Y)
	var row3 := HBoxContainer.new()
	row3.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_add_spacer(row3, 1)
	_add_nudge_btn(row3, "▼  +%s px" % step_str, func():
		if is_slash: calibrator._nudge_slash_y(step_val)
		else: calibrator._nudge_y(step_val)
	, 2)
	_add_spacer(row3, 1)
	box.add_child(row3)

	return box

func _add_spacer(parent: Control, stretch: int) -> void:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.size_flags_stretch_ratio = stretch
	parent.add_child(spacer)

func _add_nudge_btn(parent: Control, text: String, on_click: Callable, stretch: int) -> void:
	var btn := Button.new()
	btn.text = text
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.size_flags_stretch_ratio = stretch
	btn.pressed.connect(on_click)
	parent.add_child(btn)
