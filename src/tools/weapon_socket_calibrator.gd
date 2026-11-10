@tool
class_name WeaponSocketCalibrator
extends Node2D

## Ferramenta visual de calibração de sockets de armas e itens nas costas na Viewport 2D do Godot.
## Permite selecionar a arma, a animação e o frame, ver os sprites na tela 2D
## e calibrar tanto a arma na mão, o movimento do tronco nas costas, quanto o ângulo/offset da arma guardada nas costas.

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

const WEAPON_DATA_PATHS: Dictionary = {
	"sword": "res://src/entities/equipment/swords/weapon_sword_base.tres",
	"sword_2": "res://src/entities/equipment/swords/weapon_sword_base.tres",
	"dagger": "res://src/entities/equipment/daggers/weapon_dagger_base.tres",
	"dagger_2": "res://src/entities/equipment/daggers/weapon_dagger_base.tres",
	"hammer": "res://src/entities/equipment/hammers/weapon_hammer_base.tres",
	"hammer_2": "res://src/entities/equipment/hammers/weapon_hammer_base.tres",
	"staff": "res://src/entities/equipment/staffs/weapon_staff_base.tres",
	"staff_2": "res://src/entities/equipment/staffs/weapon_staff_base.tres",
	"bow": "res://src/entities/equipment/bows/weapon_bow_base.tres",
	"bow_2": "res://src/entities/equipment/bows/weapon_bow_base.tres",
	"crossbow": "res://src/entities/equipment/crossbows/weapon_crossbow_base.tres",
	"crossbow_2": "res://src/entities/equipment/crossbows/weapon_crossbow_base.tres",
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
## Escolha o que você deseja calibrar:
## - Mão Principal: Ancoragem frame a frame da arma na mão (salva no .tres da arma).
## - Tronco nas Costas: Posição frame a frame do tronco do aventureiro (salva no back_socket.tres).
## - Ajuste da Arma nas Costas: Ângulo e offset da arma de reserva guardada nas costas (salva no weapon_<arma>_base.tres).
@export_enum("Mão Principal (MainHandSocket)", "Tronco nas Costas (BackSocket - Frame a Frame)", "Ajuste da Arma nas Costas (Ângulo & Offset)") var target_socket: String = "Mão Principal (MainHandSocket)":
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

@export_group("3. Arma e Escudo nas Costas")
## Arma exibida guardada nas costas (secundária).
@export_enum("none", "bow", "sword", "dagger", "hammer", "staff", "crossbow") var back_weapon_preview: String = "bow":
	set(value):
		back_weapon_preview = value
		_update_back_visuals()
		_on_frame_changed()

## Exibir ou ocultar o escudo nas costas como modelo de referência.
@export var show_shield_on_back: bool = true:
	set(value):
		show_shield_on_back = value
		_update_back_visuals()

@export_group("4. Ajustes do Alvo Selecionado")
## Posição ou offset do alvo atual.
@export var socket_position: Vector2 = Vector2.ZERO:
	set(value):
		socket_position = value
		_apply_position_to_target(value)

## Rotação em graus do alvo atual.
@export_range(-360.0, 360.0, 0.5, "suffix:°") var socket_rotation: float = 0.0:
	set(value):
		socket_rotation = value
		_apply_rotation_to_target(value)

## Visibilidade do item na mão neste frame.
@export var item_visible_in_frame: bool = true:
	set(value):
		item_visible_in_frame = value
		if _weapon_instance and is_instance_valid(_weapon_instance):
			_weapon_instance.visible = value

@export_group("5. Gravação no Arquivo")
## Clique nesta caixinha para SALVAR no arquivo correspondente!
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
var _secondary_weapon_data: WeaponData = null
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

	var sec_path: String = WEAPON_DATA_PATHS.get(back_weapon_preview, "")
	if ResourceLoader.exists(sec_path):
		_secondary_weapon_data = load(sec_path) as WeaponData
	else:
		_secondary_weapon_data = null

func _apply_position_to_target(val: Vector2) -> void:
	if target_socket == "Mão Principal (MainHandSocket)":
		if main_hand_socket and main_hand_socket.position != val:
			main_hand_socket.position = val
	elif target_socket == "Tronco nas Costas (BackSocket - Frame a Frame)":
		if back_socket_weapon and back_socket_weapon.position != val:
			back_socket_weapon.position = val
		if back_socket_shield:
			back_socket_shield.position = val + Vector2(-3.0, 0.0)
	elif target_socket == "Ajuste da Arma nas Costas (Ângulo & Offset)":
		if _back_weapon_instance and is_instance_valid(_back_weapon_instance) and _back_weapon_instance.position != val:
			_back_weapon_instance.position = val

func _apply_rotation_to_target(val: float) -> void:
	if target_socket == "Mão Principal (MainHandSocket)":
		if main_hand_socket and not is_equal_approx(main_hand_socket.rotation_degrees, val):
			main_hand_socket.rotation_degrees = val
	elif target_socket == "Tronco nas Costas (BackSocket - Frame a Frame)":
		# O socket de tronco do corpo fica com rotação 0
		if back_socket_weapon:
			back_socket_weapon.rotation_degrees = 0.0
	elif target_socket == "Ajuste da Arma nas Costas (Ângulo & Offset)":
		if _back_weapon_instance and is_instance_valid(_back_weapon_instance) and not is_equal_approx(_back_weapon_instance.rotation_degrees, val):
			_back_weapon_instance.rotation_degrees = val

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
		back_w.rotation_degrees = 0.0 # No jogo o socket do tronco não gira; quem gira é a arma
		for c in back_w.get_children():
			c.queue_free()
		_back_weapon_instance = null

		if back_weapon_preview != "none":
			var sec_path: String = WEAPON_DATA_PATHS.get(back_weapon_preview, "")
			if ResourceLoader.exists(sec_path):
				_secondary_weapon_data = load(sec_path) as WeaponData

			var scene_path: String = VISUAL_SCENES.get(back_weapon_preview, "")
			if ResourceLoader.exists(scene_path):
				var scene := load(scene_path) as PackedScene
				if scene:
					_back_weapon_instance = scene.instantiate() as Node2D
					back_w.add_child(_back_weapon_instance)
					if _secondary_weapon_data:
						_back_weapon_instance.position = _secondary_weapon_data.back_offset
						_back_weapon_instance.rotation_degrees = _secondary_weapon_data.back_rotation_degrees
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

	# 1. Pose do aventureiro no frame
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(selected_animation):
		sprite.animation = selected_animation
		sprite.frame = current_frame

	var hand := _get_node_safe("Visual/MainHandSocket") as Marker2D
	var back_w := _get_node_safe("Visual/BackSocketWeapon") as Marker2D
	var back_s := _get_node_safe("Visual/BackSocketShield") as Marker2D

	# 2. Atualiza a mão principal com o profile selecionado
	if _current_profile_resource and _current_profile_resource.has_method("get_frame_data"):
		var data: Dictionary = _current_profile_resource.get_frame_data(selected_animation, current_frame)
		if hand:
			hand.position = data.get("pos", Vector2(6, -20))
			hand.rotation_degrees = data.get("rot", -35.0)
		if _weapon_instance and is_instance_valid(_weapon_instance):
			_weapon_instance.visible = data.get("visible", true)

	# 3. Atualiza os sockets do tronco com o back_socket.tres
	var torso_pos := Vector2(-3, -20)
	if _back_profile_resource and _back_profile_resource.has_method("get_frame_pos"):
		torso_pos = _back_profile_resource.get_frame_pos(selected_animation, current_frame)

	if back_w:
		back_w.position = torso_pos
		back_w.rotation_degrees = 0.0
	if back_s:
		back_s.position = torso_pos + Vector2(-3.0, 0.0)

	# 4. Atualiza os inputs do Inspector de acordo com o Target Socket ativo
	if target_socket == "Mão Principal (MainHandSocket)":
		if hand:
			socket_position = hand.position
			socket_rotation = hand.rotation_degrees
			if _weapon_instance and is_instance_valid(_weapon_instance):
				item_visible_in_frame = _weapon_instance.visible
		status_message = "Mão Principal: %s [%s - Frame %d]" % [selected_weapon_profile, selected_animation, current_frame]

	elif target_socket == "Tronco nas Costas (BackSocket - Frame a Frame)":
		if back_w:
			socket_position = back_w.position
			socket_rotation = 0.0
		status_message = "Tronco nas Costas (Global): back_socket.tres [%s - Frame %d]" % [selected_animation, current_frame]

	elif target_socket == "Ajuste da Arma nas Costas (Ângulo & Offset)":
		if _secondary_weapon_data:
			socket_position = _secondary_weapon_data.back_offset
			socket_rotation = _secondary_weapon_data.back_rotation_degrees
		elif _back_weapon_instance and is_instance_valid(_back_weapon_instance):
			socket_position = _back_weapon_instance.position
			socket_rotation = _back_weapon_instance.rotation_degrees
		status_message = "Arma nas Costas: %s (Offset & Ângulo Base)" % back_weapon_preview

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		if target_socket == "Mão Principal (MainHandSocket)":
			if main_hand_socket:
				if main_hand_socket.position != socket_position:
					socket_position = main_hand_socket.position
				if not is_equal_approx(main_hand_socket.rotation_degrees, socket_rotation):
					socket_rotation = main_hand_socket.rotation_degrees
		elif target_socket == "Tronco nas Costas (BackSocket - Frame a Frame)":
			if back_socket_weapon:
				if back_socket_weapon.position != socket_position:
					socket_position = back_socket_weapon.position
		elif target_socket == "Ajuste da Arma nas Costas (Ângulo & Offset)":
			if _back_weapon_instance and is_instance_valid(_back_weapon_instance):
				if _back_weapon_instance.position != socket_position:
					socket_position = _back_weapon_instance.position
				if not is_equal_approx(_back_weapon_instance.rotation_degrees, socket_rotation):
					socket_rotation = _back_weapon_instance.rotation_degrees

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

	elif target_socket == "Tronco nas Costas (BackSocket - Frame a Frame)":
		if not _back_profile_resource:
			status_message = "ERRO: Perfil back_socket.tres não encontrado!"
			return

		var pos_prop := "%s_%d_pos" % [selected_animation, current_frame]
		_back_profile_resource.set(pos_prop, socket_position)

		var back_path := "res://src/entities/equipment/socket_profiles/back_socket.tres"
		var err := ResourceSaver.save(_back_profile_resource, back_path)
		if err == OK:
			status_message = "SUCESSO! Tronco salvo em back_socket.tres -> [%s Frame %d] (Pos: %v)" % [
				selected_animation, current_frame, socket_position
			]
			print(status_message)
		else:
			status_message = "ERRO ao salvar back_socket.tres: código %d" % err

	elif target_socket == "Ajuste da Arma nas Costas (Ângulo & Offset)":
		if not _secondary_weapon_data:
			status_message = "ERRO: WeaponData da arma %s não encontrado!" % back_weapon_preview
			return

		_secondary_weapon_data.back_offset = socket_position
		_secondary_weapon_data.back_rotation_degrees = socket_rotation

		var w_path: String = WEAPON_DATA_PATHS.get(back_weapon_preview, "")
		var err := ResourceSaver.save(_secondary_weapon_data, w_path)
		if err == OK:
			status_message = "SUCESSO! %s salvo -> back_offset: %v, back_rotation: %.1f°" % [
				back_weapon_preview, socket_position, socket_rotation
			]
			print(status_message)
		else:
			status_message = "ERRO ao salvar %s: código %d" % [back_weapon_preview, err]
