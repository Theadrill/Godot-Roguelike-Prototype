class_name MotherDialogUI
extends CanvasLayer

const GamepadPromptBar = preload("res://src/ui/components/gamepad_prompt_bar.gd")

signal closed(did_take_tea: bool)

@onready var category_view: Control = $MainPanel/CategoryView
@onready var list_view_elixirs: Control = $MainPanel/ListViewElixirs
@onready var list_view_teas: Control = $MainPanel/ListViewTeas
@onready var list_view_clothes: Control = $MainPanel/ListViewClothes

@onready var btn_cat_elixirs: Button = $MainPanel/CategoryView/CategoriesHBox/BtnCatElixirs
@onready var btn_cat_teas: Button = $MainPanel/CategoryView/CategoriesHBox/BtnCatTeas
@onready var btn_cat_clothes: Button = $MainPanel/CategoryView/CategoriesHBox/BtnCatClothes

@onready var btn_back_elixirs: Button = $MainPanel/ListViewElixirs/Header/BtnBack
@onready var btn_select_elixir_1: Button = $MainPanel/ListViewElixirs/ScrollContainer/VBox/Item1/BtnSelect
@onready var btn_select_elixir_2: Button = $MainPanel/ListViewElixirs/ScrollContainer/VBox/Item2/BtnSelect

@onready var btn_back_teas: Button = $MainPanel/ListViewTeas/Header/BtnBack
@onready var tea_1_level_label: Label = $MainPanel/ListViewTeas/ScrollContainer/VBox/Item1/LevelLabel
@onready var tea_1_req_label: Label = $MainPanel/ListViewTeas/ScrollContainer/VBox/Item1/ReqLabel
@onready var btn_upgrade_tea_1: Button = $MainPanel/ListViewTeas/ScrollContainer/VBox/Item1/BtnUpgrade

@onready var tea_2_level_label: Label = $MainPanel/ListViewTeas/ScrollContainer/VBox/Item2/LevelLabel
@onready var tea_2_req_label: Label = $MainPanel/ListViewTeas/ScrollContainer/VBox/Item2/ReqLabel
@onready var btn_upgrade_tea_2: Button = $MainPanel/ListViewTeas/ScrollContainer/VBox/Item2/BtnUpgrade

@onready var btn_back_clothes: Button = $MainPanel/ListViewClothes/Header/BtnBack
@onready var btn_skin_default: Button = $MainPanel/ListViewClothes/ScrollContainer/VBox/Item1/BtnEquip
@onready var btn_skin_crimson: Button = $MainPanel/ListViewClothes/ScrollContainer/VBox/Item2/BtnEquip

@onready var prompt_bar: GamepadPromptBar = $MainPanel/GamepadPromptBar

enum ViewState { CATEGORIES, ELIXIRS_LIST, TEAS_LIST, CLOTHES_LIST }
var current_view: ViewState = ViewState.CATEGORIES
var did_take_tea_or_elixir: bool = false

func _ready() -> void:
	visible = false
	_setup_buttons()

func _setup_buttons() -> void:
	btn_cat_elixirs.pressed.connect(func() -> void: _switch_to_view(ViewState.ELIXIRS_LIST))
	btn_cat_teas.pressed.connect(func() -> void: _switch_to_view(ViewState.TEAS_LIST))
	btn_cat_clothes.pressed.connect(func() -> void: _switch_to_view(ViewState.CLOTHES_LIST))
	
	btn_back_elixirs.pressed.connect(func() -> void: _switch_to_view(ViewState.CATEGORIES))
	btn_back_teas.pressed.connect(func() -> void: _switch_to_view(ViewState.CATEGORIES))
	btn_back_clothes.pressed.connect(func() -> void: _switch_to_view(ViewState.CATEGORIES))
	
	btn_select_elixir_1.pressed.connect(func() -> void: _on_elixir_selected("folha_de_fogo"))
	btn_select_elixir_2.pressed.connect(func() -> void: _on_elixir_selected("caldo_revigorante"))
	
	btn_upgrade_tea_1.pressed.connect(func() -> void: _on_tea_upgrade("stone_root"))
	btn_upgrade_tea_2.pressed.connect(func() -> void: _on_tea_upgrade("mountain_chamomile"))
	
	btn_skin_default.pressed.connect(func() -> void: _on_skin_selected("default"))
	btn_skin_crimson.pressed.connect(func() -> void: _on_skin_selected("crimson"))

	var btn_close: Button = $MainPanel/TopBar/BtnClose
	if btn_close:
		btn_close.pressed.connect(close_ui)

func open_ui() -> void:
	visible = true
	did_take_tea_or_elixir = false
	_switch_to_view(ViewState.CATEGORIES)

func close_ui() -> void:
	visible = false
	closed.emit(did_take_tea_or_elixir)

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
	list_view_elixirs.visible = (current_view == ViewState.ELIXIRS_LIST)
	list_view_teas.visible = (current_view == ViewState.TEAS_LIST)
	list_view_clothes.visible = (current_view == ViewState.CLOTHES_LIST)

	_refresh_display()

	await get_tree().process_frame
	match current_view:
		ViewState.CATEGORIES:
			btn_cat_elixirs.grab_focus()
		ViewState.ELIXIRS_LIST:
			btn_select_elixir_1.grab_focus()
		ViewState.TEAS_LIST:
			btn_upgrade_tea_1.grab_focus()
		ViewState.CLOTHES_LIST:
			btn_skin_default.grab_focus()

func _on_elixir_selected(elixir_id: String) -> void:
	ProgressionManager.select_elixir(elixir_id)
	did_take_tea_or_elixir = true
	_refresh_display()

func _on_tea_upgrade(tea_id: String) -> void:
	if tea_id == "stone_root":
		if ProgressionManager.tea_stone_root_duplicates >= 2:
			ProgressionManager.tea_stone_root_duplicates -= 2
			ProgressionManager.tea_stone_root_level += 1
			ProgressionManager.permanent_upgrades_updated.emit()
			did_take_tea_or_elixir = true
	elif tea_id == "mountain_chamomile":
		if ProgressionManager.tea_mountain_chamomile_duplicates >= 2:
			ProgressionManager.tea_mountain_chamomile_duplicates -= 2
			ProgressionManager.tea_mountain_chamomile_level += 1
			ProgressionManager.permanent_upgrades_updated.emit()
			did_take_tea_or_elixir = true
	_refresh_display()

func _on_skin_selected(skin_id: String) -> void:
	ProgressionManager.select_skin(skin_id)
	var player: Player = get_tree().get_first_node_in_group("player") as Player
	if player:
		ProgressionManager.apply_skin_to_player(player)
	_refresh_display()

func _refresh_display() -> void:
	if prompt_bar:
		prompt_bar.refresh_prompts()

	# Elixires
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

	# Chás Permanentes
	var hp_bonus: int = (ProgressionManager.tea_stone_root_level - 1) * 15
	tea_1_level_label.text = "Nível " + str(ProgressionManager.tea_stone_root_level) + " (+" + str(hp_bonus) + " HP)"
	tea_1_req_label.text = "Feixes: " + str(ProgressionManager.tea_stone_root_duplicates) + "/2"
	btn_upgrade_tea_1.disabled = (ProgressionManager.tea_stone_root_duplicates < 2)
	
	var heal_bonus: int = (ProgressionManager.tea_mountain_chamomile_level - 1) * 5
	tea_2_level_label.text = "Nível " + str(ProgressionManager.tea_mountain_chamomile_level) + " (+" + str(heal_bonus) + "% Cura)"
	tea_2_req_label.text = "Feixes: " + str(ProgressionManager.tea_mountain_chamomile_duplicates) + "/2"
	btn_upgrade_tea_2.disabled = (ProgressionManager.tea_mountain_chamomile_duplicates < 2)

	# Roupas
	var active_skin: String = ProgressionManager.active_skin_id
	if active_skin == "default":
		btn_skin_default.text = "✓ " + tr("UI_EQUIPPED_SKIN")
		btn_skin_default.modulate = Color(0.5, 1.0, 0.5, 1.0)
	else:
		btn_skin_default.text = tr("UI_EQUIP_SKIN")
		btn_skin_default.modulate = Color(1.0, 1.0, 1.0, 1.0)

	if active_skin == "crimson":
		btn_skin_crimson.text = "✓ " + tr("UI_EQUIPPED_SKIN")
		btn_skin_crimson.modulate = Color(0.5, 1.0, 0.5, 1.0)
	else:
		btn_skin_crimson.text = tr("UI_EQUIP_SKIN")
		btn_skin_crimson.modulate = Color(1.0, 1.0, 1.0, 1.0)
