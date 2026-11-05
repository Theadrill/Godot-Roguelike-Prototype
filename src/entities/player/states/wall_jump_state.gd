class_name WallJumpState
extends State

var player: Player
var wall_normal: Vector2 = Vector2.ZERO
var input_lock_timer: float = 0.0
const INPUT_LOCK_DURATION: float = 0.12

func enter() -> void:
	player = character as Player
	wall_normal = player.get_wall_normal()

	# Record wall normal so the player cannot immediately re-grab the same wall
	player.last_wall_jump_normal_x = signf(wall_normal.x)

	# Firm kick away from the wall
	player.velocity.x = wall_normal.x * player.wall_jump_horizontal
	player.velocity.y = player.wall_jump_vertical
	player.update_facing(wall_normal.x)
	input_lock_timer = INPUT_LOCK_DURATION

func physics_update(delta: float) -> void:
	input_lock_timer -= delta

	# Check if we hit the opposite wall to stick or chain into next jump
	if player.is_on_wall_only():
		var current_wall_norm: float = signf(player.get_wall_normal().x)
		if current_wall_norm != player.last_wall_jump_normal_x:
			if Input.is_action_just_pressed("jump") or player.jump_buffer_timer > 0.0:
				player.jump_buffer_timer = 0.0
				state_machine.transition_to("walljump")
				return
			state_machine.transition_to("wallslide")
			return

	# Air steering after input lock expires
	if input_lock_timer <= 0.0:
		var direction := Input.get_axis("move_left", "move_right")
		if direction != 0.0:
			player.update_facing(direction)
			player.velocity.x = move_toward(player.velocity.x, direction * player.run_speed, (player.run_speed / player.acceleration_time) * delta)

	player.velocity.y += player.gravity * delta

	if player.is_on_floor():
		state_machine.transition_to("idle")
		return

	if player.velocity.y >= 0.0:
		state_machine.transition_to("fall")
		return

	player.move_and_slide()
