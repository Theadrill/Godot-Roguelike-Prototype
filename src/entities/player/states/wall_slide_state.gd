class_name WallSlideState
extends State

## Progressive Wall Slide / Cling State with Grip Limit.
## Simulates realistic friction falloff:
## 1. Initial solid grip hold (e.g. 0.5s freeze)
## 2. Struggling slip phase: velocity starts tiny (15 px/s) and accelerates smoothly
##    over 1.2s up to max slide speed (220 px/s), mimicking grip failing under gravity.
## 3. Grip expiration: after wall_grip_duration, the player completely loses grip and falls.
## 4. Player can jump off, let go, or press DOWN to bypass the hold and drop fast.

var player: Player
var slide_timer: float = 0.0

func enter() -> void:
	player = character as Player
	player.velocity = Vector2.ZERO
	slide_timer = 0.0
	player.last_wall_jump_normal_x = 0.0
	player.is_wall_recovery_active = false
	player.play_animation(&"wall_cling")

func physics_update(delta: float) -> void:
	if player.is_on_floor():
		state_machine.transition_to("idle")
		return

	# Wall jump check FIRST before any detach checks!
	if Input.is_action_just_pressed("jump") or player.jump_buffer_timer > 0.0:
		player.jump_buffer_timer = 0.0
		state_machine.transition_to("walljump")
		return

	var wall_norm: float = signf(player.get_wall_normal().x)
	var input_dir: float = Input.get_axis("move_left", "move_right")

	if not player.is_on_wall_only():
		player.wall_fall_start_y = player.global_position.y
		if wall_norm != 0.0:
			player.last_wall_jump_normal_x = wall_norm
		player.is_wall_recovery_active = true
		state_machine.transition_to("fall")
		return

	# Orient player into the wall
	if wall_norm != 0.0:
		player.update_facing(-wall_norm)

	# If player explicitly steers AWAY from the wall (and didn't jump), let go
	if signf(input_dir) == wall_norm and abs(input_dir) > 0.4:
		player.wall_fall_start_y = player.global_position.y
		player.last_wall_jump_normal_x = wall_norm
		player.is_wall_recovery_active = true
		state_machine.transition_to("fall")
		return

	# Ledge climb check: if near the top corner of the wall
	if not player.is_crouch_requested():
		if player.check_ledge():
			state_machine.transition_to("ledgeclimb")
			return

	slide_timer += delta

	# Grip limit: if player stays on wall too long, grip fails completely and player falls!
	if slide_timer >= player.wall_grip_duration:
		player.wall_fall_start_y = player.global_position.y
		player.last_wall_jump_normal_x = wall_norm
		player.is_wall_recovery_active = true
		player.velocity.x = wall_norm * 40.0
		state_machine.transition_to("fall")
		return

	# If holding down, immediately skip hold and accelerate to full slide speed
	if Input.is_action_pressed("down"):
		slide_timer = maxf(slide_timer, player.wall_cling_hold_time + player.wall_slide_accel_duration)

	# Maintain slight pressure towards wall to keep is_on_wall reliable in Godot 4
	player.velocity.x = -wall_norm * 15.0

	# Progressive grip physics:
	if slide_timer < player.wall_cling_hold_time:
		# Phase 1: Firm grip hold (completely stationary)
		player.velocity.y = 0.0
		if not player.player_sprite or player.player_sprite.animation != &"wall_cling":
			player.play_animation(&"wall_cling")
	else:
		# Phase 2: Slipping struggle (smooth non-linear acceleration from min to max speed)
		var slip_time := slide_timer - player.wall_cling_hold_time
		var t := clampf(slip_time / maxf(player.wall_slide_accel_duration, 0.01), 0.0, 1.0)
		# Quadratic friction falloff: starts almost imperceptible, then accelerates quickly
		var curve := t * t
		var target_speed := lerpf(player.wall_slide_min_speed, player.wall_slide_max_speed, curve)
		player.velocity.y = move_toward(player.velocity.y, target_speed, (player.gravity * 0.8) * delta)
		if not player.player_sprite or player.player_sprite.animation != &"wall_slide":
			player.play_animation(&"wall_slide")

	player.move_and_slide()
