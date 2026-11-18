class_name FamilyHouse
extends Node2D

## Hub do Jogo: A Cabana Rústica Medieval da Família
## Santuário temporal protegido da anomalia. O guerreiro desperta aqui após a morte.

const NpcBark = preload("res://src/ui/hub/npc_bark.gd")
const MotherDialogUI = preload("res://src/ui/hub/mother_dialog_ui.gd")
const BrotherForgeUI = preload("res://src/ui/hub/brother_forge_ui.gd")
const TouchOfDeathUI = preload("res://src/ui/hub/touch_of_death_ui.gd")

@export_group("Pedestal Draft Pool")
## Pool de armas corpo a corpo (Melee) elegíveis para sorteio nos pedestais da cabana.
@export var melee_weapon_pool: Array[WeaponData] = [
	preload("res://src/entities/equipment/swords/weapon_sword_base.tres"),
	preload("res://src/entities/equipment/daggers/weapon_dagger_base.tres"),
	preload("res://src/entities/equipment/axes/weapon_axe_base.tres"),
	preload("res://src/entities/equipment/hammers/weapon_hammer_base.tres")
]
## Pool de armas de alcance (Ranged / Magia) elegíveis para sorteio nos pedestais da cabana.
@export var ranged_weapon_pool: Array[WeaponData] = [
	preload("res://src/entities/equipment/bows/weapon_bow_base.tres"),
	preload("res://src/entities/equipment/crossbows/weapon_crossbow_base.tres"),
	preload("res://src/entities/equipment/staffs/weapon_staff_base.tres")
]
## Pool de escudos elegíveis para sorteio nos pedestais de defesa da cabana.
@export var shield_pool: Array[ShieldData] = [
	preload("res://src/entities/equipment/shields/shield_buckler_base.tres")
]

@onready var player: Player = $Player
@onready var dog_pet: Node2D = $Pets/DogPreta
@onready var cat_pet: Node2D = $Pets/CatBela
@onready var pet_spots: Node2D = $PetSpots
@onready var exit_portal_area: Area2D = $ExitPortalArea
@onready var fade_rect: ColorRect = $FadeCanvas/FadeRect
@onready var pedestals_container: Node2D = get_node_or_null("Props/Pedestals") as Node2D

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
var _player_near_mother: bool = false
var _player_near_brother: bool = false
var _player_near_death: bool = false
var _vortex_time: float = 0.0
var _dialogue_sequence_token: int = 0

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
		player.clear_all_equipment()

		var cam: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
		if cam:
			cam.limit_left = 0
			cam.limit_top = 0
			cam.limit_right = 1140
			cam.limit_bottom = 360
		ProgressionManager.apply_skin_to_player(player)

	_roll_pedestals_for_run(false)
	if not ProgressionManager.metrics_updated.is_connected(_on_progression_metrics_updated):
		ProgressionManager.metrics_updated.connect(_on_progression_metrics_updated)

	_setup_npc_interactions()
	_setup_portal_and_uis()

func _process(delta: float) -> void:
	# Condensação suave do Espectro da Morte conforme o jogador se aproxima do portal
	if death_specter and player and not _is_transitioning:
		var px: float = player.global_position.x
		if px < 920.0:
			death_specter.modulate.a = move_toward(death_specter.modulate.a, 0.0, delta * 2.0)
		else:
			var target_alpha: float = clampf((px - 920.0) / 90.0, 0.0, 1.0)
			death_specter.modulate.a = move_toward(death_specter.modulate.a, target_alpha, delta * 3.0)

	# Atualiza rotação do shader do vórtice caso ativo
	if _is_transitioning and death_vortex_portal and death_vortex_portal.visible:
		_vortex_time += delta
		var mat := death_vortex_portal.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter("vortex_time", _vortex_time)

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
		touch_of_death_ui.closed.connect(_on_death_ui_closed)

func _unhandled_input(event: InputEvent) -> void:
	if player and player.is_input_locked:
		return
	if event.is_action_pressed("interact"):
		if _player_near_mother:
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
	if player and player.is_input_locked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_mother_menu()

func _open_mother_menu() -> void:
	if mother_ui and not mother_ui.visible and not _is_transitioning:
		if player:
			player.is_input_locked = true
		mother_ui.open_ui()

func _on_mother_ui_closed(did_take_tea: bool = false) -> void:
	await get_tree().create_timer(0.08).timeout
	if player:
		player.is_input_locked = false
	if not player or not mother_bark:
		return
		
	if did_take_tea:
		var variation: int = randi() % 3
		var sequence: Array[Dictionary] = []
		match variation:
			0:
				sequence = [
					{"speaker": "player", "text": "BARK_TEA_CUTE_H1", "duration": 3.4, "delay": 2.8},
					{"speaker": "mother", "text": "BARK_TEA_CUTE_M1", "duration": 4.0, "delay": 3.5, "color": Color(1.0, 0.88, 0.7, 1.0)}
				]
			1:
				sequence = [
					{"speaker": "player", "text": "BARK_TEA_CUTE_H2", "duration": 3.4, "delay": 2.8},
					{"speaker": "mother", "text": "BARK_TEA_CUTE_M2", "duration": 4.0, "delay": 3.5, "color": Color(1.0, 0.88, 0.7, 1.0)}
				]
			2:
				sequence = [
					{"speaker": "mother", "text": "BARK_TEA_CUTE_M3_A", "duration": 3.0, "delay": 2.2, "color": Color(1.0, 0.88, 0.7, 1.0)},
					{"speaker": "player", "text": "BARK_TEA_CUTE_H3", "duration": 3.4, "delay": 2.8},
					{"speaker": "mother", "text": "BARK_TEA_CUTE_M3_B", "duration": 4.2, "delay": 3.8, "color": Color(1.0, 0.88, 0.7, 1.0)}
				]
		_play_dialogue_sequence(sequence)
	else:
		player.show_bark(tr("PROMPT_HERO_TO_MOTHER"), 3.0)
		var timer := get_tree().create_timer(1.8)
		timer.timeout.connect(func() -> void:
			if mother_bark and is_instance_valid(mother_bark):
				var random_line: String = tr(MOTHER_REFUSAL_BARKS.pick_random())
				mother_bark.show_bark(random_line, 5.0, Color(1.0, 0.88, 0.7, 1.0))
		)

# --- Interação com o Irmão ---
func _on_brother_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if player and player.is_input_locked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_brother_menu()

func _open_brother_menu() -> void:
	if brother_ui and not brother_ui.visible and not _is_transitioning:
		if player:
			player.is_input_locked = true
		brother_ui.open_ui()

func _on_brother_ui_closed(did_upgrade: bool = false) -> void:
	await get_tree().create_timer(0.08).timeout
	if player:
		player.is_input_locked = false
	if not player or not brother_bark:
		return
		
	if did_upgrade:
		var variation: int = randi() % 3
		var sequence: Array[Dictionary] = []
		match variation:
			0:
				sequence = [
					{"speaker": "player", "text": "BARK_FORGE_CUTE_H1", "duration": 3.6, "delay": 3.0},
					{"speaker": "brother", "text": "BARK_FORGE_CUTE_B1", "duration": 4.0, "delay": 3.5, "color": Color(0.85, 0.92, 1.0, 1.0)}
				]
			1:
				sequence = [
					{"speaker": "player", "text": "BARK_FORGE_CUTE_H2", "duration": 3.4, "delay": 2.8},
					{"speaker": "brother", "text": "BARK_FORGE_CUTE_B2", "duration": 4.0, "delay": 3.5, "color": Color(0.85, 0.92, 1.0, 1.0)}
				]
			2:
				sequence = [
					{"speaker": "player", "text": "BARK_FORGE_CUTE_H3_A", "duration": 3.5, "delay": 2.8},
					{"speaker": "brother", "text": "BARK_FORGE_CUTE_B3", "duration": 3.2, "delay": 2.4, "color": Color(0.85, 0.92, 1.0, 1.0)},
					{"speaker": "player", "text": "BARK_FORGE_CUTE_H3_B", "duration": 3.8, "delay": 3.2}
				]
		_play_dialogue_sequence(sequence)
	else:
		player.show_bark(tr("PROMPT_HERO_TO_BROTHER"), 3.0)
		var timer := get_tree().create_timer(1.8)
		timer.timeout.connect(func() -> void:
			if brother_bark and is_instance_valid(brother_bark):
				var random_line: String = tr(BROTHER_EXCUSE_BARKS.pick_random())
				brother_bark.show_bark(random_line, 5.0, Color(0.85, 0.92, 1.0, 1.0))
		)

func _play_dialogue_sequence(steps: Array[Dictionary]) -> void:
	_dialogue_sequence_token += 1
	var seq_id: int = _dialogue_sequence_token
	for step in steps:
		if seq_id != _dialogue_sequence_token:
			return
		var speaker: String = step.get("speaker", "player")
		var text: String = tr(step.get("text", ""))
		var duration: float = step.get("duration", 3.5)
		var delay_after: float = step.get("delay", 3.2)
		var color: Color = step.get("color", Color.WHITE)
		
		if speaker == "player":
			if player and is_instance_valid(player):
				player.show_bark(text, duration)
		elif speaker == "mother":
			if mother_bark and is_instance_valid(mother_bark):
				mother_bark.show_bark(text, duration, color)
		elif speaker == "brother":
			if brother_bark and is_instance_valid(brother_bark):
				brother_bark.show_bark(text, duration, color)
				
		await get_tree().create_timer(delay_after).timeout

# --- Sorteio Dinâmico dos Pedestais por Run ---
func _on_progression_metrics_updated() -> void:
	_roll_pedestals_for_run(true)

func _roll_pedestals_for_run(only_newly_unlocked: bool = false) -> void:
	if not pedestals_container:
		return

	var weapon_peds: Array[WeaponPedestal] = []
	var shield_peds: Array[WeaponPedestal] = []
	for child in pedestals_container.get_children():
		var ped := child as WeaponPedestal
		if not ped:
			continue
		if ped.is_shield_pedestal:
			shield_peds.append(ped)
		else:
			weapon_peds.append(ped)

	_roll_weapon_pedestals(weapon_peds, only_newly_unlocked)
	_roll_shield_pedestals(shield_peds, only_newly_unlocked)

func _roll_weapon_pedestals(weapon_peds: Array[WeaponPedestal], only_newly_unlocked: bool) -> void:
	var melees: Array[WeaponData] = _filtered_weapons(melee_weapon_pool)
	var rangeds: Array[WeaponData] = _filtered_weapons(ranged_weapon_pool)
	melees.shuffle()
	rangeds.shuffle()

	var all_weapons: Array[WeaponData] = []
	all_weapons.append_array(melees)
	all_weapons.append_array(rangeds)
	all_weapons.shuffle()
	if all_weapons.is_empty():
		return

	if not only_newly_unlocked:
		var unlocked_peds: Array[WeaponPedestal] = []
		for ped in weapon_peds:
			if ProgressionManager.is_weapon_pedestal_unlocked(ped.pedestal_index):
				unlocked_peds.append(ped)
			else:
				ped.set_equipment(null)

		if unlocked_peds.is_empty():
			return

		var chosen: Array[WeaponData] = []
		if unlocked_peds.size() == 1:
			chosen.append(all_weapons[0])
		else:
			if not melees.is_empty():
				chosen.append(melees.pop_back())
			if not rangeds.is_empty():
				chosen.append(rangeds.pop_back())
			var remaining: Array[WeaponData] = []
			remaining.append_array(melees)
			remaining.append_array(rangeds)
			remaining.shuffle()
			while chosen.size() < unlocked_peds.size() and not remaining.is_empty():
				chosen.append(remaining.pop_back())
			while chosen.size() < unlocked_peds.size():
				all_weapons.shuffle()
				chosen.append(all_weapons[0])
			chosen.shuffle()

		for i in range(unlocked_peds.size()):
			unlocked_peds[i].set_equipment(chosen[i].duplicate() as WeaponData)
		return

	# Preenchimento incremental quando novos pedestais são desbloqueados ao vivo (ex: menu F3)
	var unlocked_count: int = 0
	var to_fill: Array[WeaponPedestal] = []
	var used_names: Array[String] = []
	var has_melee: bool = false
	var has_ranged: bool = false

	for ped in weapon_peds:
		if not ProgressionManager.is_weapon_pedestal_unlocked(ped.pedestal_index):
			continue
		unlocked_count += 1
		var w := ped.equipment_data as WeaponData
		if w:
			used_names.append(w.equipment_name)
			if w.weapon_category == WeaponData.WeaponCategory.MELEE:
				has_melee = true
			else:
				has_ranged = true
		elif not ped.was_populated_this_run:
			to_fill.append(ped)

	if player:
		for equipped in [player.weapon, player.secondary_weapon]:
			var w := equipped as WeaponData
			if w:
				used_names.append(w.equipment_name)
				if w.weapon_category == WeaponData.WeaponCategory.MELEE:
					has_melee = true
				else:
					has_ranged = true

	if to_fill.is_empty():
		return

	to_fill.shuffle()
	for ped in to_fill:
		var picked: WeaponData = null
		if unlocked_count >= 2 and not has_melee and not melees.is_empty():
			picked = _pick_unique_weapon(melees, used_names)
			has_melee = true
		elif unlocked_count >= 2 and not has_ranged and not rangeds.is_empty():
			picked = _pick_unique_weapon(rangeds, used_names)
			has_ranged = true
		else:
			picked = _pick_unique_weapon(all_weapons, used_names)

		if picked:
			used_names.append(picked.equipment_name)
			ped.set_equipment(picked.duplicate() as WeaponData)

func _roll_shield_pedestals(shield_peds: Array[WeaponPedestal], only_newly_unlocked: bool) -> void:
	var shields: Array[ShieldData] = _filtered_shields(shield_pool)
	if shields.is_empty():
		return

	var pool_copy: Array[ShieldData] = shields.duplicate()
	pool_copy.shuffle()

	for ped in shield_peds:
		if not ProgressionManager.is_shield_pedestal_unlocked(ped.pedestal_index):
			if not only_newly_unlocked:
				ped.set_equipment(null)
			continue
		if only_newly_unlocked and ped.was_populated_this_run:
			continue
		if pool_copy.is_empty():
			pool_copy = shields.duplicate()
			pool_copy.shuffle()
		var chosen_shield: ShieldData = pool_copy.pop_back()
		ped.set_equipment(chosen_shield.duplicate() as ShieldData)

func _filtered_weapons(pool: Array[WeaponData]) -> Array[WeaponData]:
	var result: Array[WeaponData] = []
	for w in pool:
		if w:
			result.append(w)
	return result

func _filtered_shields(pool: Array[ShieldData]) -> Array[ShieldData]:
	var result: Array[ShieldData] = []
	for s in pool:
		if s:
			result.append(s)
	return result

func _pick_unique_weapon(candidates: Array[WeaponData], used_names: Array[String]) -> WeaponData:
	for candidate in candidates:
		if not used_names.has(candidate.equipment_name):
			return candidate
	return candidates[0] if not candidates.is_empty() else null

# --- Interação com a Morte & Sequência do Portal ---
func _on_exit_portal_entered(body: Node2D) -> void:
	if _is_transitioning or body != player or (player and player.is_input_locked):
		return
	_player_near_death = true
	_open_death_menu()

func _on_exit_portal_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if player and player.is_input_locked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_open_death_menu()

func _open_death_menu() -> void:
	if touch_of_death_ui and not touch_of_death_ui.visible and not _is_transitioning:
		if player:
			player.is_input_locked = true
		touch_of_death_ui.open_ui()

func _on_death_ui_closed() -> void:
	await get_tree().create_timer(0.08).timeout
	if player:
		player.is_input_locked = false

func _on_blessing_chosen_and_transition(_blessing_id: String) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if player:
		player.is_input_locked = true

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
		# Personagem caminha automaticamente em direção ao centro do vórtice (x = 1040)
		player.facing_direction = 1
		player.velocity.x = 80.0
		var walk_tween := create_tween()
		walk_tween.tween_property(player, "global_position:x", 1040.0, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
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
