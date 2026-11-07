class_name DeathScreen
extends CanvasLayer

signal respawn_requested
signal main_menu_requested

@onready var spiral_overlay: ColorRect = $SpiralOverlay
@onready var content_container: CenterContainer = $ContentContainer
@onready var title_label: Label = $ContentContainer/VBoxContainer/TitleLabel
@onready var subtitle_label: Label = $ContentContainer/VBoxContainer/SubtitleLabel
@onready var buttons_container: HBoxContainer = $ContentContainer/VBoxContainer/ButtonsContainer
@onready var respawn_btn_label: Label = $ContentContainer/VBoxContainer/ButtonsContainer/RespawnOption/Label
@onready var menu_btn_label: Label = $ContentContainer/VBoxContainer/ButtonsContainer/MenuOption/Label

var is_active: bool = false
var can_accept_input: bool = false
var _seq_tween: Tween = null
var _material: ShaderMaterial = null
var _vortex_time: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	if spiral_overlay and spiral_overlay.material:
		_material = spiral_overlay.material as ShaderMaterial
		if _material:
			_material.set_shader_parameter("progress", 0.0)
			_material.set_shader_parameter("vortex_time", 0.0)
	
	if content_container:
		content_container.modulate.a = 0.0
	if buttons_container:
		buttons_container.modulate.a = 0.0
	
	_update_localized_texts()

func _process(delta: float) -> void:
	if is_active and _material:
		_vortex_time += delta
		_material.set_shader_parameter("vortex_time", _vortex_time)

func _update_localized_texts() -> void:
	if title_label:
		title_label.text = tr("MSG_DEATH_TITLE")
	if subtitle_label:
		subtitle_label.text = tr("MSG_DEATH_SUBTITLE")
	if respawn_btn_label:
		respawn_btn_label.text = tr("UI_DEATH_RESPAWN")
	if menu_btn_label:
		menu_btn_label.text = tr("UI_DEATH_MAIN_MENU")

func play_death_sequence() -> void:
	if is_active:
		return
	is_active = true
	can_accept_input = false
	visible = true
	_update_localized_texts()

	if content_container:
		content_container.modulate.a = 0.0
	if buttons_container:
		buttons_container.modulate.a = 0.0

	# 1. Slow-motion dramático (0.2x)
	Engine.time_scale = 0.2

	if _seq_tween and _seq_tween.is_valid():
		_seq_tween.kill()

	# Execução contínua ignorando time_scale reduzido
	_seq_tween = create_tween()
	_seq_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# Fase 1: Vórtice Espiral se expande e engole a tela em 1.1s
	if _material:
		_material.set_shader_parameter("progress", 0.0)
		_seq_tween.tween_method(
			func(val: float) -> void: _material.set_shader_parameter("progress", val),
			0.0, 1.0, 1.1
		).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Fase 2: Restaura velocidade normal do motor
	_seq_tween.tween_callback(func() -> void:
		Engine.time_scale = 1.0
	)

	# Fase 3: Fade in solene no título e subtítulo (0.6s)
	if content_container:
		_seq_tween.tween_property(content_container, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	# Pequena pausa dramática
	_seq_tween.tween_interval(0.25)

	# Fase 4: Fade in nos botões A e B com liberação de input
	if buttons_container:
		_seq_tween.tween_property(buttons_container, "modulate:a", 1.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	_seq_tween.tween_callback(func() -> void:
		can_accept_input = true
	)

func _unhandled_input(event: InputEvent) -> void:
	if not is_active or not can_accept_input:
		return

	# Opção A: Voltar para o Espaço Liminar (Gamepad A / Espaço / Enter / Tecla E)
	var is_a_pressed := false
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_A:
		is_a_pressed = true
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_E):
		is_a_pressed = true
	elif event.is_action_pressed("jump") or event.is_action_pressed("ui_accept"):
		is_a_pressed = true

	if is_a_pressed:
		get_viewport().set_input_as_handled()
		_on_respawn_chosen()
		return

	# Opção B: Menu Principal (Gamepad B / Esc / Backspace)
	var is_b_pressed := false
	if event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_B:
		is_b_pressed = true
	elif event is InputEventKey and event.pressed and (event.keycode == KEY_ESCAPE or event.keycode == KEY_BACKSPACE):
		is_b_pressed = true
	elif event.is_action_pressed("roll") or event.is_action_pressed("ui_cancel"):
		is_b_pressed = true

	if is_b_pressed:
		get_viewport().set_input_as_handled()
		_on_main_menu_chosen()
		return

func _on_respawn_chosen() -> void:
	can_accept_input = false
	var tween := create_tween()
	if content_container:
		tween.tween_property(content_container, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if spiral_overlay:
		tween.parallel().tween_property(spiral_overlay, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	visible = false
	if content_container:
		content_container.modulate.a = 1.0
	if spiral_overlay:
		spiral_overlay.modulate.a = 1.0
	is_active = false
	if _material:
		_material.set_shader_parameter("progress", 0.0)
	respawn_requested.emit()

func _on_main_menu_chosen() -> void:
	can_accept_input = false
	var tween := create_tween()
	if content_container:
		tween.tween_property(content_container, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if spiral_overlay:
		tween.parallel().tween_property(spiral_overlay, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	visible = false
	if content_container:
		content_container.modulate.a = 1.0
	if spiral_overlay:
		spiral_overlay.modulate.a = 1.0
	is_active = false
	if _material:
		_material.set_shader_parameter("progress", 0.0)
	main_menu_requested.emit()
