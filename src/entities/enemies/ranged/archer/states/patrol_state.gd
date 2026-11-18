class_name ArcherPatrolState
extends State

## Archer Patrol State:
## Walks on platforms, detects player, and transitions to Aim or Kite.

var archer: Archer
var wait_timer: float = 0.0
var is_waiting: bool = false

func enter() -> void:
	archer = character as Archer
	archer.hide_telegraph()
	is_waiting = false
	wait_timer = 0.0

func physics_update(delta: float) -> void:
	# Gravity
	if not archer.is_on_floor():
		archer.velocity.y += archer.gravity * delta
	else:
		archer.velocity.y = 0.0

	if archer.reaggro_cooldown > 0.0:
		archer.reaggro_cooldown = maxf(0.0, archer.reaggro_cooldown - delta)

	# Scan for Player (skipped while cooling down after losing aggro)
	var player := archer.find_player() if archer.reaggro_cooldown <= 0.0 else null
	if player:
		var to_player := player.global_position - archer.global_position
		var dist := to_player.length()
		var dir_to_player := signf(to_player.x)
		var is_in_front: bool = (dir_to_player == float(archer.facing_direction)) or (dir_to_player == 0.0)
		var max_dist: float = archer.spot_range if is_in_front else archer.back_awareness_range

		if dist <= max_dist and archer.has_line_of_sight_to(player):
			archer.target_player = player
			if not is_in_front and dir_to_player != 0.0:
				archer.update_facing(dir_to_player)

			var has_angle: bool = archer.has_valid_shot_angle(player)
			if archer.can_move and ((dist < archer.min_kite_distance and archer.can_step_backward()) or not has_angle):
				state_machine.transition_to("kite")
			elif has_angle:
				state_machine.transition_to("aim")
			return

	if not archer.can_move or archer.stationary:
		archer.velocity.x = move_toward(archer.velocity.x, 0.0, archer.friction * delta)
		archer.move_and_slide()
		return

	if is_waiting:
		wait_timer -= delta
		archer.velocity.x = move_toward(archer.velocity.x, 0.0, archer.friction * delta)
		archer.move_and_slide()
		if wait_timer <= 0.0:
			is_waiting = false
			archer.update_facing(-archer.facing_direction)
		return

	# Move forward along patrol ledge (wait & turn only when grounded at an edge/wall)
	if not archer.is_on_floor():
		archer.velocity.x = 0.0
		archer.move_and_slide()
		return

	if not archer.can_step_forward():
		is_waiting = true
		wait_timer = archer.patrol_wait_duration
		archer.velocity.x = 0.0
		archer.move_and_slide()
		return

	archer.velocity.x = float(archer.facing_direction) * archer.patrol_speed
	archer.move_and_slide()
