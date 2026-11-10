@tool
class_name WeaponSocketCalibrator
extends Node2D

## Ferramenta visual unificada de calibração de armas (Mão e Costas).
## Você escolhe a arma, se quer calibrar na Mão ou nas Costas, a animação e o frame.
## Arrasta e gira livremente na Viewport 2D com o mouse e salva direto no .tres da arma!

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

@export_group("1. O que você quer calibrar?")
## Escolha onde a arma está posicionada:
## - Mão Principal: Calibra a arma empunhada na mão.
## - Costas: Calibra a arma guardada nas costas.
@export_enum("Mão Principal (MainHandSocket)", "Costas (BackSocketWeapon)") var socket_target: String = "Mão Principal (MainHandSocket)":
	set(value):
		socket_target = value
		_on_configuration_changed()

## Escolha a arma a ser calibrada.
@export_enum("sword", "sword_2", "dagger", "dagger_2", "hammer", "hammer_2", "staff", "staff_2", "bow", "bow_2", "crossbow", "crossbow_2") var selected_weapon: String = "sword":
	set(value):
		selected_weapon = value
		_on_configuration_changed()

@export_group("2. Animação & Frame")
## Escolha a animação do aventureiro para visualizar e calibrar.
@export_enum("idle", "run", "jump", "crouch", "fall", "fall_from_jump", "slide", "roll", "double_jump") var selected_animation: String = "idle":
	set(value):
		selected_animation = value
		_on_configuration_changed()

## Escolha o frame específico da animação.
@export_range(0, 5, 1) var current_frame: int = 0:
	set(value):
		var max_f: int = ANIMATION_FRAME_COUNTS.get(selected_animation, 4) - 1
		current_frame = clampi(value, 0, max_f)
		_on_frame_changed()

@export_group("3. Elementos de Apoio / Referência")
## Arma secundária para ver nas costas quando estiver calibrando a Mão (ou vice-versa).
@export_enum("none", "bow", "sword", "dagger", "hammer", "staff", "crossbow") var reference_weapon: String = "bow":
	set(value):
		reference_weapon = value
		_update_visuals()
		_on_frame_changed()

## Exibir ou ocultar o escudo nas costas como referência.
@export var show_shield_on_back: bool = true:
	set(value):
		show_shield_on_back = value
		_update_shield_visual()

@export_group("4. Ajustes do Frame Atual (X, Y e Ângulo)")
## Posição do socket no frame atual. Você pode digitar aqui OU arrastar o nó na Viewport 2D com o mouse!
@export var socket_position: Vector2 = Vector2.ZERO:
	set(value):
		socket_position = value
		var node := _get_active_marker()
		if node and node.position != value:
			node.position = value

## Rotação em graus no frame atual.
@export_range(-360.0, 360.0, 0.5, "suffix:°") var socket_rotation: float = 0.0:
	set(value):
		socket_rotation = value
		var node := _get_active_marker()
		if node and not is_equal_approx(node.rotation_degrees, value):
			node.rotation_degrees = value

## Visibilidade da arma neste frame (true = visível, false = oculta).
@export var item_visible_in_frame: bool = true:
	set(value):
		item_visible_in_frame = value
		var vis := _get_active_weapon_visual()
		if vis and is_instance_valid(vis):
			vis.visible = value

@export_group("5. Gravação no Arquivo")
## Clique nesta caixinha para SALVAR a posição e rotação atuais diretamente no .tres da arma!
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
var _reference_profile_resource: WeaponSocketProfile = null

var _hand_instance: Node2D = null
var _back_instance: Node2D = null
var _shield_instance: Node2D = null

func _ready() -> void:
	_load_resources()
	_update_visuals()
	_update_shield_visual()
	_on_configuration_changed()

func _load_resources() -> void:
	var path := "res://src/entities/equipment/socket_profiles/%s.tres" % selected_weapon
	if ResourceLoader.exists(path):
		_current_profile_resource = load(path) as WeaponSocketProfile
	else:
		_current_profile_resource = null

	if reference_weapon != "none":
		var ref_path := "res://src/entities/equipment/socket_profiles/%s.tres" % reference_weapon
		if ResourceLoader.exists(ref_path):
			_reference_profile_resource = load(ref_path) as WeaponSocketProfile
	else:
		_reference_profile_resource = null

func _get_active_marker() -> Marker2D:
	if socket_target == "Mão Principal (MainHandSocket)":
		if not main_hand_socket:
			main_hand_socket = get_node_or_null("Visual/MainHandSocket") as Marker2D
		return main_hand_socket
	else:
		if not back_socket_weapon:
			back_socket_weapon = get_node_or_null("Visual/BackSocketWeapon") as Marker2D
		return back_socket_weapon

func _get_active_weapon_visual() -> Node2D:
	if socket_target == "Mão Principal (MainHandSocket)":
		return _hand_instance
	else:
		return _back_instance

func _update_visuals() -> void:
	var hand := _get_node_safe("Visual/MainHandSocket") as Marker2D
	var back := _get_node_safe("Visual/BackSocketWeapon") as Marker2D

	if hand:
		for c in hand.get_children():
			c.queue_free()
		_hand_instance = null

	if back:
		for c in back.get_children():
			c.queue_free()
		_back_instance = null

	var hand_weapon := selected_weapon if socket_target == "Mão Principal (MainHandSocket)" else reference_weapon
	var back_weapon := reference_weapon if socket_target == "Mão Principal (MainHandSocket)" else selected_weapon

	# 1. Instancia arma da mão
	if hand and hand_weapon != "none":
		var h_scene_path: String = VISUAL_SCENES.get(hand_weapon, "")
		if ResourceLoader.exists(h_scene_path):
			var scene := load(h_scene_path) as PackedScene
			if scene:
				_hand_instance = scene.instantiate() as Node2D
				hand.add_child(_hand_instance)
				_hand_instance.position = Vector2.ZERO
				_hand_instance.rotation_degrees = 0.0

	# 2. Instancia arma das costas
	if back and back_weapon != "none":
		var b_scene_path: String = VISUAL_SCENES.get(back_weapon, "")
		if ResourceLoader.exists(b_scene_path):
			var b_scene := load(b_scene_path) as PackedScene
			if b_scene:
				_back_instance = b_scene.instantiate() as Node2D
				back.add_child(_back_instance)
				_back_instance.position = Vector2.ZERO
				_back_instance.rotation_degrees = 0.0
				_back_instance.z_index = -2

func _update_shield_visual() -> void:
	var back_s := _get_node_safe("Visual/BackSocketShield") as Marker2D
	if not back_s:
		return

	for c in back_s.get_children():
		c.queue_free()
	_shield_instance = null

	if show_shield_on_back:
		var s_path := "res://src/entities/equipment/shields/shield_visual.tscn"
		if ResourceLoader.exists(s_path):
			var scene := load(s_path) as PackedScene
			if scene:
				_shield_instance = scene.instantiate() as Node2D
				back_s.add_child(_shield_instance)
				_shield_instance.position = Vector2.ZERO
				_shield_instance.rotation_degrees = 0.0
				_shield_instance.z_index = -1

func _get_node_safe(path: String) -> Node:
	return get_node_or_null(path)

func _on_configuration_changed() -> void:
	_load_resources()
	_update_visuals()
	_update_shield_visual()

	var max_f: int = ANIMATION_FRAME_COUNTS.get(selected_animation, 4) - 1
	if current_frame > max_f:
		current_frame = 0

	_on_frame_changed()

func _on_frame_changed() -> void:
	var sprite := _get_node_safe("Visual/CharacterSprite") as AnimatedSprite2D
	if not sprite:
		return

	# 1. Pose do aventureiro no frame selecionado
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(selected_animation):
		sprite.animation = selected_animation
		sprite.frame = current_frame

	var hand := _get_node_safe("Visual/MainHandSocket") as Marker2D
	var back := _get_node_safe("Visual/BackSocketWeapon") as Marker2D
	var back_s := _get_node_safe("Visual/BackSocketShield") as Marker2D

	var hand_prof := _current_profile_resource if socket_target == "Mão Principal (MainHandSocket)" else _reference_profile_resource
	var back_prof := _reference_profile_resource if socket_target == "Mão Principal (MainHandSocket)" else _current_profile_resource

	# 2. Atualiza Mão
	if hand and hand_prof and hand_prof.has_method("get_frame_data"):
		var data: Dictionary = hand_prof.get_frame_data(selected_animation, current_frame)
		hand.position = data.get("pos", Vector2(6, -20))
		hand.rotation_degrees = data.get("rot", -35.0)
		if _hand_instance and is_instance_valid(_hand_instance):
			_hand_instance.visible = data.get("visible", true)

	# 3. Atualiza Costas
	if back and back_prof and back_prof.has_method("get_back_frame_data"):
		var b_data: Dictionary = back_prof.get_back_frame_data(selected_animation, current_frame)
		back.position = b_data.get("pos", Vector2(-6, -24))
		back.rotation_degrees = b_data.get("rot", -175.0)
		if _back_instance and is_instance_valid(_back_instance):
			_back_instance.visible = b_data.get("visible", true)

	# 4. Atualiza Escudo
	if back_s and back:
		back_s.position = back.position + Vector2(-3.0, 0.0)

	# 5. Atualiza os inputs do Inspector para o alvo ativo
	var active_marker := _get_active_marker()
	if active_marker:
		socket_position = active_marker.position
		socket_rotation = active_marker.rotation_degrees

	var active_vis := _get_active_weapon_visual()
	if active_vis and is_instance_valid(active_vis):
		item_visible_in_frame = active_vis.visible

	var target_label := "Mão" if socket_target == "Mão Principal (MainHandSocket)" else "Costas"
	status_message = "%s [%s] -> %s Frame %d" % [selected_weapon, target_label, selected_animation, current_frame]

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		var active_marker := _get_active_marker()
		if active_marker:
			if active_marker.position != socket_position:
				socket_position = active_marker.position
			if not is_equal_approx(active_marker.rotation_degrees, socket_rotation):
				socket_rotation = active_marker.rotation_degrees

func save_current_frame_data() -> void:
	_load_resources()
	if not _current_profile_resource:
		status_message = "ERRO: Perfil %s.tres não encontrado!" % selected_weapon
		return

	if socket_target == "Mão Principal (MainHandSocket)":
		var pos_prop := "%s_%d_pos" % [selected_animation, current_frame]
		var rot_prop := "%s_%d_rot" % [selected_animation, current_frame]
		var vis_prop := "%s_%d_visible" % [selected_animation, current_frame]

		_current_profile_resource.set(pos_prop, socket_position)
		_current_profile_resource.set(rot_prop, socket_rotation)
		_current_profile_resource.set(vis_prop, item_visible_in_frame)

		var path := "res://src/entities/equipment/socket_profiles/%s.tres" % selected_weapon
		var err := ResourceSaver.save(_current_profile_resource, path)
		if err == OK:
			status_message = "SUCESSO! Salvo em %s.tres -> MÃO [%s Frame %d] (Pos: %v, Rot: %.1f°)" % [
				selected_weapon, selected_animation, current_frame, socket_position, socket_rotation
			]
			print(status_message)
		else:
			status_message = "ERRO ao salvar no arquivo: código %d" % err

	else: # Costas (BackSocketWeapon)
		_current_profile_resource.set_back_frame_data(
			selected_animation, current_frame, socket_position, socket_rotation, item_visible_in_frame
		)

		var path := "res://src/entities/equipment/socket_profiles/%s.tres" % selected_weapon
		var err := ResourceSaver.save(_current_profile_resource, path)
		if err == OK:
			status_message = "SUCESSO! Salvo em %s.tres -> COSTAS [%s Frame %d] (Pos: %v, Rot: %.1f°)" % [
				selected_weapon, selected_animation, current_frame, socket_position, socket_rotation
			]
			print(status_message)
		else:
			status_message = "ERRO ao salvar no arquivo: código %d" % err
