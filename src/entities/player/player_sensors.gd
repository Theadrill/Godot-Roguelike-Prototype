class_name PlayerSensors
extends RefCounted

## Sub-controlador modular de sensores espaciais e filtros direcionais de intenção do Player.
## Encapsula detecção de beirada (Dead Cells mantle), colisão suave contra inimigos e deadzone de analógico.

var _player: CharacterBody2D = null


func setup(player_ref: CharacterBody2D) -> void:
	_player = player_ref


## Retorna true se o jogador estiver pressionando ativamente na direção de um inimigo sobreposto.
func is_pushing_against_enemy(move_direction: float) -> bool:
	var overlap_detector: Area2D = _player.enemy_overlap_detector
	if not overlap_detector or move_direction == 0.0:
		return false
	for body in overlap_detector.get_overlapping_bodies():
		if body is CharacterBody2D and body != _player:
			var dx: float = body.global_position.x - _player.global_position.x
			if move_direction > 0.0 and dx > -8.0:
				return true
			elif move_direction < 0.0 and dx < 8.0:
				return true
	return false


## Retorna true quando o jogador pressiona Baixo com intenção dominante (filtra inclinação diagonal acidental).
func is_crouch_requested() -> bool:
	return _is_vertical_intent_requested(&"down", [KEY_S, KEY_DOWN], 1.0)


## Retorna true quando o jogador mira para Cima com intenção dominante (filtra inclinação diagonal acidental).
func is_upward_attack_requested() -> bool:
	return _is_vertical_intent_requested(&"up", [KEY_W, KEY_UP], -1.0)


## Retorna true quando Baixo + Pulo é pressionado para iniciar Ground Slam aéreo.
func is_ground_slam_requested() -> bool:
	var down_held: bool = Input.is_action_pressed("down") or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.get_joy_axis(0, JOY_AXIS_LEFT_Y) > 0.4
	return down_held and Input.is_action_just_pressed("jump")


## Detecção de beirada em 4 estágios (Dead Cells mantle check).
## Atualiza player.ledge_target_position quando há plataforma escalável com teto livre.
func check_ledge() -> bool:
	if is_crouch_requested():
		return false

	var space := _player.get_world_2d().direct_space_state
	if not space:
		return false

	var face: float = float(_player.facing_direction)
	var ray_dist: float = 18.0
	var player_pos: Vector2 = _player.global_position
	var exclude_rids: Array[RID] = [_player.get_rid()]

	# 1. Contato lateral: testa pés (-1px), joelho (-12px) e peito (-24px).
	var wall_hit: Dictionary = {}
	for y_offset in [-1.0, -12.0, -24.0]:
		var wall_query := PhysicsRayQueryParameters2D.create(
			player_pos + Vector2(0.0, y_offset),
			player_pos + Vector2(face * ray_dist, y_offset),
			1
		)
		wall_query.exclude = exclude_rids
		wall_hit = space.intersect_ray(wall_query)
		if not wall_hit.is_empty():
			break

	if wall_hit.is_empty():
		return false

	var wall_x: float = wall_hit.position.x

	# 2. Folga superior: área da cabeça precisa estar livre acima da quina.
	var head_from := player_pos + Vector2(0.0, -42.0)
	var head_to := head_from + Vector2(face * (ray_dist + 4.0), 0.0)
	var head_query := PhysicsRayQueryParameters2D.create(head_from, head_to, 1)
	head_query.exclude = exclude_rids
	if not space.intersect_ray(head_query).is_empty():
		return false

	# 3. Superfície de apoio: procura o topo caminhável da plataforma.
	var floor_from := Vector2(wall_x + (face * 6.0), player_pos.y - 50.0)
	var floor_to := Vector2(wall_x + (face * 6.0), player_pos.y + 6.0)
	var floor_query := PhysicsRayQueryParameters2D.create(floor_from, floor_to, 1)
	floor_query.exclude = exclude_rids
	var floor_hit := space.intersect_ray(floor_query)
	if floor_hit.is_empty() or floor_hit.normal.y > -0.7:
		return false

	var floor_y: float = floor_hit.position.y

	# 4. Altura livre de pouso: verifica se cabem 40px em pé sobre a plataforma.
	var target_x: float = wall_x + (face * 10.0)
	var ceiling_query := PhysicsRayQueryParameters2D.create(
		Vector2(target_x, floor_y - 2.0),
		Vector2(target_x, floor_y - 42.0),
		1
	)
	ceiling_query.exclude = exclude_rids
	if not space.intersect_ray(ceiling_query).is_empty():
		return false

	_player.ledge_target_position = Vector2(target_x, floor_y)
	return true


func _is_vertical_intent_requested(action: StringName, digital_keys: Array[Key], axis_sign: float) -> bool:
	if not Input.is_action_pressed(action):
		return false

	for key in digital_keys:
		if Input.is_key_pressed(key):
			return true

	var joy_y: float = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	var joy_x: float = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	if joy_y * axis_sign < _player.vertical_input_threshold:
		return false

	if absf(joy_x) > 0.35:
		return absf(joy_y) > absf(joy_x) * 0.85

	return true
