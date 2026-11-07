class_name RangedAttackState
extends State

## Ranged Attack State for Bow and Crossbow:
## Implements continuous fire (holding button to continuously loose arrows/bolts),
## charge mechanics for charge weapons/spells, directional aiming, and tactical recovery.

var player: Player

var attack_phase: int = 0 # 0: Aim/Draw/Charge, 1: Fire, 2: Recovery/Reload
var phase_timer: float = 0.0
var charge_progress: float = 0.0
var has_fired: bool = false

func enter() -> void:
	player = character as Player
	if not player.weapon:
		_exit_to_movement()
		return

	# Apply attack visual pose on weapon instance (straight vertical bow)
	if player._main_weapon_instance:
		player._main_weapon_instance.position = player.weapon.attack_visual_offset
		player._main_weapon_instance.rotation_degrees = player.weapon.attack_visual_rotation_degrees

	_start_shot_cycle()

func _start_shot_cycle() -> void:
	has_fired = false
	charge_progress = 0.0
	phase_timer = 0.0

	# Crossbow fires instantly on trigger; Bow/charge weapons begin drawing string/accumulating charge
	if player.weapon.weapon_category == WeaponData.WeaponCategory.RANGED_CROSSBOW:
		_fire_projectile()
	else:
		attack_phase = 0
		var is_aiming_up: bool = Input.is_action_pressed("up") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
		if player.main_hand_socket:
			player.main_hand_socket.rotation_degrees = -45.0 if is_aiming_up else 0.0

func exit() -> void:
	has_fired = false
	# Restore resting grip stance (visual_offset and visual_rotation_degrees)
	if player.weapon and player._main_weapon_instance:
		player._main_weapon_instance.position = player.weapon.visual_offset
		player._main_weapon_instance.rotation_degrees = player.weapon.visual_rotation_degrees
		player._main_weapon_instance.modulate = Color.WHITE
		player._main_weapon_instance.scale = Vector2.ONE
	if player.main_hand_socket:
		player.main_hand_socket.rotation_degrees = -35.0

func physics_update(delta: float) -> void:
	# Gravity in air
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
	else:
		player.velocity.y = 0.0

	match attack_phase:
		0:
			# Drawing / Charging
			var charge_duration: float = player.weapon.max_charge_time if player.weapon.is_charge_attack else player.weapon.charge_time
			charge_progress = minf(1.0, charge_progress + delta / maxf(0.05, charge_duration))

			var is_aiming_up: bool = Input.is_action_pressed("up") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
			var base_angle: float = -45.0 if is_aiming_up else 0.0

			# Tremor feedback flag
			var jitter: float = 0.0
			if player.weapon.charge_has_tremor:
				jitter = (randf() - 0.5) * 4.5 * charge_progress

			if player.main_hand_socket:
				player.main_hand_socket.rotation_degrees = base_angle + jitter

			# Energizing glow feedback flag
			if player._main_weapon_instance:
				if player.weapon.charge_has_energize:
					var pulse: float = sin(float(Time.get_ticks_msec()) * 0.015) * 0.2 if charge_progress >= 1.0 else 0.0
					var intensity: float = 1.0 + (charge_progress * 1.6) + pulse
					var energy_col := player.weapon.charge_energy_color
					player._main_weapon_instance.modulate = Color(
						1.0 + (energy_col.r * intensity * 0.7),
						1.0 + (energy_col.g * intensity * 0.7),
						1.0 + (energy_col.b * intensity * 0.7),
						1.0
					)
					var scale_mult: float = 1.0 + (charge_progress * 0.15)
					player._main_weapon_instance.scale = Vector2(scale_mult, scale_mult)
				else:
					player._main_weapon_instance.modulate = Color.WHITE
					player._main_weapon_instance.scale = Vector2.ONE

			# Slow tactical movement while aiming bow on floor
			if player.is_on_floor():
				var move_dir := Input.get_axis("move_left", "move_right")
				player.velocity.x = move_toward(player.velocity.x, move_dir * (player.run_speed * 0.4), 800.0 * delta)
				if move_dir != 0.0:
					player.update_facing(move_dir)
			else:
				player.velocity.x = move_toward(player.velocity.x, 0.0, 300.0 * delta)

			player.move_and_slide()

			# Determine when to loose projectile:
			if player.weapon.is_charge_attack:
				# Charge weapon/spell: release button to fire (or trigger upon max charge)
				if not Input.is_action_pressed("attack_primary"):
					_fire_projectile()
			else:
				# Continuous firing weapon (auto-fire): release immediately when draw completes, or on button release
				if charge_progress >= 1.0 or not Input.is_action_pressed("attack_primary"):
					_fire_projectile()

		2:
			# Recovery / Reload phase
			phase_timer -= delta
			player.velocity.x = move_toward(player.velocity.x, 0.0, 700.0 * delta)
			player.move_and_slide()

			# Roll cancel during reload
			if player.is_roll_requested():
				state_machine.transition_to("roll")
				return

			# Guard cancel during reload
			if Input.is_action_just_pressed("defend") and player.can_defend():
				state_machine.transition_to("guard")
				return

			if phase_timer <= 0.0:
				if Input.is_action_pressed("attack_primary") and not player.weapon.is_charge_attack:
					# Keep firing while holding attack!
					_start_shot_cycle()
				else:
					_exit_to_movement()

func _fire_projectile() -> void:
	if has_fired:
		return
	has_fired = true
	attack_phase = 2 # Enter recovery/reload

	# Reset visual charge aura upon discharge
	if player._main_weapon_instance:
		player._main_weapon_instance.modulate = Color.WHITE
		player._main_weapon_instance.scale = Vector2.ONE

	var weapon := player.weapon
	var proj_scene: PackedScene = weapon.projectile_scene if weapon.projectile_scene else load("res://src/combat/projectile.tscn")
	if not proj_scene:
		_exit_to_movement()
		return

	# Determine aiming angle: straight horizontal or 45-degree upward shot
	var is_aiming_up: bool = Input.is_action_pressed("up") or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)
	var shoot_dir := Vector2(float(player.facing_direction), 0.0)
	if is_aiming_up:
		shoot_dir = Vector2(float(player.facing_direction) * 0.7, -0.7).normalized()
		if player.main_hand_socket:
			player.main_hand_socket.rotation_degrees = -45.0
	else:
		if player.main_hand_socket:
			player.main_hand_socket.rotation_degrees = 0.0

	# Calculate speed and damage scaled by charge ratio
	var final_speed: float = weapon.projectile_speed
	var final_damage: float = weapon.base_damage
	if weapon.is_charge_attack:
		final_damage = weapon.base_damage * (1.0 + charge_progress * (weapon.charge_damage_multiplier - 1.0))
		final_speed = weapon.projectile_speed * (0.8 + charge_progress * 0.4)
	else:
		var charge_mult := clampf(charge_progress, 0.75, 1.0)
		final_speed *= charge_mult
		final_damage *= charge_mult

	# Instantiate projectile in world
	var proj := proj_scene.instantiate() as Projectile
	var base_origin: Vector2
	if player.main_hand_socket:
		base_origin = player.main_hand_socket.global_position
	else:
		base_origin = player.global_position + Vector2(float(player.facing_direction) * 8.0, -20.0)

	var spawn_pos: Vector2 = base_origin + shoot_dir * 16.0
	proj.setup(shoot_dir, final_speed, final_damage, player, false)
	player.get_parent().add_child(proj)
	proj.global_position = spawn_pos

	# Firing recoil & tactile feedback (Bows keep player planted firmly; Crossbow has heavy kickback)
	var recoil_force: float = 0.0 if weapon.weapon_category == WeaponData.WeaponCategory.RANGED_BOW else 120.0
	if recoil_force > 0.0:
		player.velocity.x = -player.facing_direction * recoil_force
	else:
		player.velocity.x = 0.0
	CombatFeedback.apply_hit_feedback(0.04, weapon.rumble_weak, weapon.rumble_strong, weapon.rumble_duration)

	# Set reload/recovery cadence
	phase_timer = weapon.reload_time

func _exit_to_movement() -> void:
	if not player.is_on_floor():
		state_machine.transition_to("fall")
	else:
		var dir := Input.get_axis("move_left", "move_right")
		if abs(dir) > 0.1:
			state_machine.transition_to("run")
		else:
			state_machine.transition_to("idle")
