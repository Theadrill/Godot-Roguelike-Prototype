class_name BrotherForgeUI
extends CanvasLayer

signal closed(farewell_text: String)

@onready var panel_forge: Control = $MainPanel/Content/PanelForge
@onready var panel_arsenal: Control = $MainPanel/Content/PanelArsenal
@onready var btn_tab_forge: Button = $MainPanel/TabContainer/BtnTabForge
@onready var btn_tab_arsenal: Button = $MainPanel/TabContainer/BtnTabArsenal

@onready var weapon_1_level_label: Label = $MainPanel/Content/PanelForge/Cards/Card1/LevelLabel
@onready var weapon_1_req_label: Label = $MainPanel/Content/PanelForge/Cards/Card1/ReqLabel
@onready var btn_upgrade_weapon_1: Button = $MainPanel/Content/PanelForge/Cards/Card1/BtnUpgrade

@onready var weapon_2_level_label: Label = $MainPanel/Content/PanelForge/Cards/Card2/LevelLabel
@onready var weapon_2_req_label: Label = $MainPanel/Content/PanelForge/Cards/Card2/ReqLabel
@onready var btn_upgrade_weapon_2: Button = $MainPanel/Content/PanelForge/Cards/Card2/BtnUpgrade

const FAREWELL_BARKS: Array[String] = [
	"BARK_BROTHER_FAREWELL_1",
	"BARK_BROTHER_FAREWELL_2",
	"BARK_BROTHER_FAREWELL_3",
	"BARK_BROTHER_FAREWELL_4"
]

var _current_tab: int = 0

func _ready() -> void:
	visible = false
	_switch_tab(0)
	_setup_buttons()

func _setup_buttons() -> void:
	btn_tab_forge.pressed.connect(func() -> void: _switch_tab(0))
	btn_tab_arsenal.pressed.connect(func() -> void: _switch_tab(1))
	
	btn_upgrade_weapon_1.pressed.connect(func() -> void: _on_weapon_upgrade("sword"))
	btn_upgrade_weapon_2.pressed.connect(func() -> void: _on_weapon_upgrade("bow"))
	
	var btn_close: Button = $MainPanel/Header/BtnClose
	if btn_close:
		btn_close.pressed.connect(close_ui)

func open_ui() -> void:
	visible = true
	_current_tab = 0
	_switch_tab(0)
	_refresh_display()

func close_ui() -> void:
	visible = false
	var random_farewell := tr(FAREWELL_BARKS.pick_random())
	closed.emit(random_farewell)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		close_ui()

func _switch_tab(tab_index: int) -> void:
	_current_tab = tab_index
	panel_forge.visible = (_current_tab == 0)
	panel_arsenal.visible = (_current_tab == 1)
	
	if _current_tab == 0:
		btn_tab_forge.modulate = Color(0.85, 0.95, 1.0, 1.0)
		btn_tab_arsenal.modulate = Color(0.7, 0.7, 0.7, 1.0)
	else:
		btn_tab_forge.modulate = Color(0.7, 0.7, 0.7, 1.0)
		btn_tab_arsenal.modulate = Color(0.85, 0.95, 1.0, 1.0)
	
	_refresh_display()

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
