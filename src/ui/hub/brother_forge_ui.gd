class_name BrotherForgeUI
extends CanvasLayer

signal closed(did_upgrade: bool)

@onready var weapon_1_level_label: Label = $MainPanel/ScrollContainer/VBox/Item1/LevelLabel
@onready var weapon_1_req_label: Label = $MainPanel/ScrollContainer/VBox/Item1/ReqLabel
@onready var btn_upgrade_weapon_1: Button = $MainPanel/ScrollContainer/VBox/Item1/BtnUpgrade

@onready var weapon_2_level_label: Label = $MainPanel/ScrollContainer/VBox/Item2/LevelLabel
@onready var weapon_2_req_label: Label = $MainPanel/ScrollContainer/VBox/Item2/ReqLabel
@onready var btn_upgrade_weapon_2: Button = $MainPanel/ScrollContainer/VBox/Item2/BtnUpgrade

@onready var prompt_bar: GamepadPromptBar = $MainPanel/GamepadPromptBar

var did_upgrade_weapon: bool = false

func _ready() -> void:
	visible = false
	add_to_group("modal_ui")
	_setup_buttons()

func _setup_buttons() -> void:
	btn_upgrade_weapon_1.pressed.connect(func() -> void: _on_weapon_upgrade("sword"))
	btn_upgrade_weapon_2.pressed.connect(func() -> void: _on_weapon_upgrade("bow"))
	
	var btn_close: Button = $MainPanel/TopBar/BtnClose
	if btn_close:
		btn_close.pressed.connect(close_ui)

func open_ui() -> void:
	visible = true
	did_upgrade_weapon = false
	_refresh_display()
	await get_tree().process_frame
	btn_upgrade_weapon_1.grab_focus()

func close_ui() -> void:
	visible = false
	closed.emit(did_upgrade_weapon)

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
			did_upgrade_weapon = true
	elif weapon_id == "bow":
		if ProgressionManager.weapon_bow_duplicates >= 2:
			ProgressionManager.weapon_bow_duplicates -= 2
			ProgressionManager.weapon_bow_level += 1
			ProgressionManager.permanent_upgrades_updated.emit()
			did_upgrade_weapon = true
	_refresh_display()

func _refresh_display() -> void:
	if prompt_bar:
		prompt_bar.refresh_prompts()

	# 1. Espada Rústica
	var sword_dmg: float = ProgressionManager.get_sword_base_damage()
	weapon_1_level_label.text = tr("UI_FORGE_LEVEL_DMG_FMT") % [ProgressionManager.weapon_sword_level, str(sword_dmg)]
	weapon_1_req_label.text = tr("UI_FORGE_RECIPES_REQ_FMT") % ProgressionManager.weapon_sword_duplicates
	btn_upgrade_weapon_1.disabled = (ProgressionManager.weapon_sword_duplicates < 2)

	# 2. Arco de Caça
	var bow_dmg: float = ProgressionManager.get_bow_base_damage()
	weapon_2_level_label.text = tr("UI_FORGE_LEVEL_DMG_FMT") % [ProgressionManager.weapon_bow_level, str(bow_dmg)]
	weapon_2_req_label.text = tr("UI_FORGE_RECIPES_REQ_FMT") % ProgressionManager.weapon_bow_duplicates
	btn_upgrade_weapon_2.disabled = (ProgressionManager.weapon_bow_duplicates < 2)
