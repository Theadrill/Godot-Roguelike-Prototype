class_name CrouchState
extends State

## Crouch / Duck State when pressing down.
## Decreases player hitbox height to 20px (under 32px gaps) and prevents walking through solid enemies.

var player: Player

func enter() -> void:
	player = character as Player
	player.velocity.x = 0.0
	_set_crouched(true)

func exit() -> void:
	_set_crouched(false)

func physics_update(delta: float) -> void:
	if not player.is_on_floor():
		state_machine.transition_to("fall")
		return

	# Roll from crouch
	if Input.is_action_just_pressed("roll"):
		state_machine.transition_to("roll")
		return

	# Jump from crouch
	if Input.is_action_just_pressed("jump") or player.jump_buffer_timer > 0.0:
		player.jump_buffer_timer = 0.0
		state_machine.transition_to("jump")
		return

	# Attack from crouch
	if Input.is_action_just_pressed("attack_primary") and player.can_attack():
		state_machine.transition_to("attack")
		return

	# Decelerate any remaining residual velocity
	player.velocity.x = move_toward(player.velocity.x, 0.0, 800.0 * delta)
	player.move_and_slide()

	# If release down, check ceiling clearance before uncrouching
	var is_holding_down: bool = player.is_crouch_requested()
	if not is_holding_down:
		player.ceiling_check.force_raycast_update()
		if not player.ceiling_check.is_colliding():
			var h_dir: float = Input.get_axis("move_left", "move_right")
			if abs(h_dir) > 0.1:
				state_machine.transition_to("run")
			else:
				state_machine.transition_to("idle")

func _set_crouched(crouched: bool) -> void:
	var rect := player.collision_shape.shape as RectangleShape2D
	if not rect:
		return

	if crouched:
		rect.size = Vector2(16.0, 20.0)
		player.collision_shape.position = Vector2(0.0, -10.0)
		player.visual.scale.y = 0.5
		if player.hurtbox and player.hurtbox.has_node("CollisionShape2D"):
			var h_rect := player.hurtbox.get_node("CollisionShape2D").shape as RectangleShape2D
			if h_rect:
				h_rect.size = Vector2(16.0, 20.0)
				player.hurtbox.get_node("CollisionShape2D").position = Vector2(0.0, -10.0)
	else:
		rect.size = Vector2(16.0, 40.0)
		player.collision_shape.position = Vector2(0.0, -20.0)
		player.visual.scale.y = 1.0
		if player.hurtbox and player.hurtbox.has_node("CollisionShape2D"):
			var h_rect := player.hurtbox.get_node("CollisionShape2D").shape as RectangleShape2D
			if h_rect:
				h_rect.size = Vector2(16.0, 40.0)
				player.hurtbox.get_node("CollisionShape2D").position = Vector2(0.0, -20.0)
