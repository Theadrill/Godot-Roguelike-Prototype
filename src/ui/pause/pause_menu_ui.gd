class_name PauseMenuUI
extends CanvasLayer

## Menu de Pausa Oficial: Acessível via ESC (Teclado) ou Start (Gamepad).
## Opções: Continuar, Painel DEV / Métricas, Salvar e Sair, Recarregar do Zero.

@onready var btn_resume: Button = $MainPanel/VBoxContainer/BtnResume
@onready var btn_dev_menu: Button = $MainPanel/VBoxContainer/BtnDevMenu
@onready var btn_save_quit: Button = $MainPanel/VBoxContainer/BtnSaveQuit
@onready var btn_restart: Button = $MainPanel/VBoxContainer/BtnRestart
@onready var prompt_bar: GamepadPromptBar = $MainPanel/GamepadPromptBar

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buttons()

func _setup_buttons() -> void:
	btn_resume.pressed.connect(close_pause_menu)
	btn_dev_menu.pressed.connect(_on_dev_menu_pressed)
	btn_save_quit.pressed.connect(_on_save_quit_pressed)
	btn_restart.pressed.connect(_on_restart_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if not visible and _is_any_modal_open():
		return

	if event.is_action_pressed("pause_game"):
		get_viewport().set_input_as_handled()
		if visible:
			close_pause_menu()
		else:
			_try_open_pause_menu()
	elif visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_pause_menu()

func _is_any_modal_open() -> bool:
	for node in get_tree().get_nodes_in_group("modal_ui"):
		if "visible" in node and node.visible:
			return true
	return false

func _try_open_pause_menu() -> void:
	# Não abre se qualquer janela modal estiver aberta
	if _is_any_modal_open():
		return

	open_pause_menu()

func open_pause_menu() -> void:
	visible = true
	get_tree().paused = true
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.is_input_locked = true
		player.velocity = Vector2.ZERO
	if prompt_bar:
		prompt_bar.refresh_prompts()
	await get_tree().process_frame
	btn_resume.grab_focus()

func close_pause_menu() -> void:
	Input.action_release("slide")
	Input.action_release("roll")
	Input.action_release("ui_cancel")
	visible = false
	get_tree().paused = false
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.is_input_locked = false

func _on_dev_menu_pressed() -> void:
	var debug_panel = get_tree().root.find_child("DebugMetricsPanel", true, false)
	if debug_panel:
		visible = false
		debug_panel.open_from_pause_menu()

func _on_save_quit_pressed() -> void:
	ProgressionManager.save_profile()
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.is_input_locked = true
		player.velocity = Vector2.ZERO
	get_tree().quit(0)

func _on_restart_pressed() -> void:
	ProgressionManager.save_profile()
	ProgressionManager.reset_daily_run()
	get_tree().paused = false
	var player := get_tree().get_first_node_in_group("player") as Player
	if player:
		player.is_input_locked = false
	get_tree().change_scene_to_file("res://src/world/hub/family_house.tscn")
