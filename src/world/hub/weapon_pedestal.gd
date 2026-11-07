class_name WeaponPedestal
extends Node2D

## Pedestal físico diegético de armamento na cabana familiar.
## Armazena armas ou escudos ativos para o guerreiro equipar antes de partir,
## ou exibe as metas necessárias de desbloqueio para pedestais trancados.

@export var is_shield_pedestal: bool = false
@export var pedestal_index: int = 0
@export var equipment_data: EquipmentData = null

@onready var pedestal_base: Polygon2D = $Base
@onready var item_visual: Polygon2D = $ItemVisual
@onready var lock_visual: Polygon2D = $LockVisual
@onready var info_label: Label = $InfoLabel
@onready var interaction_area: Area2D = $InteractionArea

var _is_player_near: bool = false
var _player_ref: Player = null
var _original_item_y: float = -24.0

func _ready() -> void:
	if item_visual:
		_original_item_y = item_visual.position.y
	if info_label:
		info_label.visible = false

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	interaction_area.input_event.connect(_on_input_event)

	_refresh_pedestal_state()

func _process(delta: float) -> void:
	# Flutuação suave mística do item desbloqueado sobre o pedestal
	if item_visual and item_visual.visible:
		var bob: float = sin(Time.get_ticks_msec() * 0.0035 + float(pedestal_index) * 0.8) * 2.5
		item_visual.position.y = _original_item_y + bob

func _on_body_entered(body: Node2D) -> void:
	if body is Player or body.is_in_group("player"):
		_is_player_near = true
		_player_ref = body as Player
		_show_hint(true)

func _on_body_exited(body: Node2D) -> void:
	if body is Player or body.is_in_group("player"):
		_is_player_near = false
		_show_hint(false)

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		interact()

func _unhandled_input(event: InputEvent) -> void:
	if _is_player_near and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		interact()

func interact() -> void:
	if not _player_ref:
		_player_ref = get_tree().get_first_node_in_group("player") as Player
	if not _player_ref or _player_ref.is_input_locked:
		return

	var is_unlocked: bool = _check_is_unlocked()

	if not is_unlocked:
		var condition_text: String = _get_condition_text()
		_player_ref.show_bark("[Trancado] " + condition_text)
		return

	if not equipment_data:
		_player_ref.show_bark("Pedestal vazio no momento.")
		return

	# Equipar Arma ou Escudo
	if is_shield_pedestal and equipment_data is ShieldData:
		_player_ref.shield = equipment_data as ShieldData
		_player_ref.show_equipment_visuals()
		ProgressionManager.are_weapons_equipped = true
		_player_ref.show_bark("Escudo Equipado: " + equipment_data.equipment_name)
	elif equipment_data is WeaponData:
		var wp: WeaponData = equipment_data as WeaponData
		ProgressionManager.are_weapons_equipped = true
		_player_ref.show_equipment_visuals()
		
		# Se não tiver arma principal, equipa na mão
		if not _player_ref.weapon:
			_player_ref.equip_weapon(wp)
			_player_ref.show_bark("Equipado na mão: " + wp.equipment_name)
		# Se já tem arma na mão mas não tem secundária nas costas, equipa nas costas
		elif not _player_ref.secondary_weapon:
			_player_ref.equip_secondary_weapon(wp)
			_player_ref.show_bark("Equipado nas costas: " + wp.equipment_name)
		# Se já tem ambas, substitui a da mão
		else:
			_player_ref.equip_weapon(wp)
			_player_ref.show_bark("Equipado na mão: " + wp.equipment_name)

func _check_is_unlocked() -> bool:
	if is_shield_pedestal:
		return ProgressionManager.is_shield_pedestal_unlocked(pedestal_index)
	else:
		return ProgressionManager.is_weapon_pedestal_unlocked(pedestal_index)

func _get_condition_text() -> String:
	if is_shield_pedestal:
		return ProgressionManager.get_shield_pedestal_condition_text(pedestal_index)
	else:
		return ProgressionManager.get_weapon_pedestal_condition_text(pedestal_index)

func _refresh_pedestal_state() -> void:
	var unlocked: bool = _check_is_unlocked()
	
	if lock_visual:
		lock_visual.visible = not unlocked
	if item_visual:
		item_visual.visible = unlocked and equipment_data != null

	# Cor do pedestal: bronze/pedra escura se trancado, pedra nobre com runa se liberado
	if pedestal_base:
		if unlocked:
			pedestal_base.color = Color(0.38, 0.42, 0.46, 1.0)
		else:
			pedestal_base.color = Color(0.20, 0.22, 0.24, 1.0)

func _show_hint(show: bool) -> void:
	if not info_label:
		return
	if not show:
		info_label.visible = false
		return

	var is_unlocked: bool = _check_is_unlocked()
	if is_unlocked:
		if equipment_data:
			info_label.text = "[RB] " + equipment_data.equipment_name
			info_label.modulate = Color(0.9, 1.0, 0.8, 1.0)
		else:
			info_label.text = "Pedestal Vazio"
			info_label.modulate = Color(0.7, 0.7, 0.7, 1.0)
	else:
		info_label.text = "[Trancado]\n" + _get_condition_text()
		info_label.modulate = Color(1.0, 0.7, 0.5, 1.0)

	info_label.visible = true
