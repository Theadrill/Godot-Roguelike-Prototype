class_name FallState
extends State

var player: Player

func enter() -> void:
	player = character as Player
	if player.fall_peak_y == 0.0:
		player.fall_peak_y = player.global_position.y
	else:
		player.fall_peak_y = minf(player.fall_peak_y, player.global_position.y)

	var prev_state_name: String = state_machine.previous_state.name if state_machine and state_machine.previous_state else ""
	if prev_state_name in ["Jump", "WallJump"]:
		player.play_animation(&"fall_from_jump")
	else:
		player.play_animation(&"fall")

func exit() -> void:
	player.stop_animation()

func physics_update(delta: float) -> void:
	if player.is_on_floor():
		var total_fall: float = player.global_position.y - player.fall_peak_y
		player.fall_peak_y = player.global_position.y

		# Hard landing from high altitude (knees impact and quick recovery)
		if total_fall >= player.hard_landing_min_distance:
			state_machine.transition_to("hardlanding")
			return

		if player.jump_buffer_timer > 0.0:
			player.jump_buffer_timer = 0.0
			state_machine.transition_to("jump")
			return
		elif abs(Input.get_axis("move_left", "move_right")) > 0.1:
			state_machine.transition_to("run")
			return
		else:
			state_machine.transition_to("idle")
			return

	if player.coyote_timer > 0.0 and Input.is_action_just_pressed("jump"):
		player.coyote_timer = 0.0
		state_machine.transition_to("jump")
		return

	# Wall jump OR Wall Regrab Recovery check while touching wall
	if (Input.is_action_just_pressed("jump") or player.jump_buffer_timer > 0.0) and player.is_on_wall_only():
		var wall_norm: float = signf(player.get_wall_normal().x)
		if wall_norm != player.last_wall_jump_normal_x:
			# Different wall: kick off with normal wall jump
			player.jump_buffer_timer = 0.0
			state_machine.transition_to("walljump")
			return
		else:
			# Same wall recovery: after falling >= min fall distance, pressing jump regrabs the wall!
			var move_h: float = Input.get_axis("move_left", "move_right")
			var steering_away: bool = (move_h != 0.0 and signf(move_h) == wall_norm)
			var fall_dist: float = player.global_position.y - player.wall_fall_start_y
			if not steering_away and fall_dist >= player.wall_regrab_min_fall_distance:
				player.jump_buffer_timer = 0.0
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

	if Input.is_action_just_pressed("jump") and player.can_double_jump:
		state_machine.transition_to("doublejump")
		return

	if player.is_slide_requested():
		state_machine.transition_to("slide")
		return

	# Attack in air (supports holding button)
	if Input.is_action_pressed("attack_primary") and player.can_attack():
		if player.is_ranged_weapon_equipped():
			state_machine.transition_to("rangedattack")
		else:
			state_machine.transition_to("attack")
		return

	# Horizontal air control (update facing first)
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		player.update_facing(direction)

	# Ledge climb check: mantle onto platform corner if touching or moving towards ledge
	var is_holding_away: bool = (direction != 0.0 and signf(direction) != float(player.facing_direction))
	if not is_holding_away:
		if player.check_ledge():
			state_machine.transition_to("ledgeclimb")
			return

	if player.is_on_wall_only():
		var wall_norm: float = signf(player.get_wall_normal().x)
		if wall_norm != player.last_wall_jump_normal_x:
			if signf(direction) == -wall_norm:
				state_machine.transition_to("wallslide")
				return

	# Gravity: 100% normal, or slightly floatier (e.g. 0.85x) during wall recovery to give reaction window!
	var grav_mult: float = player.fall_gravity_multiplier
	if player.is_wall_recovery_active:
		grav_mult *= player.wall_recovery_gravity_multiplier
	player.velocity.y += (player.gravity * grav_mult) * delta

	if direction != 0.0:
		player.velocity.x = move_toward(
			player.velocity.x,
			direction * player.run_speed,
			(player.run_speed / player.acceleration_time) * delta
		)
	else:
		player.velocity.x = move_toward(
			player.velocity.x,
			0.0,
			(player.run_speed / player.acceleration_time) * delta
		)

	player.move_and_slide()
