class_name WallSlideState
extends State

var player: Player

func enter() -> void:
	player = character as Player
	player.can_double_jump = true

	# Zero out velocity completely on entry so player sticks to the wall immediately!
	player.velocity = Vector2.ZERO

func physics_update(delta: float) -> void:
	if player.is_on_floor():
		state_machine.transition_to("idle")
		return

	if not player.is_on_wall_only():
		state_machine.transition_to("fall")
		return

	var wall_norm: float = signf(player.get_wall_normal().x)
	var input_dir: float = Input.get_axis("move_left", "move_right")

	# If player explicitly steers AWAY from the wall, let go
	if signf(input_dir) == wall_norm and abs(input_dir) > 0.2:
		state_machine.transition_to("fall")
		return

	# Wall jump check
	if Input.is_action_just_pressed("jump") or player.jump_buffer_timer > 0.0:
		player.jump_buffer_timer = 0.0
		state_machine.transition_to("walljump")
		return

	# Maintain slight pressure towards wall to keep is_on_wall reliable in Godot 4
	player.velocity.x = -wall_norm * 15.0
	# Slide down smoothly with clamped speed
	player.velocity.y = move_toward(player.velocity.y, player.wall_slide_speed, (player.gravity * 0.5) * delta)
	player.move_and_slide()
