class_name MotherDialogUI
extends CanvasLayer

signal closed(farewell_text: String)

@onready var panel_elixirs: Control = $MainPanel/Content/PanelElixirs
@onready var panel_teas: Control = $MainPanel/Content/PanelTeas
@onready var btn_tab_elixirs: Button = $MainPanel/TabContainer/BtnTabElixirs
@onready var btn_tab_teas: Button = $MainPanel/TabContainer/BtnTabTeas

@onready var btn_select_elixir_1: Button = $MainPanel/Content/PanelElixirs/Cards/Card1/BtnSelect
@onready var btn_select_elixir_2: Button = $MainPanel/Content/PanelElixirs/Cards/Card2/BtnSelect

@onready var tea_1_level_label: Label = $MainPanel/Content/PanelTeas/Cards/Card1/LevelLabel
@onready var tea_1_req_label: Label = $MainPanel/Content/PanelTeas/Cards/Card1/ReqLabel
@onready var btn_upgrade_tea_1: Button = $MainPanel/Content/PanelTeas/Cards/Card1/BtnUpgrade

@onready var tea_2_level_label: Label = $MainPanel/Content/PanelTeas/Cards/Card2/LevelLabel
@onready var tea_2_req_label: Label = $MainPanel/Content/PanelTeas/Cards/Card2/ReqLabel
@onready var btn_upgrade_tea_2: Button = $MainPanel/Content/PanelTeas/Cards/Card2/BtnUpgrade

const FAREWELL_BARKS: Array[String] = [
	"BARK_MOTHER_FAREWELL_1",
	"BARK_MOTHER_FAREWELL_2",
	"BARK_MOTHER_FAREWELL_3",
	"BARK_MOTHER_FAREWELL_4"
]

var _current_tab: int = 0

func _ready() -> void:
	visible = false
	_switch_tab(0)
	_setup_buttons()

func _setup_buttons() -> void:
	btn_tab_elixirs.pressed.connect(func() -> void: _switch_tab(0))
	btn_tab_teas.pressed.connect(func() -> void: _switch_tab(1))
	
	btn_select_elixir_1.pressed.connect(func() -> void: _on_elixir_selected("folha_de_fogo"))
	btn_select_elixir_2.pressed.connect(func() -> void: _on_elixir_selected("caldo_revigorante"))
	
	btn_upgrade_tea_1.pressed.connect(func() -> void: _on_tea_upgrade("stone_root"))
	btn_upgrade_tea_2.pressed.connect(func() -> void: _on_tea_upgrade("mountain_chamomile"))
	
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
	panel_elixirs.visible = (_current_tab == 0)
	panel_teas.visible = (_current_tab == 1)
	
	if _current_tab == 0:
		btn_tab_elixirs.modulate = Color(1.0, 0.9, 0.7, 1.0)
		btn_tab_teas.modulate = Color(0.7, 0.7, 0.7, 1.0)
	else:
		btn_tab_elixirs.modulate = Color(0.7, 0.7, 0.7, 1.0)
		btn_tab_teas.modulate = Color(1.0, 0.9, 0.7, 1.0)
	
	_refresh_display()

func _on_elixir_selected(elixir_id: String) -> void:
	ProgressionManager.select_elixir(elixir_id)
	_refresh_display()

func _on_tea_upgrade(tea_id: String) -> void:
	if tea_id == "stone_root":
		if ProgressionManager.tea_stone_root_duplicates >= 2:
			ProgressionManager.tea_stone_root_duplicates -= 2
			ProgressionManager.tea_stone_root_level += 1
			ProgressionManager.permanent_upgrades_updated.emit()
	elif tea_id == "mountain_chamomile":
		if ProgressionManager.tea_mountain_chamomile_duplicates >= 2:
			ProgressionManager.tea_mountain_chamomile_duplicates -= 2
			ProgressionManager.tea_mountain_chamomile_level += 1
			ProgressionManager.permanent_upgrades_updated.emit()
	_refresh_display()

func _refresh_display() -> void:
	# 1. Elixires
	var active_elixir: String = ProgressionManager.active_elixir
	if active_elixir == "folha_de_fogo":
		btn_select_elixir_1.text = "✓ " + tr("UI_SELECTED")
		btn_select_elixir_1.modulate = Color(0.5, 1.0, 0.5, 1.0)
	else:
		btn_select_elixir_1.text = tr("UI_SELECT")
		btn_select_elixir_1.modulate = Color(1.0, 1.0, 1.0, 1.0)
		
	if active_elixir == "caldo_revigorante":
		btn_select_elixir_2.text = "✓ " + tr("UI_SELECTED")
		btn_select_elixir_2.modulate = Color(0.5, 1.0, 0.5, 1.0)
	else:
		btn_select_elixir_2.text = tr("UI_SELECT")
		btn_select_elixir_2.modulate = Color(1.0, 1.0, 1.0, 1.0)

	# 2. Chás Permanentes
	var hp_bonus: int = (ProgressionManager.tea_stone_root_level - 1) * 15
	tea_1_level_label.text = "Nível " + str(ProgressionManager.tea_stone_root_level) + " (+" + str(hp_bonus) + " HP)"
	tea_1_req_label.text = "Feixes Repetidos: " + str(ProgressionManager.tea_stone_root_duplicates) + "/2"
	btn_upgrade_tea_1.disabled = (ProgressionManager.tea_stone_root_duplicates < 2)
	
	var heal_bonus: int = (ProgressionManager.tea_mountain_chamomile_level - 1) * 5
	tea_2_level_label.text = "Nível " + str(ProgressionManager.tea_mountain_chamomile_level) + " (+" + str(heal_bonus) + "% Cura)"
	tea_2_req_label.text = "Feixes Repetidos: " + str(ProgressionManager.tea_mountain_chamomile_duplicates) + "/2"
	btn_upgrade_tea_2.disabled = (ProgressionManager.tea_mountain_chamomile_duplicates < 2)
