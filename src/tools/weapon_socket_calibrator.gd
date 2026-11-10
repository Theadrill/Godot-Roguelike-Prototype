@tool
class_name WeaponSocketCalibrator
extends Node2D

## Ferramenta visual de calibração de sockets de armas e itens nas costas na Viewport 2D do Godot.
## Permite selecionar a arma, a animação e o frame, ver os sprites na tela 2D
## e arrastar a arma ou o socket das costas diretamente com o mouse, gravando no arquivo correspondente (.tres).

const VISUAL_SCENES: Dictionary = {
	"sword": "res://src/entities/equipment/swords/sword_visual.tscn",
	"sword_2": "res://src/entities/equipment/swords/sword_visual.tscn",
	"dagger": "res://src/entities/equipment/daggers/dagger_visual.tscn",
	"dagger_2": "res://src/entities/equipment/daggers/dagger_visual.tscn",
	"hammer": "res://src/entities/equipment/hammers/hammer_visual.tscn",
	"hammer_2": "res://src/entities/equipment/hammers/hammer_visual.tscn",
	"staff": "res://src/entities/equipment/staffs/staff_visual.tscn",
	"staff_2": "res://src/entities/equipment/staffs/staff_visual.tscn",
	"bow": "res://src/entities/equipment/bows/bow_visual.tscn",
	"bow_2": "res://src/entities/equipment/bows/bow_visual.tscn",
	"crossbow": "res://src/entities/equipment/crossbows/crossbow_visual.tscn",
	"crossbow_2": "res://src/entities/equipment/crossbows/crossbow_visual.tscn",
}

const DEFAULT_BACK_ROTATIONS: Dictionary = {
	"sword": 225.0,
	"sword_2": 225.0,
	"dagger": 225.0,
	"dagger_2": 225.0,
	"hammer": 25.0,
	"hammer_2": 25.0,
	"staff": 225.0,
	"staff_2": 225.0,
	"bow": -65.0,
	"bow_2": -65.0,
	"crossbow": 0.0,
	"crossbow_2": 0.0,
}

const ANIMATION_FRAME_COUNTS: Dictionary = {
	"idle": 4,
	"run": 6,
	"jump": 4,
	"crouch": 4,
	"fall": 2,
	"fall_from_jump": 3,
	"slide": 2,
	"roll": 4,
	"double_jump": 4,
}

@export_group("1. Alvo de Calibração")
## Escolha qual socket deseja calibrar e arrastar:
## - Mão Principal: Ajusta a posição e rotação da arma empunhada na mão (salva no .tres da arma).
## - Arma nas Costas: Ajusta o socket do tronco que segura a arma de reserva (salva no back_socket.tres).
## - Escudo nas Costas: Ajusta o socket do tronco que segura o escudo (salva no back_socket.tres).
@export_enum("Mão Principal (MainHandSocket)", "Arma nas Costas (BackSocketWeapon)", "Escudo nas Costas (BackSocketShield)") var target_socket: String = "Mão Principal (MainHandSocket)":
	set(value):
		target_socket = value
		_on_configuration_changed()

@export_group("2. Seleção de Arma & Animação")
## Escolha a categoria ou variação da arma para editar na mão.
@export_enum("sword", "sword_2", "dagger", "dagger_2", "hammer", "hammer_2", "staff", "staff_2", "bow", "bow_2", "crossbow", "crossbow_2") var selected_weapon_profile: String = "sword":
	set(value):
		selected_weapon_profile = value
		_on_configuration_changed()

## Escolha a animação do aventureiro para visualizar e calibrar.
@export_enum("idle", "run", "jump", "crouch", "fall", "fall_from_jump", "slide", "roll", "double_jump") var selected_animation: String = "idle":
	set(value):
		selected_animation = value
		_on_configuration_changed()

## Escolha o frame específico da animação selecionada.
@export_range(0, 5, 1) var current_frame: int = 0:
	set(value):
		var max_f: int = ANIMATION_FRAME_COUNTS.get(selected_animation, 4) - 1
		current_frame = clampi(value, 0, max_f)
		_on_frame_changed()

@export_group("3. Modelos de Referência nas Costas")
## Arma que deve aparecer guardada nas costas para referência visual.
@export_enum("none", "bow", "sword", "dagger", "hammer", "staff", "crossbow") var back_weapon_preview: String = "bow":
	set(value):
		back_weapon_preview = value
		_update_back_visuals()

## Exibir ou ocultar o escudo nas costas como modelo de referência.
@export var show_shield_on_back: bool = true:
	set(value):
		show_shield_on_back = value
		_update_back_visuals()

@export_group("4. Ajustes do Frame Atual")
## Posição do socket no frame atual. Você pode editar aqui OU arrastar o Marker2D correspondente na Viewport 2D com o mouse!
@export var socket_position: Vector2 = Vector2.ZERO:
	set(value):
		socket_position = value
		var target_node := _get_active_socket_node()
		if target_node and target_node.position != value:
			target_node.position = value

## Rotação do socket em graus no frame atual.
@export_range(-360.0, 360.0, 0.5, "suffix:°") var socket_rotation: float = 0.0:
	set(value):
		socket_rotation = value
		var target_node := _get_active_socket_node()
		if target_node and not is_equal_approx(target_node.rotation_degrees, value):
			target_node.rotation_degrees = value

## Visibilidade do item neste frame (true = visível, false = oculto).
@export var item_visible_in_frame: bool = true:
	set(value):
		item_visible_in_frame = value
		if target_socket == "Mão Principal (MainHandSocket)" and _weapon_instance and is_instance_valid(_weapon_instance):
			_weapon_instance.visible = value
		elif target_socket == "Arma nas Costas (BackSocketWeapon)" and _back_weapon_instance and is_instance_valid(_back_weapon_instance):
			_back_weapon_instance.visible = value
		elif target_socket == "Escudo nas Costas (BackSocketShield)" and _back_shield_instance and is_instance_valid(_back_shield_instance):
			_back_shield_instance.visible = value

@export_group("5. Gravação no Arquivo")
## Clique nesta caixinha para SALVAR a posição e rotação atuais no arquivo .tres correspondente!
@export var SAVE_FRAME_TO_PROFILE: bool = false:
	set(value):
		if value:
			save_current_frame_data()
		SAVE_FRAME_TO_PROFILE = false

## Mensagem de feedback do último salvamento.
@export var status_message: String = "Pronto para calibrar."

@onready var character_sprite: AnimatedSprite2D = $Visual/CharacterSprite
@onready var main_hand_socket: Marker2D = $Visual/MainHandSocket
@onready var back_socket_weapon: Marker2D = $Visual/BackSocketWeapon
@onready var back_socket_shield: Marker2D = $Visual/BackSocketShield

var _current_profile_resource: WeaponSocketProfile = null
var _back_profile_resource: BackSocketProfile = null
var _weapon_instance: Node2D = null
var _back_weapon_instance: Node2D = null
var _back_shield_instance: Node2D = null

func _ready() -> void:
	_load_resources()
	_update_weapon_visual()
	_update_back_visuals()
	_on_configuration_changed()

func _load_resources() -> void:
	var path := "res://src/entities/equipment/socket_profiles/%s.tres" % selected_weapon_profile
	if ResourceLoader.exists(path):
		_current_profile_resource = load(path) as WeaponSocketProfile
	var back_path := "res://src/entities/equipment/socket_profiles/back_socket.tres"
	if ResourceLoader.exists(back_path):
		_back_profile_resource = load(back_path) as BackSocketProfile

func _get_active_socket_node() -> Marker2D:
	if not main_hand_socket:
		main_hand_socket = get_node_or_null("Visual/MainHandSocket") as Marker2D
	if not back_socket_weapon:
		back_socket_weapon = get_node_or_null("Visual/BackSocketWeapon") as Marker2D
	if not back_socket_shield:
		back_socket_shield = get_node_or_null("Visual/BackSocketShield") as Marker2D

	if target_socket == "Mão Principal (MainHandSocket)":
		return main_hand_socket
	elif target_socket == "Arma nas Costas (BackSocketWeapon)":
		return back_socket_weapon
	elif target_socket == "Escudo nas Costas (BackSocketShield)":
		return back_socket_shield
	return main_hand_socket

func _update_weapon_visual() -> void:
	var hand := _get_node_safe("Visual/MainHandSocket") as Marker2D
	if not hand:
		return

	for c in hand.get_children():
		c.queue_free()
	_weapon_instance = null

	var scene_path: String = VISUAL_SCENES.get(selected_weapon_profile, VISUAL_SCENES["sword"])
	if ResourceLoader.exists(scene_path):
		var scene := load(scene_path) as PackedScene
		if scene:
			_weapon_instance = scene.instantiate() as Node2D
			hand.add_child(_weapon_instance)

func _update_back_visuals() -> void:
	var back_w := _get_node_safe("Visual/BackSocketWeapon") as Marker2D
	var back_s := _get_node_safe("Visual/BackSocketShield") as Marker2D

	if back_w:
		for c in back_w.get_children():
			c.queue_free()
		_back_weapon_instance = null

		if back_weapon_preview != "none":
			var w_path: String = VISUAL_SCENES.get(back_weapon_preview, "")
			if ResourceLoader.exists(w_path):
				var scene := load(w_path) as PackedScene
				if scene:
					_back_weapon_instance = scene.instantiate() as Node2D
					back_w.add_child(_back_weapon_instance)
					_back_weapon_instance.rotation_degrees = DEFAULT_BACK_ROTATIONS.get(back_weapon_preview, 0.0)
					_back_weapon_instance.z_index = -2

	if back_s:
		for c in back_s.get_children():
			c.queue_free()
		_back_shield_instance = null

		if show_shield_on_back:
			var s_path := "res://src/entities/equipment/shields/shield_visual.tscn"
			if ResourceLoader.exists(s_path):
				var s_scene := load(s_path) as PackedScene
				if s_scene:
					_back_shield_instance = s_scene.instantiate() as Node2D
					back_s.add_child(_back_shield_instance)
					_back_shield_instance.z_index = -1

func _get_node_safe(path: String) -> Node:
	return get_node_or_null(path)

func _on_configuration_changed() -> void:
	_load_resources()
	_update_weapon_visual()
	_update_back_visuals()

	var max_f: int = ANIMATION_FRAME_COUNTS.get(selected_animation, 4) - 1
	if current_frame > max_f:
		current_frame = 0

	_on_frame_changed()

func _on_frame_changed() -> void:
	var sprite := _get_node_safe("Visual/CharacterSprite") as AnimatedSprite2D
	if not sprite:
		return

	# Atualiza o sprite do aventureiro para a pose do frame escolhido
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(selected_animation):
		sprite.animation = selected_animation
		sprite.frame = current_frame

	var hand := _get_node_safe("Visual/MainHandSocket") as Marker2D
	var back_w := _get_node_safe("Visual/BackSocketWeapon") as Marker2D
	var back_s := _get_node_safe("Visual/BackSocketShield") as Marker2D

	# 1. Atualiza a mão principal com o profile selecionado
	if _current_profile_resource and _current_profile_resource.has_method("get_frame_data"):
		var data: Dictionary = _current_profile_resource.get_frame_data(selected_animation, current_frame)
		if hand:
			hand.position = data.get("pos", Vector2(6, -20))
			hand.rotation_degrees = data.get("rot", -35.0)
		if _weapon_instance and is_instance_valid(_weapon_instance):
			_weapon_instance.visible = data.get("visible", true)

	# 2. Atualiza os sockets das costas com o back_socket.tres
	var torso_pos := Vector2(-3, -20)
	if _back_profile_resource and _back_profile_resource.has_method("get_frame_pos"):
		torso_pos = _back_profile_resource.get_frame_pos(selected_animation, current_frame)

	if back_w:
		back_w.position = torso_pos
	if back_s:
		back_s.position = torso_pos + Vector2(-3.0, 0.0)

	# 3. Atualiza os inputs do Inspector de acordo com o Target Socket ativo
	if target_socket == "Mão Principal (MainHandSocket)":
		if hand:
			socket_position = hand.position
			socket_rotation = hand.rotation_degrees
			if _weapon_instance and is_instance_valid(_weapon_instance):
				item_visible_in_frame = _weapon_instance.visible
		status_message = "Mão Principal: %s [%s - Frame %d]" % [selected_weapon_profile, selected_animation, current_frame]
	elif target_socket == "Arma nas Costas (BackSocketWeapon)":
		if back_w:
			socket_position = back_w.position
			socket_rotation = back_w.rotation_degrees
			if _back_weapon_instance and is_instance_valid(_back_weapon_instance):
				item_visible_in_frame = _back_weapon_instance.visible
		status_message = "Costas (Arma): back_socket.tres [%s - Frame %d]" % [selected_animation, current_frame]
	elif target_socket == "Escudo nas Costas (BackSocketShield)":
		if back_s:
			socket_position = back_s.position
			socket_rotation = back_s.rotation_degrees
			if _back_shield_instance and is_instance_valid(_back_shield_instance):
				item_visible_in_frame = _back_shield_instance.visible
		status_message = "Costas (Escudo): back_socket.tres [%s - Frame %d]" % [selected_animation, current_frame]

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		var active_node := _get_active_socket_node()
		if active_node:
			if active_node.position != socket_position:
				socket_position = active_node.position
			if not is_equal_approx(active_node.rotation_degrees, socket_rotation):
				socket_rotation = active_node.rotation_degrees

func save_current_frame_data() -> void:
	_load_resources()

	if target_socket == "Mão Principal (MainHandSocket)":
		if not _current_profile_resource:
			status_message = "ERRO: Perfil de arma não encontrado!"
			return

		var pos_prop := "%s_%d_pos" % [selected_animation, current_frame]
		var rot_prop := "%s_%d_rot" % [selected_animation, current_frame]
		var vis_prop := "%s_%d_visible" % [selected_animation, current_frame]

		_current_profile_resource.set(pos_prop, socket_position)
		_current_profile_resource.set(rot_prop, socket_rotation)
		_current_profile_resource.set(vis_prop, item_visible_in_frame)

		var path := "res://src/entities/equipment/socket_profiles/%s.tres" % selected_weapon_profile
		var err := ResourceSaver.save(_current_profile_resource, path)
		if err == OK:
			status_message = "SUCESSO! Salvo em %s.tres -> [%s Frame %d] (Pos: %v, Rot: %.1f°)" % [
				selected_weapon_profile, selected_animation, current_frame, socket_position, socket_rotation
			]
			print(status_message)
		else:
			status_message = "ERRO ao salvar no arquivo: código %d" % err

	else:
		# Calibração do socket das costas (back_socket.tres)
		if not _back_profile_resource:
			status_message = "ERRO: Perfil back_socket.tres não encontrado!"
			return

		var pos_prop := "%s_%d_pos" % [selected_animation, current_frame]
		var saved_pos := socket_position
		if target_socket == "Escudo nas Costas (BackSocketShield)":
			# O escudo usa offset relativo de (-3, 0) em relação ao tronco
			saved_pos = socket_position - Vector2(-3.0, 0.0)

		_back_profile_resource.set(pos_prop, saved_pos)

		var back_path := "res://src/entities/equipment/socket_profiles/back_socket.tres"
		var err := ResourceSaver.save(_back_profile_resource, back_path)
		if err == OK:
			status_message = "SUCESSO! Tronco salvo em back_socket.tres -> [%s Frame %d] (Pos: %v)" % [
				selected_animation, current_frame, saved_pos
			]
			print(status_message)
		else:
			status_message = "ERRO ao salvar back_socket.tres: código %d" % err
