@tool
class_name WeaponSocketCalibrator
extends Node2D

## Ferramenta visual unificada de calibração de armas e escudos (Mão e Costas).
## Permite selecionar Arma ou Escudo, escolher se quer calibrar na Mão ou nas Costas,
## ajustar o frame, arrastar e girar livremente na Viewport 2D com o mouse e salvar no .tres correspondente!

const WEAPON_SCENES: Dictionary = {
	"sword": "res://src/entities/equipment/swords/sword_visual.tscn",
	"sword_2": "res://src/entities/equipment/swords/sword_visual.tscn",
	"dagger": "res://src/entities/equipment/daggers/dagger_visual.tscn",
	"dagger_2": "res://src/entities/equipment/daggers/dagger_visual.tscn",
	"hammer": "res://src/entities/equipment/hammers/hammer_visual.tscn",
	"hammer_2": "res://src/entities/equipment/hammers/hammer_visual.tscn",
	"axe": "res://src/entities/equipment/axes/axe_visual.tscn",
	"axe_2": "res://src/entities/equipment/axes/axe_visual.tscn",
	"staff": "res://src/entities/equipment/staffs/staff_visual.tscn",
	"staff_2": "res://src/entities/equipment/staffs/staff_visual.tscn",
	"bow": "res://src/entities/equipment/bows/bow_visual.tscn",
	"bow_2": "res://src/entities/equipment/bows/bow_visual.tscn",
	"crossbow": "res://src/entities/equipment/crossbows/crossbow_visual.tscn",
	"crossbow_2": "res://src/entities/equipment/crossbows/crossbow_visual.tscn",
}

const SHIELD_SCENES: Dictionary = {
	"shield": "res://src/entities/equipment/shields/shield_visual.tscn",
	"shield_2": "res://src/entities/equipment/shields/shield_visual.tscn",
}

const WEAPON_DATA_PATHS: Dictionary = {
	"sword": "res://src/entities/equipment/swords/weapon_sword_base.tres",
	"sword_2": "res://src/entities/equipment/swords/weapon_sword_base.tres",
	"dagger": "res://src/entities/equipment/daggers/weapon_dagger_base.tres",
	"dagger_2": "res://src/entities/equipment/daggers/weapon_dagger_base.tres",
	"hammer": "res://src/entities/equipment/hammers/weapon_hammer_base.tres",
	"hammer_2": "res://src/entities/equipment/hammers/weapon_hammer_base.tres",
	"axe": "res://src/entities/equipment/axes/weapon_axe_base.tres",
	"axe_2": "res://src/entities/equipment/axes/weapon_axe_base.tres",
	"staff": "res://src/entities/equipment/staffs/weapon_staff_base.tres",
	"staff_2": "res://src/entities/equipment/staffs/weapon_staff_base.tres",
	"bow": "res://src/entities/equipment/bows/weapon_bow_base.tres",
	"bow_2": "res://src/entities/equipment/bows/weapon_bow_base.tres",
	"crossbow": "res://src/entities/equipment/crossbows/weapon_crossbow_base.tres",
	"crossbow_2": "res://src/entities/equipment/crossbows/weapon_crossbow_base.tres",
}

const ATTACK_ANIMATIONS: Array[String] = [
	"attack1",
	"attack2",
	"attack3",
	"air_attack1",
	"air_attack2",
	"air_attack3",
	"air_attack",
]

const ANIMATION_FRAME_COUNTS: Dictionary = {
	"idle": 4,
	"run": 6,
	"jump": 4,
	"crouch": 4,
	"fall": 2,
	"fall_from_jump": 3,
	"slide": 2,
	"roll": 1,
	"double_jump": 4,
	"wall_cling": 1,
	"wall_slide": 2,
	"corner_climb": 5,
	"attack1": 5,
	"attack2": 6,
	"attack3": 6,
	"air_attack1": 4,
	"air_attack2": 4,
	"air_attack3": 7,
	"air_attack": 4,
	"cast": 4,
	"channeling": 2,
	"block": 3,
	"block_loop": 2,
	"stagger": 3,
}

@export_group("1. O que você quer calibrar?")
## Escolha o item e o local que deseja calibrar:
## - Arma na Mão: Ajusta a arma empunhada na mão principal.
## - Arma nas Costas: Ajusta a arma de reserva guardada nas costas.
## - Escudo na Mão: Ajusta o escudo erguido em posição de guarda/mão secundária.
## - Escudo nas Costas: Ajusta o escudo guardado nas costas.
@export_enum("Arma na Mão (MainHandSocket)", "Arma nas Costas (BackSocketWeapon)", "Escudo na Mão (OffHandSocket)", "Escudo nas Costas (BackSocketShield)") var socket_target: String = "Arma na Mão (MainHandSocket)":
	set(value):
		socket_target = value
		_on_configuration_changed()

## Escolha a arma (usado quando estiver calibrando Arma na Mão ou nas Costas).
@export_enum("sword", "sword_2", "dagger", "dagger_2", "hammer", "hammer_2", "axe", "axe_2", "staff", "staff_2", "bow", "bow_2", "crossbow", "crossbow_2") var selected_weapon: String = "sword":
	set(value):
		selected_weapon = value
		_on_configuration_changed()

## Escolha o escudo (usado quando estiver calibrando Escudo na Mão ou nas Costas).
@export_enum("shield", "shield_2") var selected_shield: String = "shield":
	set(value):
		selected_shield = value
		_on_configuration_changed()

@export_group("2. Animação, Frame & File")
## Escolha a animação do aventureiro para visualizar e calibrar.
@export_enum("idle", "run", "jump", "crouch", "fall", "fall_from_jump", "slide", "roll", "double_jump", "wall_cling", "wall_slide", "corner_climb", "attack1", "attack2", "attack3", "air_attack1", "air_attack2", "air_attack3", "cast", "channeling", "block", "block_loop", "stagger") var selected_animation: String = "idle":
	set(value):
		selected_animation = value
		_on_configuration_changed()

## Escolha o frame específico da animação.
@export_range(0, 7, 1) var current_frame: int = 0:
	set(value):
		var max_f: int = ANIMATION_FRAME_COUNTS.get(selected_animation, 4) - 1
		current_frame = clampi(value, 0, max_f)
		_on_frame_changed()

## Simulação da rotação da cambalhota (0°, 90°, 180°, 270°). Só tem efeito visual ao inspecionar "roll".
@export_enum("0°", "90°", "180°", "270°") var roll_preview_angle: String = "0°":
	set(value):
		roll_preview_angle = value
		_apply_roll_preview()

## Clique nesta caixinha para SALVAR a posição, rotação, inversão e Z-Index atuais diretamente no .tres correspondente!
@export var SAVE_FRAME_TO_PROFILE: bool = false:
	set(value):
		if value:
			save_current_frame_data()
		SAVE_FRAME_TO_PROFILE = false

## Pega todo o posicionamento, rotação, Z-index, visibilidade e flips do frame atual e aplica/salva em TODOS OS FRAMES DA ANIMAÇÃO ATUAL (ex: apenas nos frames de run, sem tocar em idle ou outras)!
@export var APPLY_TO_CURRENT_ANIMATION: bool = false:
	set(value):
		if value:
			_prompt_apply_to_current_animation()
		APPLY_TO_CURRENT_ANIMATION = false

@export_group("3. Elementos de Apoio & Referência")
## Arma secundária para ver nas costas como referência.
@export_enum("none", "bow", "sword", "dagger", "hammer", "axe", "staff", "crossbow") var reference_secondary_weapon: String = "bow":
	set(value):
		reference_secondary_weapon = value
		_update_visual_instances()
		_on_frame_changed()

## Exibir ou ocultar o escudo nas costas quando não estiver calibrando o escudo.
@export var show_shield_reference: bool = true:
	set(value):
		show_shield_reference = value
		_update_visual_instances()
		_on_frame_changed()

@export_group("4. Ajustes do Frame Atual (X, Y, Ângulo, Inversão e Z-Index)")
## Posição X do socket (step de 0.1 px, sem barra de slider).
@export_range(-200.0, 200.0, 0.1, "or_less", "or_greater", "hide_slider", "suffix:px") var socket_pos_x: float = 0.0:
	set(value):
		socket_pos_x = value
		if not _is_syncing_from_frame:
			var node := _get_active_marker()
			if node and not is_equal_approx(node.position.x, value):
				node.position.x = value

## Posição Y do socket (step de 0.1 px, sem barra de slider).
@export_range(-200.0, 200.0, 0.1, "or_less", "or_greater", "hide_slider", "suffix:px") var socket_pos_y: float = 0.0:
	set(value):
		socket_pos_y = value
		if not _is_syncing_from_frame:
			var node := _get_active_marker()
			if node and not is_equal_approx(node.position.y, value):
				node.position.y = value

@export_subgroup("Ajuste Fino de Posição (Botões X e Y)")
@export_tool_button("◄ -1.0 px (X)") var btn_nudge_x_minus_1: Callable = _on_nudge_x_m1
@export_tool_button("◄ -0.1 px (X)") var btn_nudge_x_minus_01: Callable = _on_nudge_x_m01
@export_tool_button("► +0.1 px (X)") var btn_nudge_x_plus_01: Callable = _on_nudge_x_p01
@export_tool_button("► +1.0 px (X)") var btn_nudge_x_plus_1: Callable = _on_nudge_x_p1

@export_tool_button("▲ -1.0 px (Y)") var btn_nudge_y_minus_1: Callable = _on_nudge_y_m1
@export_tool_button("▲ -0.1 px (Y)") var btn_nudge_y_minus_01: Callable = _on_nudge_y_m01
@export_tool_button("▼ +0.1 px (Y)") var btn_nudge_y_plus_01: Callable = _on_nudge_y_p01
@export_tool_button("▼ +1.0 px (Y)") var btn_nudge_y_plus_1: Callable = _on_nudge_y_p1
@export_subgroup("")

## Propriedade calculada Vector2 para compatibilidade de código e desserialização
var socket_position: Vector2:
	get:
		return Vector2(socket_pos_x, socket_pos_y)
	set(value):
		socket_pos_x = value.x
		socket_pos_y = value.y
		if not _is_syncing_from_frame:
			var node := _get_active_marker()
			if node and node.position != value:
				node.position = value

## Rotação em graus no frame atual.
@export_range(-360.0, 360.0, 0.5, "suffix:°") var socket_rotation: float = 0.0:
	set(value):
		socket_rotation = value
		if not _is_syncing_from_frame:
			var node := _get_active_marker()
			if node and not is_equal_approx(node.rotation_degrees, value):
				node.rotation_degrees = value

## Inverter horizontalmente o sprite (Flip Horizontal / Eixo X).
@export var socket_flip_h: bool = false:
	set(value):
		socket_flip_h = value
		if not _is_syncing_from_frame:
			_apply_active_visual_flip()

## Inverter verticalmente o sprite (Flip Vertical / Eixo Y).
@export var socket_flip_v: bool = false:
	set(value):
		socket_flip_v = value
		if not _is_syncing_from_frame:
			_apply_active_visual_flip()

## Profundidade / Z-Index no frame atual (-2 costas fundas, -1 atrás do corpo, 0 neutro, 1 na frente do corpo/cintura).
@export_range(-10, 10, 1) var socket_z_index: int = -2:
	set(value):
		socket_z_index = value
		if not _is_syncing_from_frame:
			var node := _get_active_marker()
			if node and node.z_index != value:
				node.z_index = value

## Visibilidade do item neste frame (true = visível, false = oculto).
@export var item_visible_in_frame: bool = true:
	set(value):
		item_visible_in_frame = value
		if not _is_syncing_from_frame:
			var vis := _get_active_visual_instance()
			if vis and is_instance_valid(vis):
				vis.visible = value

@export_group("5. Calibração de Slash (Offset & Escala)")
## Exibe ou oculta a prévia do efeito de corte (SlashEffect) quando estiver inspecionando uma animação de ataque (attack1, attack2, attack3, air_attack1, air_attack3).
@export var show_slash_preview: bool = true:
	set(value):
		show_slash_preview = value
		_update_slash_preview()

## Deslocamento X do Slash na tela (relativo à origem do pé do personagem).
@export_range(-200.0, 200.0, 0.1, "or_less", "or_greater", "hide_slider", "suffix:px") var slash_offset_x: float = 0.0:
	set(value):
		slash_offset_x = value
		if not _is_syncing_slash:
			_apply_slash_transform_to_node()

## Deslocamento Y do Slash na tela (relativo à origem do pé do personagem).
@export_range(-200.0, 200.0, 0.1, "or_less", "or_greater", "hide_slider", "suffix:px") var slash_offset_y: float = 0.0:
	set(value):
		slash_offset_y = value
		if not _is_syncing_slash:
			_apply_slash_transform_to_node()

@export_subgroup("Ajuste Fino do Slash (Botões X e Y)")
@export_tool_button("◄ -1.0 px (Slash X)") var btn_slash_x_m1: Callable = _on_slash_x_m1
@export_tool_button("◄ -0.1 px (Slash X)") var btn_slash_x_m01: Callable = _on_slash_x_m01
@export_tool_button("► +0.1 px (Slash X)") var btn_slash_x_p01: Callable = _on_slash_x_p01
@export_tool_button("► +1.0 px (Slash X)") var btn_slash_x_p1: Callable = _on_slash_x_p1

@export_tool_button("▲ -1.0 px (Slash Y)") var btn_slash_y_m1: Callable = _on_slash_y_m1
@export_tool_button("▲ -0.1 px (Slash Y)") var btn_slash_y_m01: Callable = _on_slash_y_m01
@export_tool_button("▼ +0.1 px (Slash Y)") var btn_slash_y_p01: Callable = _on_slash_y_p01
@export_tool_button("▼ +1.0 px (Slash Y)") var btn_slash_y_p1: Callable = _on_slash_y_p1
@export_subgroup("")

## Escala X e Y do Slash na tela (1.0 = tamanho original).
@export var slash_preview_scale: Vector2 = Vector2.ONE:
	set(value):
		slash_preview_scale = value
		if not _is_syncing_slash:
			_apply_slash_transform_to_node()

## Inverter horizontalmente o desenho do Slash neste golpe.
@export var slash_preview_flip_h: bool = false:
	set(value):
		slash_preview_flip_h = value
		if not _is_syncing_slash:
			_apply_slash_transform_to_node()

## Inverter verticalmente o desenho do Slash neste golpe.
@export var slash_preview_flip_v: bool = false:
	set(value):
		slash_preview_flip_v = value
		if not _is_syncing_slash:
			_apply_slash_transform_to_node()

@export_subgroup("Salvar Calibração do Slash (Com Confirmação)")
@export_tool_button("💾 Salvar Slash no Set (Esta Animação)") var btn_save_slash_to_set: Callable = _prompt_save_slash_to_set
@export_tool_button("💾 Salvar Ajuste Individual na Arma") var btn_save_slash_to_weapon: Callable = _prompt_save_slash_to_weapon
@export_subgroup("")

@export_group("6. Status")
## Mensagem de feedback do último salvamento.
@export var status_message: String = "Pronto para calibrar."

@onready var character_sprite: AnimatedSprite2D = $Visual/CharacterSprite
@onready var main_hand_socket: Marker2D = $Visual/MainHandSocket
@onready var off_hand_socket: Marker2D = $Visual/OffHandSocket
@onready var back_socket_weapon: Marker2D = $Visual/BackSocketWeapon
@onready var back_socket_shield: Marker2D = $Visual/BackSocketShield
@onready var slash_effect: AnimatedSprite2D = get_node_or_null("Visual/SlashEffect") as AnimatedSprite2D

var _weapon_profile_resource: WeaponSocketProfile = null
var _shield_profile_resource: WeaponSocketProfile = null
var _ref_sec_weapon_profile: WeaponSocketProfile = null
var _weapon_data_resource: WeaponData = null

var _main_hand_instance: Node2D = null
var _off_hand_instance: Node2D = null
var _back_weapon_instance: Node2D = null
var _back_shield_instance: Node2D = null
var _is_syncing_from_frame: bool = false
var _is_syncing_slash: bool = false

func _ready() -> void:
	_load_resources()
	_update_visual_instances()
	_on_configuration_changed()

func _load_resources() -> void:
	var sprite := _get_node_safe("Visual/CharacterSprite") as AnimatedSprite2D
	if sprite and Engine.is_editor_hint():
		var expected_frames: int = ANIMATION_FRAME_COUNTS.get(selected_animation, 4)
		if not sprite.sprite_frames or (sprite.sprite_frames.has_animation(selected_animation) and sprite.sprite_frames.get_frame_count(selected_animation) < expected_frames):
			var fresh_frames := ResourceLoader.load("res://assets/player/adventurer/player_frames.tres", "", ResourceLoader.CACHE_MODE_REPLACE) as SpriteFrames
			if fresh_frames:
				sprite.sprite_frames = fresh_frames

	var w_path := "res://src/entities/equipment/socket_profiles/%s.tres" % selected_weapon
	if ResourceLoader.exists(w_path):
		_weapon_profile_resource = load(w_path) as WeaponSocketProfile
	else:
		_weapon_profile_resource = null

	var wd_path: String = WEAPON_DATA_PATHS.get(selected_weapon, "")
	if wd_path != "" and ResourceLoader.exists(wd_path):
		_weapon_data_resource = load(wd_path) as WeaponData
	else:
		_weapon_data_resource = null

	var s_path := "res://src/entities/equipment/socket_profiles/%s.tres" % selected_shield
	if ResourceLoader.exists(s_path):
		_shield_profile_resource = load(s_path) as WeaponSocketProfile
	else:
		_shield_profile_resource = null

	if reference_secondary_weapon != "none":
		var ref_path := "res://src/entities/equipment/socket_profiles/%s.tres" % reference_secondary_weapon
		if ResourceLoader.exists(ref_path):
			_ref_sec_weapon_profile = load(ref_path) as WeaponSocketProfile
	else:
		_ref_sec_weapon_profile = null

func _get_active_marker() -> Marker2D:
	if socket_target == "Arma na Mão (MainHandSocket)":
		if not main_hand_socket:
			main_hand_socket = get_node_or_null("Visual/MainHandSocket") as Marker2D
		return main_hand_socket
	elif socket_target == "Arma nas Costas (BackSocketWeapon)":
		if not back_socket_weapon:
			back_socket_weapon = get_node_or_null("Visual/BackSocketWeapon") as Marker2D
		return back_socket_weapon
	elif socket_target == "Escudo na Mão (OffHandSocket)":
		if not off_hand_socket:
			off_hand_socket = get_node_or_null("Visual/OffHandSocket") as Marker2D
		return off_hand_socket
	elif socket_target == "Escudo nas Costas (BackSocketShield)":
		if not back_socket_shield:
			back_socket_shield = get_node_or_null("Visual/BackSocketShield") as Marker2D
		return back_socket_shield
	return null

func _get_active_visual_instance() -> Node2D:
	if socket_target == "Arma na Mão (MainHandSocket)":
		return _main_hand_instance
	elif socket_target == "Arma nas Costas (BackSocketWeapon)":
		return _back_weapon_instance
	elif socket_target == "Escudo na Mão (OffHandSocket)":
		return _off_hand_instance
	elif socket_target == "Escudo nas Costas (BackSocketShield)":
		return _back_shield_instance
	return null

func _update_visual_instances() -> void:
	var hand_w := _get_node_safe("Visual/MainHandSocket") as Marker2D
	var hand_s := _get_node_safe("Visual/OffHandSocket") as Marker2D
	var back_w := _get_node_safe("Visual/BackSocketWeapon") as Marker2D
	var back_s := _get_node_safe("Visual/BackSocketShield") as Marker2D

	# Limpa instâncias anteriores
	if hand_w:
		for c in hand_w.get_children(): c.queue_free()
		_main_hand_instance = null
	if hand_s:
		for c in hand_s.get_children(): c.queue_free()
		_off_hand_instance = null
	if back_w:
		for c in back_w.get_children(): c.queue_free()
		_back_weapon_instance = null
	if back_s:
		for c in back_s.get_children(): c.queue_free()
		_back_shield_instance = null

	# 1. Arma na mão principal (sempre aparece, exceto se desativada)
	if hand_w and selected_weapon != "none":
		var w_scene_path: String = WEAPON_SCENES.get(selected_weapon, "")
		if ResourceLoader.exists(w_scene_path):
			var scene := load(w_scene_path) as PackedScene
			if scene:
				_main_hand_instance = scene.instantiate() as Node2D
				hand_w.add_child(_main_hand_instance)
				_main_hand_instance.position = Vector2.ZERO
				_main_hand_instance.rotation_degrees = 0.0

	# 2. Escudo na mão (aparece se estiver calibrando Escudo na Mão OU durante "block"/"block_loop" com referência ativa)
	var is_block_anim: bool = (selected_animation in ["block", "block_loop"])
	var should_show_hand_shield: bool = (socket_target == "Escudo na Mão (OffHandSocket)") or (is_block_anim and show_shield_reference and socket_target != "Escudo nas Costas (BackSocketShield)")
	if hand_s and should_show_hand_shield:
		var s_scene_path: String = SHIELD_SCENES.get(selected_shield, "")
		if ResourceLoader.exists(s_scene_path):
			var s_scene := load(s_scene_path) as PackedScene
			if s_scene:
				_off_hand_instance = s_scene.instantiate() as Node2D
				hand_s.add_child(_off_hand_instance)
				_off_hand_instance.position = Vector2.ZERO
				_off_hand_instance.rotation_degrees = 0.0

	# 3. Arma nas costas (aparece se calibrando Arma nas Costas OU como referência)
	var sec_w := selected_weapon if socket_target == "Arma nas Costas (BackSocketWeapon)" else reference_secondary_weapon
	if back_w and sec_w != "none":
		var b_scene_path: String = WEAPON_SCENES.get(sec_w, "")
		if ResourceLoader.exists(b_scene_path):
			var b_scene := load(b_scene_path) as PackedScene
			if b_scene:
				_back_weapon_instance = b_scene.instantiate() as Node2D
				back_w.add_child(_back_weapon_instance)
				_back_weapon_instance.position = Vector2.ZERO
				_back_weapon_instance.rotation_degrees = 0.0
				_back_weapon_instance.z_index = 0

	# 4. Escudo nas costas (aparece se calibrando Escudo nas Costas OU se show_shield_reference=true quando não estiver na mão)
	var should_show_back_shield := (socket_target == "Escudo nas Costas (BackSocketShield)") or (show_shield_reference and not should_show_hand_shield)
	if back_s and should_show_back_shield:
		var bs_scene_path: String = SHIELD_SCENES.get(selected_shield, "")
		if ResourceLoader.exists(bs_scene_path):
			var bs_scene := load(bs_scene_path) as PackedScene
			if bs_scene:
				_back_shield_instance = bs_scene.instantiate() as Node2D
				back_s.add_child(_back_shield_instance)
				_back_shield_instance.position = Vector2.ZERO
				_back_shield_instance.rotation_degrees = 0.0
				_back_shield_instance.z_index = 0

func _get_node_safe(path: String) -> Node:
	return get_node_or_null(path)

func _on_configuration_changed() -> void:
	_load_resources()
	_update_visual_instances()

	var max_f: int = ANIMATION_FRAME_COUNTS.get(selected_animation, 4) - 1
	if current_frame > max_f:
		current_frame = 0

	_apply_roll_preview()
	_sync_slash_from_weapon_data()
	_on_frame_changed()

func _apply_roll_preview() -> void:
	var visual_node := get_node_or_null("Visual") as Node2D
	if not visual_node:
		return
	if selected_animation == "roll":
		var deg := 0.0
		match roll_preview_angle:
			"90°": deg = 90.0
			"180°": deg = 180.0
			"270°": deg = 270.0
			_: deg = 0.0
		if is_zero_approx(deg):
			visual_node.rotation = 0.0
			visual_node.position = Vector2.ZERO
		else:
			var rad := deg_to_rad(deg)
			var pivot := Vector2(0.0, -10.0)
			visual_node.rotation = rad
			visual_node.position = pivot - pivot.rotated(rad)
	else:
		visual_node.rotation = 0.0
		visual_node.position = Vector2.ZERO

func _on_frame_changed() -> void:
	var sprite := _get_node_safe("Visual/CharacterSprite") as AnimatedSprite2D
	if not sprite:
		return

	# 1. Pose do aventureiro no frame selecionado
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(selected_animation):
		sprite.animation = selected_animation
		sprite.frame = current_frame
		if selected_animation == "corner_climb":
			sprite.position = Vector2(-6.5, 4.0)
		else:
			sprite.position = Vector2(-2, -29)

	var hand_w := _get_node_safe("Visual/MainHandSocket") as Marker2D
	var hand_s := _get_node_safe("Visual/OffHandSocket") as Marker2D
	var back_w := _get_node_safe("Visual/BackSocketWeapon") as Marker2D
	var back_s := _get_node_safe("Visual/BackSocketShield") as Marker2D

	# 2. Posição da Arma na Mão Principal (Tudo na mão = 2)
	if hand_w and _weapon_profile_resource and _weapon_profile_resource.has_method("get_frame_data"):
		var w_data: Dictionary = _weapon_profile_resource.get_frame_data(selected_animation, current_frame)
		hand_w.position = w_data.get("pos", Vector2(6, -20))
		hand_w.rotation_degrees = w_data.get("rot", -35.0)
		var hand_z: int = w_data.get("z_index", 2)
		if selected_animation == "corner_climb" and hand_z < 1:
			hand_z = 2
		hand_w.z_index = hand_z
		if _main_hand_instance and is_instance_valid(_main_hand_instance):
			_main_hand_instance.visible = w_data.get("visible", true)
			_apply_visual_flip(_main_hand_instance, w_data.get("flip_h", false), w_data.get("flip_v", false))

	# 3. Posição do Escudo na Mão (OffHandSocket)
	if hand_s and _shield_profile_resource and _shield_profile_resource.has_method("get_frame_data"):
		var s_hand_data: Dictionary = _shield_profile_resource.get_frame_data(selected_animation, current_frame)
		hand_s.position = s_hand_data.get("pos", Vector2(7, -19))
		hand_s.rotation_degrees = s_hand_data.get("rot", 0.0)
		hand_s.z_index = s_hand_data.get("z_index", 2)
		if _off_hand_instance and is_instance_valid(_off_hand_instance):
			_off_hand_instance.visible = s_hand_data.get("visible", true)
			_apply_visual_flip(_off_hand_instance, s_hand_data.get("flip_h", false), s_hand_data.get("flip_v", false))

	# 4. Posição da Arma nas Costas (BackSocketWeapon)
	var active_back_weapon_prof := _weapon_profile_resource if socket_target == "Arma nas Costas (BackSocketWeapon)" else _ref_sec_weapon_profile
	if back_w and active_back_weapon_prof and active_back_weapon_prof.has_method("get_back_frame_data"):
		var bw_data: Dictionary = active_back_weapon_prof.get_back_frame_data(selected_animation, current_frame)
		back_w.position = bw_data.get("pos", Vector2(-6, -24))
		back_w.rotation_degrees = bw_data.get("rot", -175.0)
		var back_weapon_name: String = selected_weapon if socket_target == "Arma nas Costas (BackSocketWeapon)" else reference_secondary_weapon
		var fallback_back_z: int = 1 if "dagger" in back_weapon_name else -2
		back_w.z_index = bw_data.get("z_index", fallback_back_z)
		if _back_weapon_instance and is_instance_valid(_back_weapon_instance):
			_back_weapon_instance.visible = bw_data.get("visible", true)
			_apply_visual_flip(_back_weapon_instance, bw_data.get("flip_h", false), bw_data.get("flip_v", false))

	# 5. Posição do Escudo nas Costas (BackSocketShield)
	if back_s and _shield_profile_resource and _shield_profile_resource.has_method("get_back_frame_data"):
		var bs_data: Dictionary = _shield_profile_resource.get_back_frame_data(selected_animation, current_frame)
		back_s.position = bs_data.get("pos", Vector2(-9, -24))
		back_s.rotation_degrees = bs_data.get("rot", 0.0)
		back_s.z_index = bs_data.get("z_index", -1)
		if _back_shield_instance and is_instance_valid(_back_shield_instance):
			_back_shield_instance.visible = bs_data.get("visible", true)
			_apply_visual_flip(_back_shield_instance, bs_data.get("flip_h", false), bs_data.get("flip_v", false))

	# 6. Atualiza os inputs do Inspector para o alvo ativo
	_is_syncing_from_frame = true
	var active_marker := _get_active_marker()
	if active_marker:
		socket_position = active_marker.position
		socket_pos_x = active_marker.position.x
		socket_pos_y = active_marker.position.y
		socket_rotation = active_marker.rotation_degrees
		socket_z_index = active_marker.z_index

	var active_vis := _get_active_visual_instance()
	if active_vis and is_instance_valid(active_vis):
		item_visible_in_frame = active_vis.visible
		socket_flip_h = active_vis.scale.x < 0.0
		socket_flip_v = active_vis.scale.y < 0.0
	_is_syncing_from_frame = false

	_sync_slash_from_weapon_data()
	_update_slash_preview()

	status_message = "%s [%s] -> %s Frame %d (Z: %d, FlipH: %s, FlipV: %s)" % [
		_get_active_item_name(),
		socket_target,
		selected_animation,
		current_frame,
		socket_z_index,
		str(socket_flip_h),
		str(socket_flip_v)
	]

func _apply_visual_flip(instance: Node2D, flip_h: bool, flip_v: bool) -> void:
	if not instance or not is_instance_valid(instance):
		return
	var sx := absf(instance.scale.x)
	if sx < 0.001: sx = 0.8
	var sy := absf(instance.scale.y)
	if sy < 0.001: sy = 0.8
	instance.scale.x = -sx if flip_h else sx
	instance.scale.y = -sy if flip_v else sy

func _apply_active_visual_flip() -> void:
	var vis := _get_active_visual_instance()
	if vis and is_instance_valid(vis):
		_apply_visual_flip(vis, socket_flip_h, socket_flip_v)

func _get_active_item_name() -> String:
	if "Arma" in socket_target:
		return selected_weapon
	return selected_shield

func _on_nudge_x_m1() -> void:
	_nudge_x(-1.0)

func _on_nudge_x_m01() -> void:
	_nudge_x(-0.1)

func _on_nudge_x_p01() -> void:
	_nudge_x(0.1)

func _on_nudge_x_p1() -> void:
	_nudge_x(1.0)

func _on_nudge_y_m1() -> void:
	_nudge_y(-1.0)

func _on_nudge_y_m01() -> void:
	_nudge_y(-0.1)

func _on_nudge_y_p01() -> void:
	_nudge_y(0.1)

func _on_nudge_y_p1() -> void:
	_nudge_y(1.0)

func _nudge_x(delta: float) -> void:
	socket_pos_x = snappedf(socket_pos_x + delta, 0.1)
	notify_property_list_changed()

func _nudge_y(delta: float) -> void:
	socket_pos_y = snappedf(socket_pos_y + delta, 0.1)
	notify_property_list_changed()

func _on_slash_x_m1() -> void:
	_nudge_slash_x(-1.0)

func _on_slash_x_m01() -> void:
	_nudge_slash_x(-0.1)

func _on_slash_x_p01() -> void:
	_nudge_slash_x(0.1)

func _on_slash_x_p1() -> void:
	_nudge_slash_x(1.0)

func _on_slash_y_m1() -> void:
	_nudge_slash_y(-1.0)

func _on_slash_y_m01() -> void:
	_nudge_slash_y(-0.1)

func _on_slash_y_p01() -> void:
	_nudge_slash_y(0.1)

func _on_slash_y_p1() -> void:
	_nudge_slash_y(1.0)

func _nudge_slash_x(delta: float) -> void:
	slash_offset_x = snappedf(slash_offset_x + delta, 0.1)
	notify_property_list_changed()

func _nudge_slash_y(delta: float) -> void:
	slash_offset_y = snappedf(slash_offset_y + delta, 0.1)
	notify_property_list_changed()

func _get_matching_step_indices_for_animation(anim_name: String) -> Array[int]:
	var indices: Array[int] = []
	var is_air: bool = anim_name.begins_with("air_")
	if _weapon_data_resource and _weapon_data_resource.attack_set and not _weapon_data_resource.attack_set.steps.is_empty():
		var steps := _weapon_data_resource.attack_set.steps
		for i in range(steps.size()):
			var st: ComboStepData = steps[i]
			if not st:
				continue
			if is_air and String(st.air_body_animation) == anim_name:
				indices.append(i)
			elif not is_air and String(st.body_animation) == anim_name:
				indices.append(i)
	if indices.is_empty():
		match anim_name:
			"attack1", "air_attack1", "air_attack":
				indices.append(0)
			"attack2", "air_attack2":
				indices.append(1)
			"attack3", "air_attack3":
				indices.append(2)
			_:
				indices.append(0)
	return indices

func _sync_slash_from_weapon_data() -> void:
	if not (selected_animation in ATTACK_ANIMATIONS) or not _weapon_data_resource:
		return
	var is_air: bool = selected_animation.begins_with("air_")
	var indices := _get_matching_step_indices_for_animation(selected_animation)
	var step_idx: int = indices[0]
	var total_off: Vector2 = _weapon_data_resource.get_step_total_slash_offset(step_idx, is_air, current_frame)
	var total_sc: Vector2 = _weapon_data_resource.get_step_total_slash_scale(step_idx, is_air, current_frame)
	var fh: bool = _weapon_data_resource.get_step_slash_flip_h(step_idx)
	var fv: bool = _weapon_data_resource.get_step_slash_flip_v(step_idx)

	_is_syncing_slash = true
	slash_offset_x = total_off.x
	slash_offset_y = total_off.y
	slash_preview_scale = total_sc
	slash_preview_flip_h = fh
	slash_preview_flip_v = fv
	_is_syncing_slash = false

func _update_slash_preview() -> void:
	var se := _get_node_safe("Visual/SlashEffect") as AnimatedSprite2D
	if not se:
		return
	if not show_slash_preview or not (selected_animation in ATTACK_ANIMATIONS) or not _weapon_data_resource or not _weapon_data_resource.slash_enabled:
		se.visible = false
		return

	if Engine.is_editor_hint() and not se.sprite_frames:
		var sf := ResourceLoader.load("res://assets/effects/slashes/slash_frames.tres", "", ResourceLoader.CACHE_MODE_REPLACE) as SpriteFrames
		if sf:
			se.sprite_frames = sf

	var is_air: bool = selected_animation.begins_with("air_")
	var indices := _get_matching_step_indices_for_animation(selected_animation)
	var step_idx: int = indices[0]
	var slash_anim: StringName = _weapon_data_resource.get_step_slash_animation(step_idx, is_air)
	if se.sprite_frames and not se.sprite_frames.has_animation(slash_anim):
		slash_anim = _weapon_data_resource.get_step_slash_animation(step_idx, false)
	if not se.sprite_frames or not se.sprite_frames.has_animation(slash_anim):
		se.visible = false
		return

	se.visible = true
	se.animation = slash_anim
	se.pause()
	var max_f: int = maxi(0, se.sprite_frames.get_frame_count(slash_anim) - 1)
	se.frame = clampi(current_frame, 0, max_f)
	se.modulate = _weapon_data_resource.slash_modulate
	se.z_index = _weapon_data_resource.slash_z_index
	_apply_slash_transform_to_node()

func _apply_slash_transform_to_node() -> void:
	var se := _get_node_safe("Visual/SlashEffect") as AnimatedSprite2D
	if not se:
		return
	var sprite := _get_node_safe("Visual/CharacterSprite") as AnimatedSprite2D
	var base_pos: Vector2 = sprite.position if sprite else Vector2(-2, -29)
	se.position = base_pos + Vector2(slash_offset_x, slash_offset_y)
	se.scale = slash_preview_scale
	se.flip_h = slash_preview_flip_h
	se.flip_v = slash_preview_flip_v

func _prompt_save_slash_to_set() -> void:
	_load_resources()
	if not (selected_animation in ATTACK_ANIMATIONS):
		status_message = "AVISO: Selecione uma animação de ataque (attack1..3, air_attack1..3) para salvar o Slash!"
		return
	if not _weapon_data_resource or not _weapon_data_resource.attack_set:
		status_message = "ERRO: A arma '%s' não possui um AttackSetData vinculado!" % selected_weapon
		return
	var set_res: AttackSetData = _weapon_data_resource.attack_set
	var set_path: String = set_res.resource_path
	var dlg := ConfirmationDialog.new()
	dlg.title = "Confirmar: Salvar Slash no Set"
	dlg.dialog_text = "Deseja salvar o Slash da animação '%s'\n(Offset: (%.1f, %.1f), Escala: %s, FlipH: %s, FlipV: %s)\ndiretamente no Set '%s'?" % [
		selected_animation, slash_offset_x, slash_offset_y, str(slash_preview_scale), str(slash_preview_flip_h), str(slash_preview_flip_v), set_path.get_file()
	]
	dlg.ok_button_text = "Sim, Salvar no Set"
	dlg.cancel_button_text = "Cancelar"
	dlg.confirmed.connect(func() -> void:
		_save_slash_to_set()
		dlg.queue_free()
	)
	dlg.canceled.connect(func() -> void:
		status_message = "Cancelado: Nenhuma alteração salva no Set."
		dlg.queue_free()
	)
	dlg.close_requested.connect(func() -> void: dlg.queue_free())
	var parent_node: Node = get_tree().root if get_tree() else self
	if Engine.is_editor_hint() and ClassDB.class_exists("EditorInterface"):
		var ed_base: Control = Engine.get_singleton("EditorInterface").get_base_control() if Engine.has_singleton("EditorInterface") else null
		if ed_base:
			parent_node = ed_base
	parent_node.add_child(dlg)
	dlg.popup_centered()

func _save_slash_to_set() -> void:
	_load_resources()
	if not _weapon_data_resource or not _weapon_data_resource.attack_set:
		return
	var set_res: AttackSetData = _weapon_data_resource.attack_set
	var is_air: bool = selected_animation.begins_with("air_")
	var indices := _get_matching_step_indices_for_animation(selected_animation)
	var target_total := Vector2(slash_offset_x, slash_offset_y)
	var weapon_modified: bool = false

	for idx in indices:
		if idx < 0 or idx >= set_res.steps.size():
			continue
		var st: ComboStepData = set_res.steps[idx]
		if not st:
			continue
		var w_step_off: Vector2 = _weapon_data_resource.slash_step_offsets[idx] if idx < _weapon_data_resource.slash_step_offsets.size() else Vector2.ZERO
		var frame_off: Vector2 = target_total - _weapon_data_resource.slash_offset - w_step_off

		var w_step_sc: Vector2 = Vector2.ONE
		if idx < _weapon_data_resource.slash_step_scales.size() and _weapon_data_resource.slash_step_scales[idx] != Vector2.ZERO:
			w_step_sc = _weapon_data_resource.slash_step_scales[idx]
		var base_w_sc: Vector2 = _weapon_data_resource.slash_scale * w_step_sc
		var frame_sc := Vector2(
			slash_preview_scale.x / (base_w_sc.x if not is_zero_approx(base_w_sc.x) else 1.0),
			slash_preview_scale.y / (base_w_sc.y if not is_zero_approx(base_w_sc.y) else 1.0)
		)

		if is_air:
			st.step_frame_air_slash_offsets[current_frame] = frame_off
			st.step_frame_air_slash_scales[current_frame] = frame_sc
		else:
			st.step_frame_slash_offsets[current_frame] = frame_off
			st.step_frame_slash_scales[current_frame] = frame_sc
		st.step_slash_flip_h = slash_preview_flip_h
		st.step_slash_flip_v = slash_preview_flip_v

		var fkey: String = WeaponData.make_slash_frame_key(idx, is_air, current_frame)
		if _weapon_data_resource.slash_frame_offsets.has(fkey):
			_weapon_data_resource.slash_frame_offsets.erase(fkey)
			weapon_modified = true
		if _weapon_data_resource.slash_frame_scales.has(fkey):
			_weapon_data_resource.slash_frame_scales.erase(fkey)
			weapon_modified = true

	var err := ResourceSaver.save(set_res, set_res.resource_path)
	if weapon_modified:
		ResourceSaver.save(_weapon_data_resource, _weapon_data_resource.resource_path)
	if err == OK:
		status_message = "SUCESSO! Slash salvo no Set '%s' para '%s' Frame %d -> Offset: (%.1f, %.1f), Escala: %s" % [
			set_res.resource_path.get_file(), selected_animation, current_frame, slash_offset_x, slash_offset_y, str(slash_preview_scale)
		]
		print(status_message)
		_sync_slash_from_weapon_data()
		_on_frame_changed()
	else:
		status_message = "ERRO ao salvar Set: código %d" % err

func _prompt_save_slash_to_weapon() -> void:
	_load_resources()
	if not (selected_animation in ATTACK_ANIMATIONS):
		status_message = "AVISO: Selecione uma animação de ataque (attack1..3, air_attack1..3) para salvar o Slash!"
		return
	if not _weapon_data_resource:
		status_message = "ERRO: WeaponData para '%s' não encontrado!" % selected_weapon
		return
	var w_path: String = _weapon_data_resource.resource_path
	var dlg := ConfirmationDialog.new()
	dlg.title = "Confirmar: Salvar Ajuste Individual na Arma"
	dlg.dialog_text = "Deseja salvar o ajuste de Slash da animação '%s'\n(Posição Final na Tela: (%.1f, %.1f), Escala: %s)\nindividualmente na arma '%s' (sem alterar o Set base)?" % [
		selected_animation, slash_offset_x, slash_offset_y, str(slash_preview_scale), w_path.get_file()
	]
	dlg.ok_button_text = "Sim, Salvar na Arma"
	dlg.cancel_button_text = "Cancelar"
	dlg.confirmed.connect(func() -> void:
		_save_slash_to_weapon()
		dlg.queue_free()
	)
	dlg.canceled.connect(func() -> void:
		status_message = "Cancelado: Nenhuma alteração salva na Arma."
		dlg.queue_free()
	)
	dlg.close_requested.connect(func() -> void: dlg.queue_free())
	var parent_node: Node = get_tree().root if get_tree() else self
	if Engine.is_editor_hint() and ClassDB.class_exists("EditorInterface"):
		var ed_base: Control = Engine.get_singleton("EditorInterface").get_base_control() if Engine.has_singleton("EditorInterface") else null
		if ed_base:
			parent_node = ed_base
	parent_node.add_child(dlg)
	dlg.popup_centered()

func _save_slash_to_weapon() -> void:
	_load_resources()
	if not _weapon_data_resource:
		return
	var is_air: bool = selected_animation.begins_with("air_")
	var indices := _get_matching_step_indices_for_animation(selected_animation)
	var target_total := Vector2(slash_offset_x, slash_offset_y)
	var step_count: int = _weapon_data_resource.get_combo_step_count()

	while _weapon_data_resource.slash_step_offsets.size() < step_count:
		_weapon_data_resource.slash_step_offsets.append(Vector2.ZERO)
	while _weapon_data_resource.slash_step_scales.size() < step_count:
		_weapon_data_resource.slash_step_scales.append(Vector2.ONE)

	for idx in indices:
		if idx < 0 or idx >= step_count:
			continue
		var set_off := Vector2.ZERO
		var set_sc := Vector2.ONE
		if _weapon_data_resource.attack_set and idx < _weapon_data_resource.attack_set.steps.size():
			var st: ComboStepData = _weapon_data_resource.attack_set.steps[idx]
			if st:
				set_off = st.get_frame_slash_offset(current_frame, is_air)
				set_sc = st.get_frame_slash_scale(current_frame, is_air)
		var w_step_off: Vector2 = _weapon_data_resource.slash_step_offsets[idx] if idx < _weapon_data_resource.slash_step_offsets.size() else Vector2.ZERO
		var w_step_sc: Vector2 = Vector2.ONE
		if idx < _weapon_data_resource.slash_step_scales.size() and _weapon_data_resource.slash_step_scales[idx] != Vector2.ZERO:
			w_step_sc = _weapon_data_resource.slash_step_scales[idx]
		var fkey: String = WeaponData.make_slash_frame_key(idx, is_air, current_frame)
		_weapon_data_resource.slash_frame_offsets[fkey] = target_total - set_off - _weapon_data_resource.slash_offset - w_step_off
		var base_sc := set_sc * _weapon_data_resource.slash_scale * w_step_sc
		_weapon_data_resource.slash_frame_scales[fkey] = Vector2(
			slash_preview_scale.x / (base_sc.x if not is_zero_approx(base_sc.x) else 1.0),
			slash_preview_scale.y / (base_sc.y if not is_zero_approx(base_sc.y) else 1.0)
		)

	var err := ResourceSaver.save(_weapon_data_resource, _weapon_data_resource.resource_path)
	if err == OK:
		status_message = "SUCESSO! Ajuste individual de Slash salvo em '%s' para '%s' Frame %d -> Final: (%.1f, %.1f)" % [
			_weapon_data_resource.resource_path.get_file(), selected_animation, current_frame, slash_offset_x, slash_offset_y
		]
		print(status_message)
		_sync_slash_from_weapon_data()
		_on_frame_changed()
	else:
		status_message = "ERRO ao salvar Arma: código %d" % err

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		var active_marker := _get_active_marker()
		if active_marker:
			if not is_equal_approx(active_marker.position.x, socket_pos_x):
				socket_pos_x = active_marker.position.x
			if not is_equal_approx(active_marker.position.y, socket_pos_y):
				socket_pos_y = active_marker.position.y
			if not is_equal_approx(active_marker.rotation_degrees, socket_rotation):
				socket_rotation = active_marker.rotation_degrees
			if active_marker.z_index != socket_z_index:
				socket_z_index = active_marker.z_index
		var se := _get_node_safe("Visual/SlashEffect") as AnimatedSprite2D
		if se and se.visible and (selected_animation in ATTACK_ANIMATIONS):
			var sprite := _get_node_safe("Visual/CharacterSprite") as AnimatedSprite2D
			var base_pos: Vector2 = sprite.position if sprite else Vector2(-2, -29)
			var cur_off: Vector2 = se.position - base_pos
			if not is_equal_approx(cur_off.x, slash_offset_x):
				_is_syncing_slash = true
				slash_offset_x = snappedf(cur_off.x, 0.1)
				_is_syncing_slash = false
			if not is_equal_approx(cur_off.y, slash_offset_y):
				_is_syncing_slash = true
				slash_offset_y = snappedf(cur_off.y, 0.1)
				_is_syncing_slash = false

func save_current_frame_data() -> void:
	_load_resources()

	if socket_target == "Arma na Mão (MainHandSocket)":
		if not _weapon_profile_resource:
			status_message = "ERRO: Perfil %s.tres não encontrado!" % selected_weapon
			return
		_weapon_profile_resource.set("%s_%d_pos" % [selected_animation, current_frame], socket_position)
		_weapon_profile_resource.set("%s_%d_rot" % [selected_animation, current_frame], socket_rotation)
		_weapon_profile_resource.set("%s_%d_visible" % [selected_animation, current_frame], item_visible_in_frame)
		if _weapon_profile_resource.has_method("set_hand_custom_data"):
			_weapon_profile_resource.set_hand_custom_data(selected_animation, current_frame, socket_z_index, socket_flip_h, socket_flip_v, socket_position, socket_rotation, item_visible_in_frame)
		elif _weapon_profile_resource.has_method("set_hand_z_index"):
			_weapon_profile_resource.set_hand_z_index(selected_animation, current_frame, socket_z_index)
		var err := ResourceSaver.save(_weapon_profile_resource, "res://src/entities/equipment/socket_profiles/%s.tres" % selected_weapon)
		_report_save_status(err, "%s.tres (Arma na Mão)" % selected_weapon)

	elif socket_target == "Arma nas Costas (BackSocketWeapon)":
		if not _weapon_profile_resource:
			status_message = "ERRO: Perfil %s.tres não encontrado!" % selected_weapon
			return
		_weapon_profile_resource.set_back_frame_data(selected_animation, current_frame, socket_position, socket_rotation, item_visible_in_frame, socket_z_index, socket_flip_h, socket_flip_v)
		var err := ResourceSaver.save(_weapon_profile_resource, "res://src/entities/equipment/socket_profiles/%s.tres" % selected_weapon)
		_report_save_status(err, "%s.tres (Arma nas Costas)" % selected_weapon)

	elif socket_target == "Escudo na Mão (OffHandSocket)":
		if not _shield_profile_resource:
			status_message = "ERRO: Perfil %s.tres não encontrado!" % selected_shield
			return
		_shield_profile_resource.set("%s_%d_pos" % [selected_animation, current_frame], socket_position)
		_shield_profile_resource.set("%s_%d_rot" % [selected_animation, current_frame], socket_rotation)
		_shield_profile_resource.set("%s_%d_visible" % [selected_animation, current_frame], item_visible_in_frame)
		if _shield_profile_resource.has_method("set_hand_custom_data"):
			_shield_profile_resource.set_hand_custom_data(selected_animation, current_frame, socket_z_index, socket_flip_h, socket_flip_v, socket_position, socket_rotation, item_visible_in_frame)
		elif _shield_profile_resource.has_method("set_hand_z_index"):
			_shield_profile_resource.set_hand_z_index(selected_animation, current_frame, socket_z_index)
		var err := ResourceSaver.save(_shield_profile_resource, "res://src/entities/equipment/socket_profiles/%s.tres" % selected_shield)
		_report_save_status(err, "%s.tres (Escudo na Mão)" % selected_shield)

	elif socket_target == "Escudo nas Costas (BackSocketShield)":
		if not _shield_profile_resource:
			status_message = "ERRO: Perfil %s.tres não encontrado!" % selected_shield
			return
		_shield_profile_resource.set_back_frame_data(selected_animation, current_frame, socket_position, socket_rotation, item_visible_in_frame, socket_z_index, socket_flip_h, socket_flip_v)
		var err := ResourceSaver.save(_shield_profile_resource, "res://src/entities/equipment/socket_profiles/%s.tres" % selected_shield)
		_report_save_status(err, "%s.tres (Escudo nas Costas)" % selected_shield)

func _prompt_apply_to_current_animation() -> void:
	var item_name: String = selected_weapon if "Arma" in socket_target else selected_shield
	var count: int = ANIMATION_FRAME_COUNTS.get(selected_animation, 4)
	var dlg := ConfirmationDialog.new()
	dlg.title = "Confirmar: Apply to Current Animation"
	dlg.dialog_text = "Tem certeza que deseja sobrescrever TODOS os %d frames da animação '%s'\nno perfil '%s.tres' (%s) com os dados do Frame %d atual?" % [
		count, selected_animation, item_name, socket_target, current_frame
	]
	dlg.ok_button_text = "Sim, Aplicar em Todos"
	dlg.cancel_button_text = "Cancelar"
	dlg.confirmed.connect(func() -> void:
		apply_to_current_animation()
		dlg.queue_free()
	)
	dlg.canceled.connect(func() -> void:
		status_message = "Cancelado: Nenhuma alteração aplicada à animação '%s'." % selected_animation
		dlg.queue_free()
	)
	dlg.close_requested.connect(func() -> void:
		dlg.queue_free()
	)
	var parent_node: Node = get_tree().root if get_tree() else self
	if Engine.is_editor_hint() and ClassDB.class_exists("EditorInterface"):
		var ed_base: Control = Engine.get_singleton("EditorInterface").get_base_control() if Engine.has_singleton("EditorInterface") else null
		if ed_base:
			parent_node = ed_base
	parent_node.add_child(dlg)
	dlg.popup_centered()

func apply_to_current_animation() -> void:
	_load_resources()
	var prof: WeaponSocketProfile = _weapon_profile_resource if "Arma" in socket_target else _shield_profile_resource
	var item_name: String = selected_weapon if "Arma" in socket_target else selected_shield
	if not prof:
		status_message = "ERRO: Perfil %s não encontrado!" % item_name
		return

	var count: int = ANIMATION_FRAME_COUNTS.get(selected_animation, 4)

	if socket_target == "Arma na Mão (MainHandSocket)" or socket_target == "Escudo na Mão (OffHandSocket)":
		for f in range(count):
			prof.set("%s_%d_pos" % [selected_animation, f], socket_position)
			prof.set("%s_%d_rot" % [selected_animation, f], socket_rotation)
			prof.set("%s_%d_visible" % [selected_animation, f], item_visible_in_frame)
			if prof.has_method("set_hand_custom_data"):
				prof.set_hand_custom_data(selected_animation, f, socket_z_index, socket_flip_h, socket_flip_v, socket_position, socket_rotation, item_visible_in_frame)
			elif prof.has_method("set_hand_z_index"):
				prof.set_hand_z_index(selected_animation, f, socket_z_index)
	else:
		for f in range(count):
			prof.set_back_frame_data(selected_animation, f, socket_position, socket_rotation, item_visible_in_frame, socket_z_index, socket_flip_h, socket_flip_v)

	var path := "res://src/entities/equipment/socket_profiles/%s.tres" % item_name
	var err := ResourceSaver.save(prof, path)
	if err == OK:
		status_message = "SUCESSO: Posição %s, Rot %.1f°, Z %d aplicados aos %d frames de '%s' em %s!" % [
			str(socket_position), socket_rotation, socket_z_index, count, selected_animation, item_name
		]
		print(status_message)
		_sync_slash_from_weapon_data()
		_on_frame_changed()
	else:
		status_message = "ERRO ao salvar na animação: Código %d" % err

func _report_save_status(err: Error, label: String) -> void:
	if err == OK:
		status_message = "SUCESSO! Salvo em %s -> [%s Frame %d] (Pos: %v, Rot: %.1f°, Z: %d, FlipH: %s, FlipV: %s)" % [
			label, selected_animation, current_frame, socket_position, socket_rotation, socket_z_index, str(socket_flip_h), str(socket_flip_v)
		]
		print(status_message)
	else:
		status_message = "ERRO ao salvar %s: código %d" % [label, err]
