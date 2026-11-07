class_name WeaponPedestal
extends Node2D

## Pedestal físico diegético de armamento na cabana familiar.
## Armazena armas ou escudos ativos para o guerreiro equipar antes de partir,
## permite guardar ou trocar itens, e exibe as metas necessárias de desbloqueio.

@export var is_shield_pedestal: bool = false
@export var pedestal_index: int = 0
@export var equipment_data: EquipmentData = null

@onready var pedestal_base: Polygon2D = $Base
@onready var item_holder: Node2D = $ItemHolder
@onready var item_fallback: Polygon2D = $ItemHolder/ItemVisualFallback
@onready var lock_visual: Polygon2D = $LockVisual
@onready var info_label: Label = $InfoLabel
@onready var interaction_area: Area2D = $InteractionArea

var _is_player_near: bool = false
var _player_ref: Player = null
var _original_item_y: float = -22.0
var _custom_visual_instance: Node2D = null

## Registro estático de todos os pedestais próximos para garantir foco exclusivo (sem sobreposição de rótulos)
static var nearby_pedestals: Array[WeaponPedestal] = []

func _ready() -> void:
	if item_holder:
		_original_item_y = item_holder.position.y
	if info_label:
		info_label.visible = false

	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	interaction_area.input_event.connect(_on_input_event)

	_refresh_pedestal_state()

func _exit_tree() -> void:
	nearby_pedestals.erase(self)

func _process(delta: float) -> void:
	# Flutuação suave mística do item desbloqueado sobre o pedestal
	if item_holder and item_holder.visible:
		var bob: float = sin(Time.get_ticks_msec() * 0.0035 + float(pedestal_index) * 0.8) * 2.5
		item_holder.position.y = _original_item_y + bob

	# Atualiza o pedestal mais próximo a cada quadro para que apenas um rótulo fique visível
	if _is_player_near and not nearby_pedestals.is_empty() and nearby_pedestals[0] == self:
		_update_pedestal_focus()

func _on_body_entered(body: Node2D) -> void:
	if body is Player or body.is_in_group("player"):
		_is_player_near = true
		_player_ref = body as Player
		if not nearby_pedestals.has(self):
			nearby_pedestals.append(self)
		_update_pedestal_focus()

func _on_body_exited(body: Node2D) -> void:
	if body is Player or body.is_in_group("player"):
		_is_player_near = false
		nearby_pedestals.erase(self)
		_show_hint(false)
		_update_pedestal_focus()

static func _update_pedestal_focus() -> void:
	if nearby_pedestals.is_empty():
		return

	var p_ref: Player = nearby_pedestals[0]._player_ref
	if not p_ref or not is_instance_valid(p_ref):
		p_ref = nearby_pedestals[0].get_tree().get_first_node_in_group("player") as Player
	if not p_ref:
		return

	var px: float = p_ref.global_position.x
	var closest: WeaponPedestal = null
	var min_dist: float = 999999.0

	for ped in nearby_pedestals:
		if is_instance_valid(ped):
			var d: float = absf(ped.global_position.x - px)
			if d < min_dist:
				min_dist = d
				closest = ped

	for ped in nearby_pedestals:
		if is_instance_valid(ped):
			if ped == closest:
				ped._show_hint(true)
			else:
				ped._show_hint(false)

func _is_current_closest() -> bool:
	if not _player_ref or nearby_pedestals.is_empty():
		return true
	var px: float = _player_ref.global_position.x
	var my_dist: float = absf(global_position.x - px)
	for other in nearby_pedestals:
		if is_instance_valid(other) and other != self:
			if absf(other.global_position.x - px) < my_dist:
				return false
	return true

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		interact()

func _unhandled_input(event: InputEvent) -> void:
	if _is_player_near and event.is_action_pressed("interact"):
		if _is_current_closest():
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

	# --- PEDESTAL DE ESCUDOS ---
	if is_shield_pedestal:
		if equipment_data != null:
			# O pedestal possui um escudo: o guerreiro equipa
			var old_shield: ShieldData = _player_ref.shield
			var new_shield: ShieldData = equipment_data as ShieldData
			_player_ref.equip_shield(new_shield)
			_player_ref.show_equipment_visuals()
			ProgressionManager.are_weapons_equipped = true

			# O pedestal fica com o escudo anterior (ou vazio)
			equipment_data = old_shield
			_refresh_pedestal_state()
			_show_hint(true)

			if old_shield:
				_player_ref.show_bark("Trocou escudo: " + new_shield.equipment_name)
			else:
				_player_ref.show_bark("Escudo Equipado: " + new_shield.equipment_name)
		else:
			# O pedestal está vazio: guarda o escudo do guerreiro nele
			if _player_ref.shield != null:
				equipment_data = _player_ref.shield
				_player_ref.equip_shield(null)
				_refresh_pedestal_state()
				_show_hint(true)
				_player_ref.show_bark("Escudo guardado no pedestal.")
			else:
				_player_ref.show_bark("Pedestal Vazio.")
		return

	# --- PEDESTAL DE ARMAS ---
	if equipment_data != null:
		var new_wp: WeaponData = equipment_data as WeaponData
		ProgressionManager.are_weapons_equipped = true

		# Caso 1: Sem arma principal na mão -> Equipa na mão
		if not _player_ref.weapon:
			_player_ref.equip_weapon(new_wp)
			equipment_data = null
			_refresh_pedestal_state()
			_show_hint(true)
			_player_ref.show_equipment_visuals()
			_player_ref.show_bark("Equipado na mão: " + new_wp.equipment_name)
		# Caso 2: Já tem na mão, mas não tem nas costas -> Equipa nas costas
		elif not _player_ref.secondary_weapon:
			_player_ref.equip_secondary_weapon(new_wp)
			equipment_data = null
			_refresh_pedestal_state()
			_show_hint(true)
			_player_ref.show_equipment_visuals()
			_player_ref.show_bark("Equipado nas costas: " + new_wp.equipment_name)
		# Caso 3: Já tem ambas -> Troca a arma atual da mão com a do pedestal
		else:
			var old_wp: WeaponData = _player_ref.weapon
			_player_ref.equip_weapon(new_wp)
			equipment_data = old_wp
			_refresh_pedestal_state()
			_show_hint(true)
			_player_ref.show_equipment_visuals()
			_player_ref.show_bark("Trocou de arma: " + new_wp.equipment_name)
	else:
		# Pedestal de arma vazio: guarda a arma da mão nele
		if _player_ref.weapon != null:
			equipment_data = _player_ref.weapon
			# Se tiver arma nas costas, promove para a mão; senão, fica desarmado
			if _player_ref.secondary_weapon != null:
				_player_ref.equip_weapon(_player_ref.secondary_weapon)
				_player_ref.equip_secondary_weapon(null)
			else:
				_player_ref.equip_weapon(null)
			_refresh_pedestal_state()
			_show_hint(true)
			_player_ref.show_bark("Arma guardada no pedestal.")
		else:
			_player_ref.show_bark("Pedestal Vazio.")

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

	# Remove visual customizado anterior caso exista
	if _custom_visual_instance and is_instance_valid(_custom_visual_instance):
		_custom_visual_instance.queue_free()
		_custom_visual_instance = null

	if unlocked and equipment_data != null and item_holder:
		item_holder.visible = true
		
		# Se o equipamento tem cena de visual própria (.visual_scene), instancia e ajusta escala/rotação
		if equipment_data.visual_scene:
			if item_fallback:
				item_fallback.visible = false
			_custom_visual_instance = equipment_data.visual_scene.instantiate() as Node2D
			if _custom_visual_instance:
				item_holder.add_child(_custom_visual_instance)
				if is_shield_pedestal or equipment_data is ShieldData:
					_custom_visual_instance.rotation_degrees = 0.0
					_custom_visual_instance.scale = Vector2(1.2, 1.2)
				elif equipment_data is WeaponData and (equipment_data as WeaponData).weapon_category != WeaponData.WeaponCategory.MELEE:
					_custom_visual_instance.rotation_degrees = 0.0
					_custom_visual_instance.scale = Vector2(1.0, 1.0)
				else:
					# Espadas ficam apontadas para cima com elegância
					_custom_visual_instance.rotation_degrees = -90.0
					_custom_visual_instance.scale = Vector2(1.1, 1.1)
		else:
			# Visual fallback por polígonos
			if item_fallback:
				item_fallback.visible = true
				if is_shield_pedestal or equipment_data is ShieldData:
					item_fallback.polygon = PackedVector2Array([
						Vector2(-7, -8), Vector2(7, -8), Vector2(9, -2), Vector2(6, 6),
						Vector2(0, 10), Vector2(-6, 6), Vector2(-9, -2)
					])
					item_fallback.color = Color(0.55, 0.45, 0.35, 1.0)
				else:
					item_fallback.polygon = PackedVector2Array([
						Vector2(-2.5, -12), Vector2(2.5, -12), Vector2(3, 6), Vector2(0, 10), Vector2(-3, 6)
					])
					item_fallback.color = Color(0.85, 0.9, 0.95, 1.0)
	else:
		if item_holder:
			item_holder.visible = false

	# Cor do pedestal: pedra nobre se desbloqueado, pedra rústica escura se trancado
	if pedestal_base:
		if unlocked:
			pedestal_base.color = Color(0.38, 0.42, 0.46, 1.0)
		else:
			pedestal_base.color = Color(0.20, 0.22, 0.24, 1.0)

func _show_hint(show: bool) -> void:
	if not info_label:
		return
	if not show or not _is_current_closest():
		info_label.visible = false
		return

	if not _player_ref:
		_player_ref = get_tree().get_first_node_in_group("player") as Player

	var is_unlocked: bool = _check_is_unlocked()
	if is_unlocked:
		if equipment_data:
			info_label.text = "[RB] " + equipment_data.equipment_name
			info_label.modulate = Color(0.9, 1.0, 0.8, 1.0)
		else:
			if is_shield_pedestal:
				if _player_ref and _player_ref.shield:
					info_label.text = "[RB] Guardar Escudo"
					info_label.modulate = Color(0.8, 0.9, 1.0, 1.0)
				else:
					info_label.text = "Pedestal Vazio"
					info_label.modulate = Color(0.65, 0.65, 0.65, 1.0)
			else:
				if _player_ref and _player_ref.weapon:
					info_label.text = "[RB] Guardar Arma"
					info_label.modulate = Color(0.8, 0.9, 1.0, 1.0)
				else:
					info_label.text = "Pedestal Vazio"
					info_label.modulate = Color(0.65, 0.65, 0.65, 1.0)
	else:
		info_label.text = "[Trancado]\n" + _get_condition_text()
		info_label.modulate = Color(1.0, 0.7, 0.5, 1.0)

	info_label.visible = true
