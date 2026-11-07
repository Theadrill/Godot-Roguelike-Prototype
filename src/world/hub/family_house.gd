class_name FamilyHouse
extends Node2D

## Hub do Jogo: A Cabana Rústica Medieval da Família
## Santuário temporal protegido da anomalia. O guerreiro desperta aqui após a morte.

const NpcBark = preload("res://src/ui/hub/npc_bark.gd")
const MotherDialogUI = preload("res://src/ui/hub/mother_dialog_ui.gd")
const BrotherForgeUI = preload("res://src/ui/hub/brother_forge_ui.gd")
const TouchOfDeathUI = preload("res://src/ui/hub/touch_of_death_ui.gd")

@onready var player: Player = $Player
@onready var dog_pet: Node2D = $Pets/DogPreta
@onready var cat_pet: Node2D = $Pets/CatBela
@onready var pet_spots: Node2D = $PetSpots
@onready var exit_portal_area: Area2D = $ExitPortalArea
@onready var fade_rect: ColorRect = $FadeCanvas/FadeRect

@onready var chest_area: Area2D = get_node_or_null("ChestArea") as Area2D
@onready var rack_area: Area2D = get_node_or_null("RackArea") as Area2D

@onready var mother_area: Area2D = get_node_or_null("Props/Mother_Placeholder/MotherArea") as Area2D
@onready var mother_bark: NpcBark = get_node_or_null("Props/Mother_Placeholder/Bark") as NpcBark

@onready var brother_area: Area2D = get_node_or_null("Props/Brother_Placeholder/BrotherArea") as Area2D
@onready var brother_bark: NpcBark = get_node_or_null("Props/Brother_Placeholder/Bark") as NpcBark

@onready var death_specter: Node2D = get_node_or_null("Props/Death_Specter_Placeholder") as Node2D
@onready var death_bark: NpcBark = get_node_or_null("Props/Death_Specter_Placeholder/Bark") as NpcBark
@onready var death_vortex_portal: ColorRect = get_node_or_null("Props/Death_Vortex_Portal") as ColorRect

@onready var mother_ui: MotherDialogUI = get_node_or_null("MotherDialogUI") as MotherDialogUI
@onready var brother_ui: BrotherForgeUI = get_node_or_null("BrotherForgeUI") as BrotherForgeUI
@onready var touch_of_death_ui: TouchOfDeathUI = get_node_or_null("TouchOfDeathUI") as TouchOfDeathUI

var _is_transitioning: bool = false
var _player_near_chest: bool = false
var _player_near_mother: bool = false
var _player_near_brother: bool = false
var _player_near_death: bool = false
var _vortex_time: float = 0.0

const MOTHER_REFUSAL_BARKS: Array[String] = [
	"BARK_MOTHER_REFUSAL_1",
	"BARK_MOTHER_REFUSAL_2",
	"BARK_MOTHER_REFUSAL_3",
	"BARK_MOTHER_REFUSAL_4"
]

const BROTHER_EXCUSE_BARKS: Array[String] = [
	"BARK_BROTHER_EXCUSE_1",
	"BARK_BROTHER_EXCUSE_2",
	"BARK_BROTHER_EXCUSE_3",
	"BARK_BROTHER_EXCUSE_4"
]

const DEATH_SARCASTIC_BARKS: Array[String] = [
	"BARK_DEATH_SARCASTIC_1",
	"BARK_DEATH_SARCASTIC_2",
	"BARK_DEATH_SARCASTIC_3",
	"BARK_DEATH_SARCASTIC_4"
]

func _ready() -> void:
	# Fade-in suave do despertar
	if fade_rect:
		fade_rect.visible = true
		fade_rect.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_property(fade_rect, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func() -> void: fade_rect.visible = false)

	# A porta da morte inicia escura e o espectro invisível
	if death_vortex_portal:
		death_vortex_portal.visible = false
		if death_vortex_portal.material:
			(death_vortex_portal.material as ShaderMaterial).set_shader_parameter("progress", 0.0)

	if death_specter:
		death_specter.modulate.a = 0.0

	# Posicionamento dinâmico dos pets
	_randomize_pet_positions()

	# Configurações do guerreiro desarmado ao despertar
	if player:
		var hud: CanvasLayer = player.get_node_or_null("HUD") as CanvasLayer
		if hud:
			hud.visible = false
		ProgressionManager.are_weapons_equipped = false
		player.hide_equipment_visuals()

		var cam: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.limit_left = 0
			cam.limit_top = 0
			cam.limit_right = 1100
			cam.limit_bottom = 360

	_setup_chest_interactions()
	_setup_npc_interactions()
	_setup_portal_and_uis()

func _process(delta: float) -> void:
	# Condensação suave do Espectro da Morte conforme o jogador se aproxima do portal
	if death_specter and player and not _is_transitioning:
		var px: float = player.global_position.x
		if px < 860.0:
			death_specter.modulate.a = move_toward(death_specter.modulate.a, 0.0, delta * 2.0)
		else:
			var target_alpha: float = clampf((px - 860.0) / 110.0, 0.0, 1.0)
			death_specter.modulate.a = move_toward(death_specter.modulate.a, target_alpha, delta * 3.0)

	# Atualiza rotação do shader do vórtice caso ativo
	if _is_transitioning and death_vortex_portal and death_vortex_portal.visible:
		_vortex_time += delta
		var mat := death_vortex_portal.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("vortex_time", _vortex_time)

func _setup_chest_interactions() -> void:
	if chest_area:
		chest_area.input_event.connect(_on_chest_input_event)
		chest_area.body_entered.connect(func(b: Node2D) -> void: if b == player: _player_near_chest = true)
		chest_area.body_exited.connect(func(b: Node2D) -> void: if b == player: _player_near_chest = false)
	if rack_area:
		rack_area.input_event.connect(_on_chest_input_event)
		rack_area.body_entered.connect(func(b: Node2D) -> void: if b == player: _player_near_chest = true)
		rack_area.body_exited.connect(func(b: Node2D) -> void: if b == player: _player_near_chest = false)

func _setup_npc_interactions() -> void:
	if mother_area:
		mother_area.body_entered.connect(func(b: Node2D) -> void: if b == player: _player_near_mother = true)
		mother_area.body_exited.connect(func(b: Node2D) -> void: if b == player: _player_near_mother = false)
		mother_area.input_event.connect(_on_mother_input_event)

	if brother_area:
		brother_area.body_entered.connect(func(b: Node2D) -> void: if b == player: _player_near_brother = true)
		brother_area.body_exited.connect(func(b: Node2D) -> void: if b == player: _player_near_brother = false)
		brother_area.input_event.connect(_on_brother_input_event)

func _setup_portal_and_uis() -> void:
	if exit_portal_area:
		exit_portal_area.body_entered.connect(_on_exit_portal_entered)
		exit_portal_area.body_exited.connect(func(b: Node2D) -> void: if b == player: _player_near_death = false)
		exit_portal_area.input_event.connect(_on_exit_portal_input_event)

	if mother_ui:
		mother_ui.closed.connect(_on_mother_ui_closed)

	if brother_ui:
		brother_ui.closed.connect(_on_brother_ui_closed)

	if touch_of_death_ui:
		touch_of_death_ui.blessing_chosen.connect(_on_blessing_chosen_and_transition)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if _player_near_chest:
			get_viewport().set_input_as_handled()
			_toggle_weapons()
		elif _player_near_mother:
			get_viewport().set_input_as_handled()
			_open_mother_menu()
		elif _player_near_brother:
			get_viewport().set_input_as_handled()
			_open_brother_menu()
		elif _player_near_death and not _is_transitioning:
			get_viewport().set_input_as_handled()
			_open_death_menu()

# --- Interação com a Mãe ---
func _on_mother_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_mother_menu()

func _open_mother_menu() -> void:
	if mother_ui and not mother_ui.visible and not _is_transitioning:
		mother_ui.open_ui()

func _on_mother_ui_closed() -> void:
	# O diálogo diegético acontece exclusivamente ao fechar a janela
	if not player or not mother_bark:
		return
	player.show_bark(tr("PROMPT_HERO_TO_MOTHER"))
	var timer := get_tree().create_timer(1.4)
	timer.timeout.connect(func() -> void:
		if mother_bark and is_instance_valid(mother_bark):
			var random_line: String = tr(MOTHER_REFUSAL_BARKS.pick_random())
			mother_bark.show_bark(random_line, 5.0, Color(1.0, 0.88, 0.7, 1.0))
	)

# --- Interação com o Irmão ---
func _on_brother_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_brother_menu()

func _open_brother_menu() -> void:
	if brother_ui and not brother_ui.visible and not _is_transitioning:
		brother_ui.open_ui()

func _on_brother_ui_closed() -> void:
	# O diálogo diegético acontece exclusivamente ao fechar a janela
	if not player or not brother_bark:
		return
	player.show_bark(tr("PROMPT_HERO_TO_BROTHER"))
	var timer := get_tree().create_timer(1.4)
	timer.timeout.connect(func() -> void:
		if brother_bark and is_instance_valid(brother_bark):
			var random_line: String = tr(BROTHER_EXCUSE_BARKS.pick_random())
			brother_bark.show_bark(random_line, 5.0, Color(0.85, 0.92, 1.0, 1.0))
	)

# --- Interação com o Baú de Armas ---
func _on_chest_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_toggle_weapons()

func _toggle_weapons() -> void:
	if not player:
		return
	ProgressionManager.are_weapons_equipped = not ProgressionManager.are_weapons_equipped
	if ProgressionManager.are_weapons_equipped:
		if not player.weapon:
			player.weapon = load("res://src/entities/equipment/swords/weapon_sword_base.tres") as WeaponData
		if not player.secondary_weapon:
			player.secondary_weapon = load("res://src/entities/equipment/bows/weapon_bow_base.tres") as WeaponData
		if not player.shield:
			player.shield = load("res://src/entities/equipment/shields/shield_buckler_base.tres") as ShieldData

		player.show_equipment_visuals()
		player.show_bark(tr("MSG_EQUIPPED_BASIC"))
	else:
		player.hide_equipment_visuals()
		player.show_bark(tr("MSG_STASHED_WEAPONS"))

# --- Interação com a Morte & Sequência do Portal ---
func _on_exit_portal_entered(body: Node2D) -> void:
	if _is_transitioning or body != player:
		return
	_player_near_death = true
	_open_death_menu()

func _on_exit_portal_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_death_menu()

func _open_death_menu() -> void:
	if touch_of_death_ui and not touch_of_death_ui.visible and not _is_transitioning:
		touch_of_death_ui.open_ui()

func _on_blessing_chosen_and_transition(_blessing_id: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true

	# 1. Ativa o vórtice na porta escura e anima o preenchimento da espiral esmeralda
	if death_vortex_portal:
		death_vortex_portal.visible = true
		var mat := death_vortex_portal.material as ShaderMaterial
		if mat:
			var portal_tween := create_tween()
			portal_tween.tween_method(func(val: float) -> void:
				mat.set_shader_parameter("progress", val)
			, 0.0, 1.0, 2.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Tremor bem suave na câmera durante o surgimento do vórtice
	var cam: GameCamera = player.get_node_or_null("Camera2D") as GameCamera
	if cam:
		cam.add_trauma(0.4)
		var shake_timer := get_tree().create_timer(1.2)
		shake_timer.timeout.connect(func() -> void:
			if cam:
				cam.add_trauma(0.35)
		)

	# 3. Diálogo entre o guerreiro e a Morte enquanto o vórtice se expande
	if player and death_bark:
		player.show_bark(tr("PROMPT_HERO_TO_DEATH"))
		var bark_timer := get_tree().create_timer(1.4)
		bark_timer.timeout.connect(func() -> void:
			if death_bark and is_instance_valid(death_bark):
				var random_sarcasm: String = tr(DEATH_SARCASTIC_BARKS.pick_random())
				death_bark.show_bark(random_sarcasm, 5.5, Color(0.42, 0.85, 0.7, 1.0))
		)

	# 4. Aguarda a leitura do diálogo e o jogador entra automaticamente no vórtice
	await get_tree().create_timer(4.8).timeout

	if player:
		# Personagem caminha automaticamente em direção ao centro do vórtice (x = 1020)
		player.facing_direction = 1
		player.velocity.x = 80.0
		var walk_tween := create_tween()
		walk_tween.tween_property(player, "global_position:x", 1020.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		walk_tween.parallel().tween_property(player, "modulate:a", 0.0, 1.4)

	# 5. Dissolução do espectro de volta na névoa
	if death_specter:
		var death_tween := create_tween()
		death_tween.tween_property(death_specter, "modulate:a", 0.0, 1.0)

	# 6. Aplica modificadores ativos da partida e transita para o bioma
	if player:
		ProgressionManager.apply_to_player(player)

	await get_tree().create_timer(1.0).timeout

	if fade_rect:
		fade_rect.visible = true
		fade_rect.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tween.finished

	get_tree().change_scene_to_file("res://src/world/movement_gym.tscn")

func _randomize_pet_positions() -> void:
	if not pet_spots or pet_spots.get_child_count() < 2:
		return

	var spots: Array[Node] = pet_spots.get_children().duplicate()
	spots.shuffle()

	if dog_pet and spots.size() > 0:
		var dog_marker := spots[0] as Marker2D
		if dog_marker:
			dog_pet.global_position = dog_marker.global_position

	if cat_pet and spots.size() > 1:
		var cat_marker := spots[1] as Marker2D
		if cat_marker:
			cat_pet.global_position = cat_marker.global_position
