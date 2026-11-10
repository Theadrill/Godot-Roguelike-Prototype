@tool
class_name WeaponSocketCalibrator
extends Node2D

## Ferramenta visual de calibração de sockets de armas na Viewport 2D do Godot.
## Permite selecionar a arma, a animação e o frame, ver o sprite na tela 2D
## e arrastar a arma livremente com o mouse, gravando diretamente no arquivo de perfil (.tres).

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

@export_group("1. Seleção de Arma & Animação")
## Escolha a categoria ou variação da arma para editar.
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

@export_group("2. Ajustes do Frame Atual")
## Posição do socket no frame atual. Você pode editar aqui OU arrastar o nó MainHandSocket diretamente na Viewport 2D com o mouse!
@export var socket_position: Vector2 = Vector2.ZERO:
	set(value):
		socket_position = value
		if main_hand_socket and main_hand_socket.position != value:
			main_hand_socket.position = value

## Rotação do socket em graus no frame atual.
@export_range(-360.0, 360.0, 0.5, "suffix:°") var socket_rotation: float = 0.0:
	set(value):
		socket_rotation = value
		if main_hand_socket and not is_equal_approx(main_hand_socket.rotation_degrees, value):
			main_hand_socket.rotation_degrees = value

## Visibilidade da arma neste frame (true = visível na mão, false = oculta).
@export var weapon_visible_in_frame: bool = true:
	set(value):
		weapon_visible_in_frame = value
		if _weapon_instance and is_instance_valid(_weapon_instance):
			_weapon_instance.visible = value

@export_group("3. Gravação no Arquivo")
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

func _ready() -> void:
	_load_resources()
	_update_weapon_visual()
	_on_configuration_changed()

func _load_resources() -> void:
	var path := "res://src/entities/equipment/socket_profiles/%s.tres" % selected_weapon_profile
	if ResourceLoader.exists(path):
		_current_profile_resource = load(path) as WeaponSocketProfile
	var back_path := "res://src/entities/equipment/socket_profiles/back_socket.tres"
	if ResourceLoader.exists(back_path):
		_back_profile_resource = load(back_path) as BackSocketProfile

func _update_weapon_visual() -> void:
	if not main_hand_socket:
		main_hand_socket = get_node_or_null("Visual/MainHandSocket") as Marker2D
	if not main_hand_socket:
		return

	for c in main_hand_socket.get_children():
		c.queue_free()
	_weapon_instance = null

	var scene_path: String = VISUAL_SCENES.get(selected_weapon_profile, VISUAL_SCENES["sword"])
	if ResourceLoader.exists(scene_path):
		var scene := load(scene_path) as PackedScene
		if scene:
			_weapon_instance = scene.instantiate() as Node2D
			main_hand_socket.add_child(_weapon_instance)

func _on_configuration_changed() -> void:
	_load_resources()
	_update_weapon_visual()

	var max_f: int = ANIMATION_FRAME_COUNTS.get(selected_animation, 4) - 1
	if current_frame > max_f:
		current_frame = 0

	_on_frame_changed()

func _on_frame_changed() -> void:
	if not character_sprite:
		character_sprite = get_node_or_null("Visual/CharacterSprite") as AnimatedSprite2D
	if not character_sprite:
		return

	# Atualiza o sprite do personagem para a pose do frame escolhido
	if character_sprite.sprite_frames and character_sprite.sprite_frames.has_animation(selected_animation):
		character_sprite.animation = selected_animation
		character_sprite.frame = current_frame

	# Carrega os dados previamente salvos daquele frame
	if _current_profile_resource and _current_profile_resource.has_method("get_frame_data"):
		var data: Dictionary = _current_profile_resource.get_frame_data(selected_animation, current_frame)
		socket_position = data.get("pos", Vector2(6, -20))
		socket_rotation = data.get("rot", -35.0)
		weapon_visible_in_frame = data.get("visible", true)
		if main_hand_socket:
			main_hand_socket.position = socket_position
			main_hand_socket.rotation_degrees = socket_rotation
		if _weapon_instance and is_instance_valid(_weapon_instance):
			_weapon_instance.visible = weapon_visible_in_frame

	# Atualiza a posição das costas caso o usuário queira visualizar
	if not back_socket_weapon:
		back_socket_weapon = get_node_or_null("Visual/BackSocketWeapon") as Marker2D
	if _back_profile_resource and _back_profile_resource.has_method("get_frame_pos") and back_socket_weapon:
		var torso_pos: Vector2 = _back_profile_resource.get_frame_pos(selected_animation, current_frame)
		back_socket_weapon.position = torso_pos
		if back_socket_shield:
			back_socket_shield.position = torso_pos + Vector2(-3.0, 0.0)

	status_message = "Carregado: %s [%s - Frame %d]" % [selected_weapon_profile, selected_animation, current_frame]

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		# Detecta quando o usuário clica e arrasta o nó MainHandSocket diretamente na Viewport 2D com o mouse
		if main_hand_socket:
			if main_hand_socket.position != socket_position:
				socket_position = main_hand_socket.position
			if not is_equal_approx(main_hand_socket.rotation_degrees, socket_rotation):
				socket_rotation = main_hand_socket.rotation_degrees

func save_current_frame_data() -> void:
	_load_resources()
	if not _current_profile_resource:
		status_message = "ERRO: Perfil não encontrado!"
		return

	var pos_prop := "%s_%d_pos" % [selected_animation, current_frame]
	var rot_prop := "%s_%d_rot" % [selected_animation, current_frame]
	var vis_prop := "%s_%d_visible" % [selected_animation, current_frame]

	_current_profile_resource.set(pos_prop, socket_position)
	_current_profile_resource.set(rot_prop, socket_rotation)
	_current_profile_resource.set(vis_prop, weapon_visible_in_frame)

	var path := "res://src/entities/equipment/socket_profiles/%s.tres" % selected_weapon_profile
	var err := ResourceSaver.save(_current_profile_resource, path)
	if err == OK:
		status_message = "SUCESSO! Salvo em %s.tres -> [%s Frame %d] (Pos: %v, Rot: %.1f°)" % [
			selected_weapon_profile, selected_animation, current_frame, socket_position, socket_rotation
		]
		print(status_message)
	else:
		status_message = "ERRO ao salvar no arquivo: código %d" % err
