class_name ArcherShootState
extends State

## Archer Shoot State:
## Looses the physical arrow matching the 3-signal attack type (Normal / Heavy / Perilous),
## manages tactical recovery, and transitions to kite or re-aim.

var archer: Archer
var recovery_timer: float = 0.0
var has_shot: bool = false

func enter() -> void:
	archer = character as Archer
	archer.hide_telegraph()
	has_shot = false
	recovery_timer = archer.shoot_cooldown
	archer.velocity.x = 0.0

	_loose_arrow()

func exit() -> void:
	archer.hide_telegraph()
	if archer.bow_node:
		archer.bow_node.rotation = 0.0

func physics_update(delta: float) -> void:
	# Gravity
	if not archer.is_on_floor():
		archer.velocity.y += archer.gravity * delta
	else:
		archer.velocity.y = 0.0

	# Active Cooldown Movement (after initial 0.20s recoil)
	var cooldown_elapsed: float = archer.attack_cooldown - recovery_timer
	if cooldown_elapsed < 0.20 or not archer.can_move:
		archer.velocity.x = move_toward(archer.velocity.x, 0.0, archer.friction * delta)
	else:
		var dist_to_player: float = 999.0
		if archer.target_player and is_instance_valid(archer.target_player):
			var dx: float = archer.target_player.global_position.x - archer.global_position.x
			dist_to_player = absf(dx)
			if dist_to_player >= 12.0:
				archer.update_facing(signf(dx))

		var cooldown_total: float = archer.attack_cooldown
		var is_reengaging: bool = recovery_timer <= minf(0.40, cooldown_total * 0.30)

		match archer.active_behavior:
			Archer.CooldownBehavior.DEFENSIVE_RETREAT:
				if dist_to_player < archer.min_kite_distance * 1.5 and archer.can_step_backward():
					archer.velocity.x = -float(archer.facing_direction) * (archer.kite_speed * archer.cooldown_speed_mult)
				else:
					archer.velocity.x = move_toward(archer.velocity.x, 0.0, archer.friction * delta)

			Archer.CooldownBehavior.AGGRESSIVE_STALK:
				if is_reengaging:
					archer.velocity.x = move_toward(archer.velocity.x, 0.0, archer.friction * delta)
				elif dist_to_player < 80.0 and archer.can_step_backward():
					archer.velocity.x = -float(archer.facing_direction) * (archer.kite_speed * archer.cooldown_speed_mult * 0.8)
				elif dist_to_player > 140.0 and archer.can_step_forward():
					archer.velocity.x = float(archer.facing_direction) * (archer.patrol_speed * archer.cooldown_speed_mult)
				else:
					archer.velocity.x = move_toward(archer.velocity.x, 0.0, archer.friction * delta)

			Archer.CooldownBehavior.STAND_GROUND:
				archer.velocity.x = move_toward(archer.velocity.x, 0.0, archer.friction * delta)

			Archer.CooldownBehavior.ADAPTIVE:
				if archer.is_adaptive_evading and archer.can_step_backward():
					archer.velocity.x = -float(archer.facing_direction) * (archer.kite_speed * 1.3)
				elif is_reengaging:
					archer.velocity.x = move_toward(archer.velocity.x, 0.0, archer.friction * delta)
				elif dist_to_player < 110.0 and archer.can_step_backward():
					archer.velocity.x = -float(archer.facing_direction) * (archer.kite_speed * 0.95)
				elif dist_to_player > 170.0 and archer.can_step_forward():
					archer.velocity.x = float(archer.facing_direction) * (archer.patrol_speed * 0.9)
				else:
					archer.velocity.x = move_toward(archer.velocity.x, 0.0, archer.friction * delta)

	archer.move_and_slide()

	recovery_timer -= delta
	if recovery_timer <= 0.0:
		var player := archer.target_player
		if not is_instance_valid(player) or not archer.has_line_of_sight_to(player):
			state_machine.transition_to("patrol")
			return

		var dist := archer.global_position.distance_to(player.global_position)
		if dist > archer.lose_target_range:
			state_machine.transition_to("patrol")
		elif archer.can_move and dist < archer.min_kite_distance and archer.can_step_backward():
			state_machine.transition_to("kite")
		else:
			state_machine.transition_to("aim")

func _loose_arrow() -> void:
	if has_shot:
		return
	has_shot = true

	var player := archer.target_player
	if not is_instance_valid(player):
		return

	var proj_scene := load("res://src/combat/projectile.tscn") as PackedScene
	if not proj_scene:
		return

	var spawn_pos: Vector2 = archer.arrow_spawn_marker.global_position if archer.arrow_spawn_marker else archer.global_position + Vector2(float(archer.facing_direction) * 16.0, -20.0)
	var target_pos: Vector2 = player.global_position + Vector2(0.0, -20.0)
	var shoot_dir: Vector2 = (target_pos - spawn_pos).normalized()

	# Balancing metrics per 3-signal attack type
	var final_damage: float = archer.normal_damage
	var final_speed: float = archer.arrow_speed
	var tint_color: Color = Color.WHITE

	match archer.current_attack_type:
		Hitbox.AttackCategory.NORMAL:
			final_damage = archer.normal_damage
			final_speed = archer.arrow_speed
			tint_color = Color.WHITE
		Hitbox.AttackCategory.HEAVY:
			final_damage = archer.heavy_damage
			final_speed = archer.arrow_speed * 1.2
			tint_color = Color(1.0, 0.85, 0.2, 1.0) # Yellow telegraph tint
		Hitbox.AttackCategory.PERILOUS:
			final_damage = archer.perilous_damage
			final_speed = archer.arrow_speed * 1.35
			tint_color = Color(1.0, 0.25, 0.25, 1.0) # Red perilous tint

	final_damage *= archer.active_damage_multiplier

	var proj := proj_scene.instantiate() as Projectile
	proj.setup(shoot_dir, final_speed, final_damage, archer, true)
	if proj.internal_hitbox:
		proj.internal_hitbox.attack_category = archer.current_attack_type
	proj.modulate = tint_color

	archer.get_parent().add_child(proj)
	proj.global_position = spawn_pos

	# Bow recoil impulse on archer (only if mobile)
	if archer.can_move:
		archer.velocity.x = -float(archer.facing_direction) * 40.0
	else:
		archer.velocity.x = 0.0
