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
	# Only disable enemy collision if there is GENUINE standing room behind the enemies!
	# Minimum gap: 16px (player width) + 5px margin = 21px
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
	
	# Ray 1: Find the closest solid wall in roll direction (up to 160px ahead)
	var wall_query := PhysicsRayQueryParameters2D.create(
		player.global_position + Vector2(0, -20),
		player.global_position + Vector2(roll_direction * 160.0, -20),
		1 # Layer 1 (Environment)
	)
	var wall_hit := space_state.intersect_ray(wall_query)
	
	if wall_hit.is_empty():
		# No wall ahead: open space, full phasing allowed
		return true

	var wall_x: float = wall_hit.position.x

	# 1) Check if there is an enemy immediately adjacent/ahead of the player (within 40px)
	var near_query := PhysicsRayQueryParameters2D.create(
		player.global_position + Vector2(0, -20),
		player.global_position + Vector2(roll_direction * 40.0, -20),
		4 # Layer 3 (Enemies)
	)
	near_query.exclude = [player.get_rid()]
	var near_hit := space_state.intersect_ray(near_query)
	
	if near_hit.is_empty():
		# No enemy right in front of the player to collide with: roll freely
		return true

	# 2) An enemy is in front of us.
	# Check clearance to the wall: where is the enemy closest to the wall?
	var enemy_query := PhysicsRayQueryParameters2D.create(
		Vector2(wall_x + (roll_direction * 5.0), player.global_position.y - 20),
		player.global_position + Vector2(0, -20),
		4 # Layer 3 (Enemies)
	)
	enemy_query.exclude = [player.get_rid()]
	var enemy_hit := space_state.intersect_ray(enemy_query)
	
	if enemy_hit.is_empty():
		return true

	var front_enemy_x: float = enemy_hit.position.x
	var gap_to_wall: float = absf(wall_x - front_enemy_x)

	# If the front-most enemy is pinned against the wall (gap < 21px = 16px body + 5px margin):
	if gap_to_wall < 21.0:
		# Check if the player has enough clearance between the near enemy and the pinned front enemy!
		# If this is the SAME enemy (or the enemies are touching/packed with no 21px gap between them):
		var near_enemy_x: float = near_hit.position.x
		var space_between_enemies: float = absf(front_enemy_x - near_enemy_x)
		
		# If there's no room between the enemies (packed together), player cannot phase
		if space_between_enemies < 21.0:
			return false

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
