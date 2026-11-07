class_name TouchOfDeathUI
extends CanvasLayer

signal blessing_chosen(blessing_id: String)

@onready var btn_choose_1: Button = $MainPanel/Content/Cards/Card1/BtnChoose
@onready var btn_choose_2: Button = $MainPanel/Content/Cards/Card2/BtnChoose
@onready var btn_skip: Button = $MainPanel/BtnSkip

func _ready() -> void:
	visible = false
	btn_choose_1.pressed.connect(func() -> void: _on_chosen("onda_espectral"))
	btn_choose_2.pressed.connect(func() -> void: _on_chosen("olhar_da_ruina"))
	btn_skip.pressed.connect(func() -> void: _on_chosen(""))

func open_ui() -> void:
	visible = true

func close_ui() -> void:
	visible = false

func _on_chosen(blessing_id: String) -> void:
	ProgressionManager.select_death_blessing(blessing_id)
	visible = false
	blessing_chosen.emit(blessing_id)
