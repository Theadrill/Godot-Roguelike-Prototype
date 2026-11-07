class_name FamilyHouse
extends Node2D

## Hub do Jogo: A Cabana Rústica Medieval da Família
## Santuário temporal protegido da anomalia. O guerreiro desperta aqui após a morte.

@onready var player: Player = $Player
@onready var dog_pet: Node2D = $Pets/DogDachshund
@onready var cat_pet: Node2D = $Pets/CatSiamese
@onready var pet_spots: Node2D = $PetSpots
@onready var exit_portal_area: Area2D = $ExitPortalArea
@onready var fade_rect: ColorRect = $FadeCanvas/FadeRect
@onready var chest_area: Area2D = get_node_or_null("ChestArea") as Area2D
@onready var rack_area: Area2D = get_node_or_null("RackArea") as Area2D

var _is_transitioning: bool = false
var _is_weapons_equipped: bool = false
var _player_near_chest: bool = false

func _ready() -> void:
	# Fade-in suave do despertar
	if fade_rect:
		fade_rect.visible = true
		fade_rect.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_property(fade_rect, "modulate:a", 0.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_callback(func() -> void: fade_rect.visible = false)

	# Posicionamento dinâmico dos pets entre cozinha e forja
	_randomize_pet_positions()

	# Oculta HUD de combate dentro da cabana para visão limpa e cinematográfica
	if player:
		var hud: CanvasLayer = player.get_node_or_null("HUD") as CanvasLayer
		if hud:
			hud.visible = false
		# Personagem acorda sem armas no refúgio familiar
		player.hide_equipment_visuals()

	# Configura câmera para os limites exatos da cabana (0 a 1100 px horizontais, 0 a 360 verticais)
	if player:
		var cam: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.limit_left = 0
			cam.limit_top = 0
			cam.limit_right = 1100
			cam.limit_bottom = 360

	if exit_portal_area:
		exit_portal_area.body_entered.connect(_on_exit_portal_entered)

	# Conecta interação nos baús e suportes de armas (clique ou botão de ação)
	_setup_chest_interactions()

func _setup_chest_interactions() -> void:
	if chest_area:
		chest_area.input_event.connect(_on_chest_input_event)
		chest_area.body_entered.connect(_on_chest_body_entered)
		chest_area.body_exited.connect(_on_chest_body_exited)
	if rack_area:
		rack_area.input_event.connect(_on_chest_input_event)
		rack_area.body_entered.connect(_on_chest_body_entered)
		rack_area.body_exited.connect(_on_chest_body_exited)

func _on_chest_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_toggle_weapons()

func _on_chest_body_entered(body: Node2D) -> void:
	if body == player or (body and body.is_in_group("player")):
		_player_near_chest = true

func _on_chest_body_exited(body: Node2D) -> void:
	if body == player or (body and body.is_in_group("player")):
		_player_near_chest = false

func _unhandled_input(event: InputEvent) -> void:
	if _player_near_chest:
		if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and event.keycode == KEY_E) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_X):
			get_viewport().set_input_as_handled()
			_toggle_weapons()

func _toggle_weapons() -> void:
	if not player:
		return
	_is_weapons_equipped = not _is_weapons_equipped
	if _is_weapons_equipped:
		player.show_equipment_visuals()
		player.show_bark("Armas equipadas!")
	else:
		player.hide_equipment_visuals()
		player.show_bark("Armas guardadas.")

## Sorteia dois lugares aconchegantes distintos a cada despertar para a Dachshund e a Gatinha
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

## Cruzar o arco de pedra ancestral leva o guerreiro para a run (por enquanto, o movement_gym)
func _on_exit_portal_entered(body: Node2D) -> void:
	if _is_transitioning or not (body is Player or body.is_in_group("player")):
		return

	_is_transitioning = true
	if fade_rect:
		fade_rect.visible = true
		fade_rect.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_property(fade_rect, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		await tween.finished

	get_tree().change_scene_to_file("res://src/world/movement_gym.tscn")
