class_name TouchOfDeathUI
extends CanvasLayer

const GamepadPromptBar = preload("res://src/ui/components/gamepad_prompt_bar.gd")

signal blessing_chosen(blessing_id: String)
signal closed

@onready var btn_choose_1: Button = $MainPanel/ScrollContainer/VBox/Item1/BtnChoose
@onready var btn_choose_2: Button = $MainPanel/ScrollContainer/VBox/Item2/BtnChoose
@onready var btn_skip: Button = $MainPanel/ScrollContainer/VBox/ItemSkip/BtnSkip
@onready var prompt_bar: GamepadPromptBar = $MainPanel/GamepadPromptBar

func _ready() -> void:
	visible = false
	btn_choose_1.pressed.connect(func() -> void: _on_chosen("onda_espectral"))
	btn_choose_2.pressed.connect(func() -> void: _on_chosen("olhar_da_ruina"))
	btn_skip.pressed.connect(func() -> void: _on_chosen(""))

	var btn_close: Button = $MainPanel/TopBar.get_node_or_null("BtnClose") as Button
	if btn_close:
		btn_close.pressed.connect(close_ui)

func open_ui() -> void:
	visible = true
	if prompt_bar:
		prompt_bar.refresh_prompts()
	await get_tree().process_frame
	btn_choose_1.grab_focus()

func close_ui() -> void:
	visible = false
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_ui()

func _on_chosen(blessing_id: String) -> void:
	ProgressionManager.select_death_blessing(blessing_id)
	visible = false
	blessing_chosen.emit(blessing_id)
