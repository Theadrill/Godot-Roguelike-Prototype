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
	# Only disable enemy collision if there is enough clearance behind the FURTHEST enemy in the pack!
	# If ANY enemy in the group is backed against a wall with space < 18px (player body width),
	# player cannot phase through and is stopped at the outer enemy body.
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
	
	# Ray 1: Find where the solid wall is in roll direction (up to 120px ahead)
	var wall_query := PhysicsRayQueryParameters2D.create(
		player.global_position + Vector2(0, -20),
		player.global_position + Vector2(roll_direction * 120.0, -20),
		1 # Layer 1 (Environment)
	)
	var wall_hit := space_state.intersect_ray(wall_query)
	
	if wall_hit.is_empty():
		# No wall ahead: open space, full phasing allowed
		return true

	var wall_x: float = wall_hit.position.x

	# Ray 2: Raycast backwards from the wall towards the player to find the enemy CLOSEST TO THE WALL!
	# This detects the enemy at the very front of the pile (closest to the wall/step).
	var enemy_query := PhysicsRayQueryParameters2D.create(
		Vector2(wall_x - (roll_direction * 1.0), player.global_position.y - 20),
		player.global_position + Vector2(0, -20),
		4 # Layer 3 (Enemies = bitmask 4)
	)
	enemy_query.exclude = [player.get_rid()]
	var enemy_hit := space_state.intersect_ray(enemy_query)
	
	if enemy_hit.is_empty():
		# No enemy between wall and player in that segment
		return true

	var enemy_collider = enemy_hit.collider
	var enemy_x: float = enemy_hit.position.x
	if enemy_collider is Node2D:
		enemy_x = enemy_collider.global_position.x

	# Gap between wall and the enemy closest to that wall:
	var gap_to_wall: float = absf(wall_x - enemy_x)
	# Player width is 16px (requires at least 18px clearance to stand cleanly without entering wall)
	if gap_to_wall < 18.0:
		return false # The front enemy is pinned against the wall! Stop roll at the outer enemy

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
