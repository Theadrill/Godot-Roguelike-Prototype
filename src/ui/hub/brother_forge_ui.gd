class_name BrotherForgeUI
extends CanvasLayer

const GamepadPromptBar = preload("res://src/ui/components/gamepad_prompt_bar.gd")

signal closed

@onready var weapon_1_level_label: Label = $MainPanel/ScrollContainer/VBox/Item1/LevelLabel
@onready var weapon_1_req_label: Label = $MainPanel/ScrollContainer/VBox/Item1/ReqLabel
@onready var btn_upgrade_weapon_1: Button = $MainPanel/ScrollContainer/VBox/Item1/BtnUpgrade

@onready var weapon_2_level_label: Label = $MainPanel/ScrollContainer/VBox/Item2/LevelLabel
@onready var weapon_2_req_label: Label = $MainPanel/ScrollContainer/VBox/Item2/ReqLabel
@onready var btn_upgrade_weapon_2: Button = $MainPanel/ScrollContainer/VBox/Item2/BtnUpgrade

@onready var prompt_bar: GamepadPromptBar = $MainPanel/GamepadPromptBar

func _ready() -> void:
	visible = false
	_setup_buttons()

func _setup_buttons() -> void:
	btn_upgrade_weapon_1.pressed.connect(func() -> void: _on_weapon_upgrade("sword"))
	btn_upgrade_weapon_2.pressed.connect(func() -> void: _on_weapon_upgrade("bow"))
	
	var btn_close: Button = $MainPanel/TopBar/BtnClose
	if btn_close:
		btn_close.pressed.connect(close_ui)

func open_ui() -> void:
	visible = true
	_refresh_display()
	await get_tree().process_frame
	btn_upgrade_weapon_1.grab_focus()

func close_ui() -> void:
	visible = false
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_ui()

func _on_weapon_upgrade(weapon_id: String) -> void:
	if weapon_id == "sword":
		if ProgressionManager.weapon_sword_duplicates >= 2:
			ProgressionManager.weapon_sword_duplicates -= 2
			ProgressionManager.weapon_sword_level += 1
			ProgressionManager.permanent_upgrades_updated.emit()
	elif weapon_id == "bow":
		if ProgressionManager.weapon_bow_duplicates >= 2:
			ProgressionManager.weapon_bow_duplicates -= 2
			ProgressionManager.weapon_bow_level += 1
			ProgressionManager.permanent_upgrades_updated.emit()
	_refresh_display()

func _refresh_display() -> void:
	if prompt_bar:
		prompt_bar.refresh_prompts()

	# 1. Espada Rústica
	var sword_dmg: float = ProgressionManager.get_sword_base_damage()
	weapon_1_level_label.text = "Nível " + str(ProgressionManager.weapon_sword_level) + " (Dano: " + str(sword_dmg) + ")"
	weapon_1_req_label.text = "Receitas Repetidas: " + str(ProgressionManager.weapon_sword_duplicates) + "/2"
	btn_upgrade_weapon_1.disabled = (ProgressionManager.weapon_sword_duplicates < 2)

	# 2. Arco de Caça
	var bow_dmg: float = ProgressionManager.get_bow_base_damage()
	weapon_2_level_label.text = "Nível " + str(ProgressionManager.weapon_bow_level) + " (Dano: " + str(bow_dmg) + ")"
	weapon_2_req_label.text = "Receitas Repetidas: " + str(ProgressionManager.weapon_bow_duplicates) + "/2"
	btn_upgrade_weapon_2.disabled = (ProgressionManager.weapon_bow_duplicates < 2)
