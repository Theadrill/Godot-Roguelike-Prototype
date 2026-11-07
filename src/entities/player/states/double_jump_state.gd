class_name DoubleJumpState
extends State

var player: Player

func enter() -> void:
	player = character as Player
	player.can_double_jump = false
	player.velocity.y = player.double_jump_velocity
	player.is_wall_recovery_active = false
	player.fall_peak_y = minf(player.fall_peak_y, player.global_position.y)

func physics_update(delta: float) -> void:
	# Wall jump OR Wall Regrab Recovery check if pressing jump while touching wall
	if Input.is_action_just_pressed("jump") and player.is_on_wall_only():
		var wall_norm: float = signf(player.get_wall_normal().x)
		if wall_norm != player.last_wall_jump_normal_x:
			state_machine.transition_to("walljump")
			return
		else:
			var move_h: float = Input.get_axis("move_left", "move_right")
			var steering_away: bool = (move_h != 0.0 and signf(move_h) == wall_norm)
			var fall_dist: float = player.global_position.y - player.wall_fall_start_y
			if not steering_away and fall_dist >= player.wall_regrab_min_fall_distance:
				player.last_wall_jump_normal_x = 0.0
				state_machine.transition_to("wallslide")
				return

	# Ground Slam check (Down + Jump in air)
	if player.is_ground_slam_requested():
		state_machine.transition_to("groundslam")
		return

	# Air Guard / Parry check
	if Input.is_action_just_pressed("defend") and player.can_defend():
		state_machine.transition_to("guard")
		return

	if player.is_roll_requested():
		state_machine.transition_to("roll")
		return

	# Attack in air (supports holding button)
	if Input.is_action_pressed("attack_primary") and player.can_attack():
		if player.is_ranged_weapon_equipped():
			state_machine.transition_to("rangedattack")
		else:
			state_machine.transition_to("attack")
		return

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		player.update_facing(direction)
		player.velocity.x = move_toward(player.velocity.x, direction * player.run_speed, (player.run_speed / player.acceleration_time) * delta)
	else:
		player.velocity.x = move_toward(player.velocity.x, 0.0, (player.run_speed / 0.15) * delta)

	player.velocity.y += player.gravity * delta
	player.fall_peak_y = minf(player.fall_peak_y, player.global_position.y)

	if player.velocity.y >= 0.0:
		state_machine.transition_to("fall")
		return

	# Ledge climb check while rising towards corner
	var is_holding_away: bool = (direction != 0.0 and signf(direction) != float(player.facing_direction))
	if not is_holding_away:
		if player.check_ledge():
			state_machine.transition_to("ledgeclimb")
			return

	player.move_and_slide()
