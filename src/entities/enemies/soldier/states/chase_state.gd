class_name SoldierChaseState
extends State

var soldier: Soldier
var los_lost_timer: float = 0.0
var turn_cooldown_timer: float = 0.0
var anti_air_cooldown_timer: float = 0.0

func enter() -> void:
	soldier = character as Soldier
	los_lost_timer = 0.0
	turn_cooldown_timer = 0.0
	soldier.hide_telegraph()
	soldier.is_hyper_armored = false

func physics_update(delta: float) -> void:
	# Decrement timers
	if turn_cooldown_timer > 0.0:
		turn_cooldown_timer -= delta
	if anti_air_cooldown_timer > 0.0:
		anti_air_cooldown_timer -= delta

	# Gravity
	if not soldier.is_on_floor():
		soldier.velocity.y += soldier.gravity * delta
	else:
		soldier.velocity.y = 0.0

	var player := soldier.target_player
	if not player or not is_instance_valid(player):
		state_machine.transition_to("patrol")
		return

	var dx: float = player.global_position.x - soldier.global_position.x
	var dy: float = player.global_position.y - soldier.global_position.y
	var dist: float = absf(dx)

	# Target lost by distance
	if dist > soldier.lose_target_range:
		soldier.target_player = null
		state_machine.transition_to("patrol")
		return

	# Update facing towards player with deadzone and cooldown (Anti-flicker)
	if dist >= 12.0:
		var desired_dir := signf(dx)
		if desired_dir != float(soldier.facing_direction):
			if turn_cooldown_timer <= 0.0:
				soldier.update_facing(desired_dir)
				turn_cooldown_timer = 0.25 # Minimum 250ms between 180-degree turns

	# Check Line of Sight
	if not _has_los_to_player():
		los_lost_timer += delta
		if los_lost_timer > 1.2:
			soldier.target_player = null
			state_machine.transition_to("patrol")
			return
	else:
		los_lost_timer = 0.0

	# Check Anti-Air Attack (Player directly overhead / landing on head)
	# dy is negative when player is above. Soldier height is 40px (-40 to 0).
	if anti_air_cooldown_timer <= 0.0 and dist <= 24.0 and dy >= -58.0 and dy <= -16.0:
		anti_air_cooldown_timer = 0.9
		soldier.velocity.x = 0.0
		var attack_state: SoldierAttackState = state_machine.get_node("Attack") as SoldierAttackState
		if attack_state:
			attack_state.is_upward = true
			attack_state.is_downward = false
		state_machine.transition_to("attack")
		return

	# Check Downward Attack (Player is below soldier, e.g. on lower platform)
	# dy is positive when player is below.
	if anti_air_cooldown_timer <= 0.0 and dist <= 24.0 and dy >= 16.0 and dy <= 58.0:
		anti_air_cooldown_timer = 0.9
		soldier.velocity.x = 0.0
		var attack_state: SoldierAttackState = state_machine.get_node("Attack") as SoldierAttackState
		if attack_state:
			attack_state.is_upward = false
			attack_state.is_downward = true
		state_machine.transition_to("attack")
		return

	# Check Horizontal Attack Range
	if dist <= soldier.attack_range and absf(dy) < 32.0:
		soldier.velocity.x = 0.0
		var attack_state: SoldierAttackState = state_machine.get_node("Attack") as SoldierAttackState
		if attack_state:
			attack_state.is_upward = false
			attack_state.is_downward = false
		state_machine.transition_to("attack")
		return

	# Stop at ledge rather than jumping off cliff
	if _is_at_ledge():
		soldier.velocity.x = move_toward(soldier.velocity.x, 0.0, soldier.friction * delta)
		soldier.move_and_slide()
		return

	# Move towards player (smooth deceleration when inside deadzone)
	if dist >= 8.0:
		soldier.velocity.x = signf(dx) * soldier.chase_speed
	else:
		soldier.velocity.x = move_toward(soldier.velocity.x, 0.0, soldier.friction * delta)
	soldier.move_and_slide()

## Raycast: Ledge check
func _is_at_ledge() -> bool:
	var space := soldier.get_world_2d().direct_space_state
	var check_x: float = soldier.global_position.x + (soldier.facing_direction * 12.0)
	var query := PhysicsRayQueryParameters2D.create(
		Vector2(check_x, soldier.global_position.y - 2.0),
		Vector2(check_x, soldier.global_position.y + 16.0),
		1 # Layer 1: Environment
	)
	var hit := space.intersect_ray(query)
	return hit.is_empty()

## Raycast: Line of sight check
func _has_los_to_player() -> bool:
	var player := soldier.target_player
	if not player:
		return false
	var space := soldier.get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		soldier.global_position + Vector2(0.0, -20.0),
		player.global_position + Vector2(0.0, -20.0),
		1 # Layer 1: Environment
	)
	var hit := space.intersect_ray(query)
	return hit.is_empty()
