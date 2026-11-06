class_name AttackState
extends State

## Attack State with 3-step weapon combo, forward impulse, charge strikes, and dodge-cancel.

var player: Player
var current_step: int = 0
var attack_timer: float = 0.0
var combo_buffered: bool = false
var last_attack_end_msec: int = -10000

var is_charging: bool = false
var charge_progress: float = 0.0

const COMBO_WINDOW: float = 0.32

func enter() -> void:
	player = character as Player

	# If weapon has is_charge_attack enabled (e.g. War Hammer)
	if player.weapon and player.weapon.is_charge_attack:
		is_charging = true
		charge_progress = 0.0
		current_step = 0
		# Windup pose: pull weapon back
		if player.main_hand_socket:
			player.main_hand_socket.rotation_degrees = -65.0
		return

	is_charging = false
	var elapsed_sec: float = float(Time.get_ticks_msec() - last_attack_end_msec) / 1000.0
	if elapsed_sec <= COMBO_WINDOW:
		current_step = (current_step + 1) % player.weapon.combo_durations.size()
	else:
		current_step = 0
		
	_start_combo_step(0.0)

func _start_combo_step(charge_ratio: float = 0.0) -> void:
	combo_buffered = false
	attack_timer = player.weapon.combo_durations[current_step]
	
	# Allow reversing direction between combo steps if steering
	var input_dir: float = Input.get_axis("move_left", "move_right")
	if abs(input_dir) > 0.1:
		player.update_facing(input_dir)

	var is_upward: bool = player.is_upward_attack_requested()
	var is_downward: bool = player.is_crouch_requested()
	
	if is_upward:
		player.velocity.x = 0.0
		if player.hitbox.has_node("CollisionShape2D"):
			player.hitbox.get_node("CollisionShape2D").position = Vector2(0.0, -36.0)
			(player.hitbox.get_node("CollisionShape2D").shape as RectangleShape2D).size = Vector2(32.0, 32.0)
		player.hitbox.knockback_direction = Vector2(player.facing_direction * 0.15, -1.0).normalized()
	elif is_downward:
		if not player.is_on_floor():
			# Midair downward slash: maintain pure fall speed, zero upward bounce
			player.velocity.x = 0.0
			if player.hitbox.has_node("CollisionShape2D"):
				player.hitbox.get_node("CollisionShape2D").position = Vector2(0.0, 6.0)
				(player.hitbox.get_node("CollisionShape2D").shape as RectangleShape2D).size = Vector2(32.0, 28.0)
			player.hitbox.knockback_direction = Vector2(player.facing_direction * 0.15, 1.0).normalized()
		else:
			# Ground low crouch sweep
			player.velocity.x = player.facing_direction * 25.0
			if player.hitbox.has_node("CollisionShape2D"):
				player.hitbox.get_node("CollisionShape2D").position = Vector2(20.0, -10.0)
				(player.hitbox.get_node("CollisionShape2D").shape as RectangleShape2D).size = Vector2(32.0, 20.0)
			player.hitbox.knockback_direction = Vector2(player.facing_direction, -0.1).normalized()
	else:
		# Forward physical step (bonus impulse on charged smash!)
		var impulse_mult: float = 1.0 + charge_ratio * 0.4
		var forward_impulse: float = player.weapon.forward_impulses[current_step] * impulse_mult
		player.velocity.x = player.facing_direction * forward_impulse
		if player.hitbox.has_node("CollisionShape2D"):
			player.hitbox.get_node("CollisionShape2D").position = Vector2(20.0, -20.0)
			(player.hitbox.get_node("CollisionShape2D").shape as RectangleShape2D).size = Vector2(32.0, 28.0)
		player.hitbox.knockback_direction = Vector2(player.facing_direction, -0.2).normalized()

	# When on ground, clamp vertical speed to 0; when in air, leave gravity/fall speed completely untouched!
	if player.is_on_floor():
		player.velocity.y = 0.0

	# Setup active hitbox with scaling per combo step and charge ratio
	var step_mult: float = 1.0 + (current_step * 0.25)
	var charge_mult: float = 1.0 + charge_ratio * (player.weapon.charge_damage_multiplier - 1.0)
	var total_mult: float = step_mult * charge_mult

	player.hitbox.damage = player.weapon.base_damage * total_mult
	player.hitbox.knockback_force = player.weapon.knockback_force * total_mult
	player.hitbox.hitstop_duration = player.weapon.hitstop_duration * (1.0 + charge_ratio * 0.5)
	player.hitbox.rumble_weak = minf(1.0, player.weapon.rumble_weak * total_mult)
	player.hitbox.rumble_strong = minf(1.0, player.weapon.rumble_strong * total_mult)
	player.hitbox.rumble_duration = player.weapon.rumble_duration * (1.0 + charge_ratio * 0.4)
	player.hitbox.combo_step = current_step + 1

	if charge_ratio > 0.4:
		# Extra impact juice for charged strike
		CombatFeedback.apply_hit_feedback(0.08, 0.7, 1.0, 0.15)
	
	player.hitbox.set_active(false)
	player.hitbox.set_active(true)
	player.set_slash_visual(true, current_step, is_upward, is_downward)

func exit() -> void:
	is_charging = false
	if player._main_weapon_instance:
		player._main_weapon_instance.modulate = Color.WHITE
		player._main_weapon_instance.scale = Vector2.ONE
	if player.main_hand_socket:
		player.main_hand_socket.rotation_degrees = -35.0
	if player.hitbox.has_node("CollisionShape2D"):
		player.hitbox.get_node("CollisionShape2D").position = Vector2(20.0, -20.0)
		(player.hitbox.get_node("CollisionShape2D").shape as RectangleShape2D).size = Vector2(32.0, 28.0)
	player.hitbox.set_active(false)
	player.set_slash_visual(false, 0, false, false)
	combo_buffered = false
	if player.attack_cooldown_timer <= 0.0:
		player.attack_cooldown_timer = player.weapon.attack_cooldown
	last_attack_end_msec = Time.get_ticks_msec()

func physics_update(delta: float) -> void:
	if is_charging:
		# Accumulate melee charge while holding attack
		var max_t: float = maxf(0.05, player.weapon.max_charge_time)
		charge_progress = minf(1.0, charge_progress + delta / max_t)

		# Tremor feedback flag
		var jitter: float = 0.0
		if player.weapon.charge_has_tremor:
			jitter = (randf() - 0.5) * 5.0 * charge_progress

		if player.main_hand_socket:
			player.main_hand_socket.rotation_degrees = -65.0 + jitter

		# Energizing glow feedback flag
		if player._main_weapon_instance:
			if player.weapon.charge_has_energize:
				var pulse: float = sin(float(Time.get_ticks_msec()) * 0.015) * 0.2 if charge_progress >= 1.0 else 0.0
				var intensity: float = 1.0 + (charge_progress * 1.5) + pulse
				var energy_col := player.weapon.charge_energy_color
				player._main_weapon_instance.modulate = Color(
					1.0 + (energy_col.r * intensity * 0.7),
					1.0 + (energy_col.g * intensity * 0.7),
					1.0 + (energy_col.b * intensity * 0.7),
					1.0
				)
				var scale_mult: float = 1.0 + (charge_progress * 0.12)
				player._main_weapon_instance.scale = Vector2(scale_mult, scale_mult)
			else:
				player._main_weapon_instance.modulate = Color.WHITE
				player._main_weapon_instance.scale = Vector2.ONE

		# Slow foot movement on ground during windup
		if player.is_on_floor():
			var dir := Input.get_axis("move_left", "move_right")
			player.velocity.x = move_toward(player.velocity.x, dir * (player.run_speed * 0.25), 600.0 * delta)
			if dir != 0.0:
				player.update_facing(dir)
		else:
			player.velocity.y += (player.gravity * player.fall_gravity_multiplier) * delta

		player.move_and_slide()

		# Roll cancel during charge
		if Input.is_action_just_pressed("roll"):
			is_charging = false
			state_machine.transition_to("roll")
			return

		# Release button: UNLEASH CHARGED SMASH!
		if not Input.is_action_pressed("attack_primary"):
			is_charging = false
			_start_combo_step(charge_progress)
		return

	attack_timer -= delta
	
	# Dodge-cancel: can always roll out of an attack immediately!
	if Input.is_action_just_pressed("roll"):
		state_machine.transition_to("roll")
		return
		
	# Input buffer for next combo hit (supports holding down attack)
	if Input.is_action_pressed("attack_primary"):
		combo_buffered = true
		
	# Decelerate horizontal impulse on ground; maintain full natural gravity in air
	if player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0.0, 700.0 * delta)
	else:
		player.velocity.y += (player.gravity * player.fall_gravity_multiplier) * delta
		
	player.move_and_slide()
	
	# Attack frame completed
	if attack_timer <= 0.0:
		player.hitbox.set_active(false)
		player.set_slash_visual(false, 0)
		last_attack_end_msec = Time.get_ticks_msec()
		
		# If another hit was buffered and we haven't reached the combo finisher
		if combo_buffered and (current_step + 1 < player.weapon.combo_durations.size()):
			current_step += 1
			_start_combo_step(0.0)
			return
			
		# Combo chain ended or standalone swing: apply cadence recovery cooldown
		if current_step + 1 >= player.weapon.combo_durations.size():
			player.attack_cooldown_timer = player.weapon.combo_finisher_cooldown
		else:
			player.attack_cooldown_timer = player.weapon.attack_cooldown
		
		current_step = 0
		if player.is_on_floor():
			if abs(Input.get_axis("move_left", "move_right")) > 0.1:
				state_machine.transition_to("run")
			else:
				state_machine.transition_to("idle")
		else:
			state_machine.transition_to("fall")
