class_name RollState
extends State

var player: Player
var roll_timer: float = 0.0
var roll_direction: float = 1.0

func enter() -> void:
	player = character as Player
	roll_timer = player.roll_duration
	roll_direction = float(player.facing_direction)

	# Decide if player can phase through enemies:
	# Only disable enemy collision if there is enough clearance behind the enemy!
	# If enemy is backed against a wall and space < 18px (player body width),
	# player cannot phase through and is stopped at the enemy body.
	var can_phase := _check_clearance_behind_enemy()
	player.set_collision_mask_value(3, not can_phase)

	# Shrink collision height to 20px so player passes under low ceilings (32px)
	_set_crouched(true)

	player.velocity.x = roll_direction * player.roll_speed
	if player.is_on_floor():
		player.velocity.y = 0.0

func exit() -> void:
	_set_crouched(false)
	# Re-enable collision with enemies (Layer 3) after roll
	player.set_collision_mask_value(3, true)

func physics_update(delta: float) -> void:
	roll_timer -= delta
	player.velocity.x = roll_direction * player.roll_speed

	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta

	player.move_and_slide()

	# Stop rolling against walls immediately so we don't get embedded
	if player.is_on_wall():
		player.velocity.x = 0.0

	# When roll duration ends, check if we have headroom to stand up
	if roll_timer <= 0.0:
		# Force raycast update
		player.ceiling_check.force_raycast_update()
		if player.ceiling_check.is_colliding():
			# Ceiling is still above our head! Continue rolling/crawling forward until clear
			return

		# Safe to stand up
		if player.is_on_floor():
			if Input.is_action_pressed("down"):
				state_machine.transition_to("crouch")
				return
			var dir := Input.get_axis("move_left", "move_right")
			if abs(dir) > 0.1:
				state_machine.transition_to("run")
			else:
				state_machine.transition_to("idle")
		else:
			state_machine.transition_to("fall")

func _check_clearance_behind_enemy() -> bool:
	var space_state := player.get_world_2d().direct_space_state
	
	# Ray 1: Find closest enemy in roll direction (up to 48px ahead)
	var enemy_query := PhysicsRayQueryParameters2D.create(
		player.global_position + Vector2(0, -20),
		player.global_position + Vector2(roll_direction * 48.0, -20),
		4 # Layer 3 (Enemies = bitmask 4)
	)
	enemy_query.exclude = [player.get_rid()]
	var enemy_hit := space_state.intersect_ray(enemy_query)
	
	if enemy_hit.is_empty():
		# No enemy ahead in close range: full phasing allowed
		return true

	var enemy_collider = enemy_hit.collider
	var enemy_pos: Vector2 = enemy_hit.position
	if enemy_collider is Node2D:
		enemy_pos = enemy_collider.global_position

	# Ray 2: Raycast from enemy outwards in roll direction looking for solid Environment (Layer 1 = bitmask 1)
	var wall_query := PhysicsRayQueryParameters2D.create(
		enemy_pos + Vector2(0, -20),
		enemy_pos + Vector2(roll_direction * 40.0, -20),
		1 # Layer 1 (Environment)
	)
	var wall_hit := space_state.intersect_ray(wall_query)
	
	if not wall_hit.is_empty():
		# Distance between enemy contact point and wall
		var gap: float = absf(wall_hit.position.x - enemy_pos.x)
		# Player width is 16px (requires at least 18px clearance to fit cleanly without entering wall)
		if gap < 18.0:
			return false # Not enough room! Stop at enemy

	return true

func _set_crouched(crouched: bool) -> void:
	var rect := player.collision_shape.shape as RectangleShape2D
	if not rect:
		return

	if crouched:
		rect.size = Vector2(16.0, 20.0)
		player.collision_shape.position = Vector2(0.0, -10.0)
		player.visual.scale.y = 0.5
	else:
		rect.size = Vector2(16.0, 40.0)
		player.collision_shape.position = Vector2(0.0, -20.0)
		player.visual.scale.y = 1.0

		# Depenetration safety: if standing up causes overlap with a wall, push out cleanly
		var test_col := player.move_and_collide(Vector2.ZERO, true)
		if test_col:
			var normal := test_col.get_normal()
			if abs(normal.x) > 0.5:
				player.global_position.x += normal.x * (test_col.get_depth() + 1.0)
