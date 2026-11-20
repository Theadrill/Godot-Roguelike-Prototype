class_name PlayerEquipmentRig
extends RefCounted

## Sub-controlador modular de equipamentos, sockets frame-a-frame e drop na morte do Player.
## Mantém paridade matemática 1:1 com o WeaponSocketCalibrator (mesmos 6 sockets, âncoras, flips e Z-index).

const STANDARD_SPRITE_POS := Vector2(-2.0, -29.0)
const CORNER_CLIMB_SPRITE_POS := Vector2(-6.5, 4.0)
const DOUBLE_JUMP_ROTATION_PIVOT := Vector2(-1.0, -29.5)
const DOUBLE_JUMP_STEP_DEGREES := 90.0


static func apply_sprite_pose_transform(sprite: AnimatedSprite2D, anim_name: StringName) -> void:
	## Aplica a âncora padrão do aventureiro ou a âncora especial do corner_climb.
	if not sprite:
		return
	sprite.rotation = 0.0
	if anim_name == &"corner_climb":
		sprite.position = CORNER_CLIMB_SPRITE_POS
	else:
		sprite.position = STANDARD_SPRITE_POS


static func apply_double_jump_visual_rotation(visual_node: Node2D, frame_idx: int, facing_dir: int) -> void:
	## Rotaciona o nó Visual inteiro (sprite + todos os sockets equipados) em 4 passos (0°, 90°, 180°, 270°) ao redor do centro encolhido.
	if not visual_node:
		return
	var clamped_step: int = clampi(frame_idx, 0, 3)
	var sign_x: float = -1.0 if facing_dir < 0 else 1.0
	var rad: float = deg_to_rad(float(clamped_step) * DOUBLE_JUMP_STEP_DEGREES) * sign_x
	if is_zero_approx(rad):
		visual_node.rotation = 0.0
		visual_node.position = Vector2.ZERO
		return
	var scaled_pivot := Vector2(DOUBLE_JUMP_ROTATION_PIVOT.x * sign_x, DOUBLE_JUMP_ROTATION_PIVOT.y)
	visual_node.rotation = rad
	visual_node.position = scaled_pivot - scaled_pivot.rotated(rad)


static func reset_visual_transform(visual_node: Node2D) -> void:
	## Restaura rotação e posição originais do nó Visual sem alterar sua escala.
	if not visual_node:
		return
	visual_node.rotation = 0.0
	visual_node.position = Vector2.ZERO


var _player: CharacterBody2D = null
var _tea_bottle_profile: WeaponSocketProfile = null
var _item_pickup_profile: WeaponSocketProfile = null


func setup(player_ref: CharacterBody2D) -> void:
	_player = player_ref
	if ResourceLoader.exists("res://src/entities/equipment/socket_profiles/tea_bottle.tres"):
		_tea_bottle_profile = load("res://src/entities/equipment/socket_profiles/tea_bottle.tres") as WeaponSocketProfile
	if _player.tea_bottle_socket and ResourceLoader.exists("res://src/entities/equipment/items/tea_bottle_visual.tscn"):
		var tb_scene := load("res://src/entities/equipment/items/tea_bottle_visual.tscn") as PackedScene
		if tb_scene:
			_player.tea_bottle_instance = tb_scene.instantiate() as Node2D
			_player.tea_bottle_socket.add_child(_player.tea_bottle_instance)
			_player.tea_bottle_instance.position = Vector2.ZERO
			_player.tea_bottle_instance.rotation_degrees = 0.0
			_player.tea_bottle_instance.visible = false

	if ResourceLoader.exists("res://src/entities/equipment/socket_profiles/item_pickup.tres"):
		_item_pickup_profile = load("res://src/entities/equipment/socket_profiles/item_pickup.tres") as WeaponSocketProfile


func refresh_equipped_visuals() -> void:
	update_main_weapon_visual()
	update_secondary_weapon_visual()
	update_shield_visual()


func set_shield_raised(raised: bool) -> void:
	if _player.is_shield_raised == raised:
		return
	_player.is_shield_raised = raised
	if not _player.shield_instance or not is_instance_valid(_player.shield_instance):
		return

	var target_socket: Marker2D = _player.off_hand_socket if _player.is_shield_raised else _player.back_socket_shield
	if target_socket and _player.shield_instance.get_parent() != target_socket:
		_player.shield_instance.reparent(target_socket, false)
	_player.shield_instance.position = Vector2.ZERO
	_player.shield_instance.rotation_degrees = 0.0
	_player.shield_instance.z_index = 0
	if _player.player_sprite:
		update_sockets_for_frame(_player.player_sprite.animation, _player.player_sprite.frame)


func hide_equipment_visuals() -> void:
	_player.are_weapons_hidden = true
	if _player.main_weapon_instance and is_instance_valid(_player.main_weapon_instance):
		_player.main_weapon_instance.visible = false
	if _player.secondary_weapon_instance and is_instance_valid(_player.secondary_weapon_instance):
		_player.secondary_weapon_instance.visible = false
	if _player.shield_instance and is_instance_valid(_player.shield_instance):
		_player.shield_instance.visible = false


func clear_all_equipment() -> void:
	_player.weapon = null
	_player.secondary_weapon = null
	_player.shield = null
	if _player.main_weapon_instance and is_instance_valid(_player.main_weapon_instance):
		_player.main_weapon_instance.queue_free()
		_player.main_weapon_instance = null
	if _player.secondary_weapon_instance and is_instance_valid(_player.secondary_weapon_instance):
		_player.secondary_weapon_instance.queue_free()
		_player.secondary_weapon_instance = null
	if _player.shield_instance and is_instance_valid(_player.shield_instance):
		_player.shield_instance.queue_free()
		_player.shield_instance = null
	_player.are_weapons_hidden = true


func show_equipment_visuals() -> void:
	_player.are_weapons_hidden = false
	if _player.main_weapon_instance and is_instance_valid(_player.main_weapon_instance):
		_player.main_weapon_instance.visible = true
	else:
		update_main_weapon_visual()

	if _player.secondary_weapon_instance and is_instance_valid(_player.secondary_weapon_instance):
		_player.secondary_weapon_instance.visible = true
	else:
		update_secondary_weapon_visual()

	if _player.shield_instance and is_instance_valid(_player.shield_instance):
		_player.shield_instance.visible = true
	else:
		update_shield_visual()


func update_main_weapon_visual() -> void:
	if _player.main_weapon_instance and is_instance_valid(_player.main_weapon_instance):
		_player.main_weapon_instance.queue_free()
		_player.main_weapon_instance = null

	if _player.main_hand_socket:
		for child in _player.main_hand_socket.get_children():
			child.queue_free()

	if _player.weapon and _player.weapon.visual_scene and _player.main_hand_socket:
		_player.main_weapon_instance = _player.weapon.visual_scene.instantiate() as Node2D
		if _player.main_weapon_instance:
			_player.main_hand_socket.add_child(_player.main_weapon_instance)
			var has_socket_profile: bool = _player.weapon.get_socket_profile() != null
			_player.main_weapon_instance.position = Vector2.ZERO if has_socket_profile else _player.weapon.visual_offset
			_player.main_weapon_instance.rotation_degrees = 0.0 if has_socket_profile else _player.weapon.visual_rotation_degrees
			_player.main_weapon_instance.z_index = 0
			_player.main_weapon_instance.visible = not _player.are_weapons_hidden
			if _player.player_sprite and _player.player_sprite.visible:
				update_sockets_for_frame(_player.player_sprite.animation, _player.player_sprite.frame)


func update_secondary_weapon_visual() -> void:
	if _player.secondary_weapon_instance and is_instance_valid(_player.secondary_weapon_instance):
		_player.secondary_weapon_instance.queue_free()
		_player.secondary_weapon_instance = null

	if _player.secondary_weapon and _player.secondary_weapon.visual_scene and _player.back_socket_weapon:
		_player.secondary_weapon_instance = _player.secondary_weapon.visual_scene.instantiate() as Node2D
		if _player.secondary_weapon_instance:
			_player.back_socket_weapon.add_child(_player.secondary_weapon_instance)
			_player.secondary_weapon_instance.position = Vector2.ZERO
			_player.secondary_weapon_instance.rotation_degrees = 0.0
			_player.secondary_weapon_instance.z_index = 0
			_player.secondary_weapon_instance.visible = not _player.are_weapons_hidden


func update_shield_visual() -> void:
	if _player.shield_instance and is_instance_valid(_player.shield_instance):
		_player.shield_instance.queue_free()
		_player.shield_instance = null

	if _player.shield and _player.shield.visual_scene:
		_player.shield_instance = _player.shield.visual_scene.instantiate() as Node2D
		if _player.shield_instance:
			var target_socket: Marker2D = _player.off_hand_socket if _player.is_shield_raised else _player.back_socket_shield
			if target_socket:
				target_socket.add_child(_player.shield_instance)
			_player.shield_instance.position = Vector2.ZERO
			_player.shield_instance.rotation_degrees = 0.0
			_player.shield_instance.z_index = 0
			_player.shield_instance.visible = not _player.are_weapons_hidden


func apply_visual_instance_flip(instance: Node2D, flip_h: bool, flip_v: bool) -> void:
	if not instance or not is_instance_valid(instance):
		return
	var sx := absf(instance.scale.x)
	if sx < 0.001:
		sx = 0.8
	var sy := absf(instance.scale.y)
	if sy < 0.001:
		sy = 0.8
	instance.scale.x = -sx if flip_h else sx
	instance.scale.y = -sy if flip_v else sy


func update_sockets_for_frame(anim_name: StringName, frame_idx: int) -> void:
	if not _player.player_sprite or not _player.player_sprite.visible:
		return

	# 1. Main Hand Weapon (atualiza apenas se não estiver executando ataque ou defesa procedural)
	var is_in_manual_socket_state: bool = false
	if _player.state_machine and _player.state_machine.current_state:
		var current_state_name: String = _player.state_machine.current_state.name.to_lower()
		if current_state_name == "attack":
			is_in_manual_socket_state = not (anim_name in [&"attack1", &"attack2", &"attack3", &"air_attack1", &"air_attack2", &"air_attack3", &"air_attack"])
		elif current_state_name == "rangedattack":
			is_in_manual_socket_state = not (anim_name in [&"cast", &"channeling", &"bow_attack", &"bow_air_attack", &"crossbow_attack", &"crossbow_air_attack"])
		elif current_state_name == "guard":
			is_in_manual_socket_state = not (anim_name in [&"block", &"block_loop"])

	if not is_in_manual_socket_state and _player.main_hand_socket and _player.weapon:
		var profile: WeaponSocketProfile = _player.weapon.get_socket_profile()
		if profile:
			var data: Dictionary = profile.get_frame_data(anim_name, frame_idx)
			_player.main_hand_socket.position = data.get("pos", Vector2(6, -20))
			_player.main_hand_socket.rotation_degrees = data.get("rot", -35.0)
			var hand_z: int = data.get("z_index", 2)
			if anim_name == &"corner_climb" and hand_z < 1:
				hand_z = 2
			_player.main_hand_socket.z_index = hand_z
			if _player.main_weapon_instance and is_instance_valid(_player.main_weapon_instance):
				var should_be_visible: bool = data.get("visible", true)
				_player.main_weapon_instance.visible = should_be_visible and not _player.are_weapons_hidden
				apply_visual_instance_flip(_player.main_weapon_instance, data.get("flip_h", false), data.get("flip_v", false))

	# 2. Back Sockets (Arma e Escudo nas costas usam o perfil da arma ou fallback)
	if _player.secondary_weapon:
		var sec_profile: WeaponSocketProfile = _player.secondary_weapon.get_socket_profile()
		if sec_profile and sec_profile.has_method("get_back_frame_data"):
			var back_data: Dictionary = sec_profile.get_back_frame_data(anim_name, frame_idx)
			if _player.back_socket_weapon:
				_player.back_socket_weapon.position = back_data.get("pos", Vector2(-6, -24))
				_player.back_socket_weapon.rotation_degrees = back_data.get("rot", 0.0)
				var default_back_z: int = 1 if _player.secondary_weapon.get_archetype_id() == "dagger" else -2
				_player.back_socket_weapon.z_index = back_data.get("z_index", default_back_z)
			if _player.secondary_weapon_instance and is_instance_valid(_player.secondary_weapon_instance):
				_player.secondary_weapon_instance.position = Vector2.ZERO
				_player.secondary_weapon_instance.rotation_degrees = 0.0
				_player.secondary_weapon_instance.visible = back_data.get("visible", true) and not _player.are_weapons_hidden
				apply_visual_instance_flip(_player.secondary_weapon_instance, back_data.get("flip_h", false), back_data.get("flip_v", false))
	elif _player.back_socket_profile and _player.back_socket_weapon:
		var torso_pos: Vector2 = _player.back_socket_profile.get_frame_pos(anim_name, frame_idx)
		_player.back_socket_weapon.position = torso_pos
		_player.back_socket_weapon.rotation_degrees = 0.0
		_player.back_socket_weapon.z_index = -2

	# 3. Escudo (na Mão/Guarda ou nas Costas)
	if _player.shield:
		var sh_profile: WeaponSocketProfile = _player.shield.get_socket_profile()
		if sh_profile:
			if _player.is_shield_raised:
				if sh_profile.has_method("get_frame_data"):
					var hand_data := sh_profile.get_frame_data(anim_name, frame_idx)
					if _player.off_hand_socket:
						_player.off_hand_socket.position = hand_data.get("pos", Vector2(7, -19))
						_player.off_hand_socket.rotation_degrees = hand_data.get("rot", 0.0)
						_player.off_hand_socket.z_index = hand_data.get("z_index", 2)
					if _player.shield_instance and is_instance_valid(_player.shield_instance):
						_player.shield_instance.position = Vector2.ZERO
						_player.shield_instance.rotation_degrees = 0.0
						_player.shield_instance.visible = hand_data.get("visible", true) and not _player.are_weapons_hidden
						apply_visual_instance_flip(_player.shield_instance, hand_data.get("flip_h", false), hand_data.get("flip_v", false))
			else:
				if sh_profile.has_method("get_back_frame_data"):
					var back_data := sh_profile.get_back_frame_data(anim_name, frame_idx)
					if _player.back_socket_shield:
						_player.back_socket_shield.position = back_data.get("pos", Vector2(-9, -24))
						_player.back_socket_shield.rotation_degrees = back_data.get("rot", 0.0)
						_player.back_socket_shield.z_index = back_data.get("z_index", -3)
					if _player.shield_instance and is_instance_valid(_player.shield_instance):
						_player.shield_instance.position = Vector2.ZERO
						_player.shield_instance.rotation_degrees = 0.0
						_player.shield_instance.visible = back_data.get("visible", true) and not _player.are_weapons_hidden
						apply_visual_instance_flip(_player.shield_instance, back_data.get("flip_h", false), back_data.get("flip_v", false))
	elif _player.back_socket_shield:
		if _player.back_socket_weapon:
			_player.back_socket_shield.position = _player.back_socket_weapon.position + Vector2(-3.0, 0.0)
			_player.back_socket_shield.z_index = -3
		elif _player.back_socket_profile:
			_player.back_socket_shield.position = _player.back_socket_profile.get_frame_pos(anim_name, frame_idx) + Vector2(-3.0, 0.0)
			_player.back_socket_shield.z_index = -3

	# 4. Garrafa de Chá (exibida apenas durante a animação "heal")
	if _player.tea_bottle_instance and is_instance_valid(_player.tea_bottle_instance):
		if anim_name == &"heal" and _player.tea_bottle_socket:
			var tb_data: Dictionary = _tea_bottle_profile.get_frame_data(anim_name, frame_idx) if _tea_bottle_profile else {}
			_player.tea_bottle_socket.position = tb_data.get("pos", Vector2(10, -24))
			_player.tea_bottle_socket.rotation_degrees = tb_data.get("rot", 0.0)
			_player.tea_bottle_socket.z_index = tb_data.get("z_index", 3)
			_player.tea_bottle_instance.position = Vector2.ZERO
			_player.tea_bottle_instance.rotation_degrees = 0.0
			_player.tea_bottle_instance.visible = tb_data.get("visible", true) and not _player.are_weapons_hidden
			apply_visual_instance_flip(_player.tea_bottle_instance, tb_data.get("flip_h", false), tb_data.get("flip_v", false))
			var tb_sprite := _player.tea_bottle_instance.get_node_or_null("Sprite2D") as Sprite2D
			if tb_sprite:
				var tb_frame: int = _player.tea_bottle_frame_override if _player.tea_bottle_frame_override >= 0 else frame_idx
				tb_sprite.frame = clampi(tb_frame, 0, 2)
		else:
			_player.tea_bottle_instance.visible = false

	# 5. Item sendo Pego (exibido durante a animação "pickup" usando o visual do item coletado)
	if _player.item_pickup_instance and is_instance_valid(_player.item_pickup_instance):
		if anim_name == &"pickup" and _player.item_pickup_socket:
			var ip_data: Dictionary = _item_pickup_profile.get_frame_data(anim_name, frame_idx) if _item_pickup_profile else {}
			_player.item_pickup_socket.position = ip_data.get("pos", Vector2(13, -10))
			_player.item_pickup_socket.rotation_degrees = ip_data.get("rot", 0.0)
			_player.item_pickup_socket.z_index = ip_data.get("z_index", 3)
			_player.item_pickup_instance.position = Vector2.ZERO
			_player.item_pickup_instance.rotation_degrees = 0.0
			_player.item_pickup_instance.visible = ip_data.get("visible", frame_idx > 0) and not _player.are_weapons_hidden
			apply_visual_instance_flip(_player.item_pickup_instance, ip_data.get("flip_h", false), ip_data.get("flip_v", false))
		else:
			_player.item_pickup_instance.visible = false


func update_equipment_depth() -> void:
	if _player.player_sprite:
		update_sockets_for_frame(_player.player_sprite.animation, _player.player_sprite.frame)
	else:
		if _player.main_hand_socket:
			_player.main_hand_socket.z_index = 2
		if _player.off_hand_socket:
			_player.off_hand_socket.z_index = -1
		if _player.back_socket_shield:
			_player.back_socket_shield.z_index = -1
		if _player.back_socket_weapon:
			var default_back_z: int = 1 if (_player.secondary_weapon and _player.secondary_weapon.get_archetype_id() == "dagger") else -2
			_player.back_socket_weapon.z_index = default_back_z


func spawn_death_dropped_equipment() -> void:
	clear_death_dropped_equipment()
	var spawn_parent: Node = _player.get_tree().current_scene if (_player.get_tree() and _player.get_tree().current_scene) else _player.get_parent()
	if not spawn_parent:
		return

	var facing: float = -1.0 if _player.facing_direction < 0 else 1.0
	var pieces: Array[Dictionary] = [
		{
			"vis": _player.main_weapon_instance,
			"socket": _player.main_hand_socket,
			"impulse": Vector2(facing * 48.0, -78.0),
			"spin": facing * 5.2,
		},
		{
			"vis": _player.secondary_weapon_instance,
			"socket": _player.back_socket_weapon,
			"impulse": Vector2(-facing * 32.0, -64.0),
			"spin": -facing * 4.0,
		},
		{
			"vis": _player.shield_instance,
			"socket": _player.off_hand_socket if _player.is_shield_raised else _player.back_socket_shield,
			"impulse": Vector2(-facing * 16.0, -54.0),
			"spin": -facing * 3.0,
		},
	]

	var safe_origin: Vector2 = _player.global_position + Vector2(0.0, -18.0)
	for entry in pieces:
		var vis_node := entry.get("vis") as Node2D
		var sock := entry.get("socket") as Node2D
		if not vis_node or not is_instance_valid(vis_node) or not vis_node.visible:
			continue
		var rot: float = sock.global_rotation if (sock and is_instance_valid(sock)) else 0.0
		var dropped := DroppedEquipmentPiece.spawn_from_visual(
			vis_node,
			safe_origin,
			rot,
			entry.get("impulse", Vector2.ZERO),
			entry.get("spin", 0.0),
			spawn_parent
		)
		if dropped:
			_player.dropped_death_items.append(dropped)


func clear_death_dropped_equipment() -> void:
	for item in _player.dropped_death_items:
		if item and is_instance_valid(item):
			item.queue_free()
	_player.dropped_death_items.clear()
