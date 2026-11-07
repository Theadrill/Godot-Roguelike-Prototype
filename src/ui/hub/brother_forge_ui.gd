class_name BrotherForgeUI
extends CanvasLayer

const GamepadPromptBar = preload("res://src/ui/components/gamepad_prompt_bar.gd")

signal closed

@onready var category_view: Control = $MainPanel/CategoryView
@onready var list_view_forge: Control = $MainPanel/ListViewForge
@onready var list_view_arsenal: Control = $MainPanel/ListViewArsenal

@onready var btn_cat_forge: Button = $MainPanel/CategoryView/CategoriesHBox/BtnCatForge
@onready var btn_cat_arsenal: Button = $MainPanel/CategoryView/CategoriesHBox/BtnCatArsenal

@onready var btn_back_forge: Button = $MainPanel/ListViewForge/Header/BtnBack
@onready var weapon_1_level_label: Label = $MainPanel/ListViewForge/ScrollContainer/VBox/Item1/LevelLabel
@onready var weapon_1_req_label: Label = $MainPanel/ListViewForge/ScrollContainer/VBox/Item1/ReqLabel
@onready var btn_upgrade_weapon_1: Button = $MainPanel/ListViewForge/ScrollContainer/VBox/Item1/BtnUpgrade

@onready var weapon_2_level_label: Label = $MainPanel/ListViewForge/ScrollContainer/VBox/Item2/LevelLabel
@onready var weapon_2_req_label: Label = $MainPanel/ListViewForge/ScrollContainer/VBox/Item2/ReqLabel
@onready var btn_upgrade_weapon_2: Button = $MainPanel/ListViewForge/ScrollContainer/VBox/Item2/BtnUpgrade

@onready var btn_back_arsenal: Button = $MainPanel/ListViewArsenal/Header/BtnBack

@onready var prompt_bar: GamepadPromptBar = $MainPanel/GamepadPromptBar

enum ViewState { CATEGORIES, FORGE_LIST, ARSENAL_LIST }
var current_view: ViewState = ViewState.CATEGORIES

func _ready() -> void:
	visible = false
	_setup_buttons()

func _setup_buttons() -> void:
	btn_cat_forge.pressed.connect(func() -> void: _switch_to_view(ViewState.FORGE_LIST))
	btn_cat_arsenal.pressed.connect(func() -> void: _switch_to_view(ViewState.ARSENAL_LIST))
	
	btn_back_forge.pressed.connect(func() -> void: _switch_to_view(ViewState.CATEGORIES))
	btn_back_arsenal.pressed.connect(func() -> void: _switch_to_view(ViewState.CATEGORIES))
	
	btn_upgrade_weapon_1.pressed.connect(func() -> void: _on_weapon_upgrade("sword"))
	btn_upgrade_weapon_2.pressed.connect(func() -> void: _on_weapon_upgrade("bow"))
	
	var btn_close: Button = $MainPanel/TopBar/BtnClose
	if btn_close:
		btn_close.pressed.connect(close_ui)

func open_ui() -> void:
	visible = true
	_switch_to_view(ViewState.CATEGORIES)

func close_ui() -> void:
	visible = false
	closed.emit()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if current_view != ViewState.CATEGORIES:
			_switch_to_view(ViewState.CATEGORIES)
		else:
			close_ui()

func _switch_to_view(new_view: ViewState) -> void:
	current_view = new_view
	category_view.visible = (current_view == ViewState.CATEGORIES)
	list_view_forge.visible = (current_view == ViewState.FORGE_LIST)
	list_view_arsenal.visible = (current_view == ViewState.ARSENAL_LIST)

	_refresh_display()

	await get_tree().process_frame
	match current_view:
		ViewState.CATEGORIES:
			btn_cat_forge.grab_focus()
		ViewState.FORGE_LIST:
			btn_upgrade_weapon_1.grab_focus()
		ViewState.ARSENAL_LIST:
			btn_back_arsenal.grab_focus()

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
