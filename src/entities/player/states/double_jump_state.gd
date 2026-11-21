class_name DoubleJumpState
extends State

const ROTATION_FRAME_COUNT: int = 4
const ROTATION_STEP_DURATION: float = 1.0 / 13.0 # 4 passos (~0.308s) cobrindo a subida do duplo pulo (~0.312s)

var player: Player
var _rotation_elapsed: float = 0.0
var _current_rotation_frame: int = 0

func enter() -> void:
	player = character as Player
	player.can_double_jump = false
	player.velocity.y = player.double_jump_velocity
	player.is_wall_recovery_active = false
	player.fall_peak_y = minf(player.fall_peak_y, player.global_position.y)
	_rotation_elapsed = 0.0
	_current_rotation_frame = 0
	player.play_animation(&"double_jump")
	player.apply_double_jump_rotation_frame(0)

func exit() -> void:
	PlayerEquipmentRig.reset_visual_transform(player.visual)
	player.stop_animation()

func physics_update(delta: float) -> void:
	# Wall jump OR Wall Regrab Recovery check if pressing jump while touching wall
	if Input.is_action_just_pressed(&"jump") and player.is_on_wall_only():
		var wall_norm: float = signf(player.get_wall_normal().x)
		if wall_norm != player.last_wall_jump_normal_x:
			state_machine.transition_to("walljump")
			return
		else:
			var move_h: float = Input.get_axis(&"move_left", &"move_right")
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
	if Input.is_action_just_pressed(&"defend") and player.can_defend():
		state_machine.transition_to("guard")
		return

	if player.is_slide_requested():
		state_machine.transition_to("slide")
		return

	# Attack in air (supports holding button)
	if (Input.is_action_pressed(&"attack_primary") or player.attack_buffer_timer > 0.0) and player.can_attack():
		player.attack_buffer_timer = 0.0
		if player.is_ranged_weapon_equipped():
			state_machine.transition_to("rangedattack")
		else:
			state_machine.transition_to("attack")
		return

	var prev_facing: int = player.facing_direction
	var direction := Input.get_axis(&"move_left", &"move_right")
	if direction != 0.0:
		player.update_facing(direction)
		if player.facing_direction != prev_facing:
			player.apply_double_jump_rotation_frame(_current_rotation_frame)
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

	if _current_rotation_frame < ROTATION_FRAME_COUNT - 1:
		_rotation_elapsed += delta
		var next_frame: int = mini(int(_rotation_elapsed / ROTATION_STEP_DURATION), ROTATION_FRAME_COUNT - 1)
		if next_frame != _current_rotation_frame:
			_current_rotation_frame = next_frame
			player.apply_double_jump_rotation_frame(_current_rotation_frame)

	player.move_and_slide()
