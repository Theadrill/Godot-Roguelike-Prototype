class_name AttackState
extends State

## Attack State with 3-step weapon combo, forward impulse, charge strikes, and dodge-cancel.

var player: Player
var current_step: int = 0
var attack_timer: float = 0.0
var combo_buffered: bool = false
var queued_combo_presses: int = 0
var last_attack_end_msec: int = -10000
var last_completed_step: int = -1

var is_charging: bool = false
var charge_progress: float = 0.0

const COMBO_WINDOW: float = 1.35

func enter() -> void:
	player = character as Player

	# If weapon has is_charge_attack enabled (e.g. War Hammer)
	if player.weapon and player.weapon.is_charge_attack:
		is_charging = true
		charge_progress = 0.0
		current_step = 0
		last_completed_step = -1
		queued_combo_presses = 0
		# Windup pose: pull weapon back
		if player.main_hand_socket:
			player.main_hand_socket.rotation_degrees = -65.0
		return

	is_charging = false
	var combo_size: int = player.weapon.get_combo_step_count() if player.weapon else 2
	var combo_window: float = player.weapon.get_combo_window() if player.weapon else COMBO_WINDOW
	var elapsed_sec: float = float(Time.get_ticks_msec() - last_attack_end_msec) / 1000.0
	if elapsed_sec <= combo_window and last_completed_step >= 0:
		if player.weapon and not player.weapon.is_combo_looping() and (last_completed_step + 1 >= combo_size):
			current_step = 0
			last_completed_step = -1
		else:
			current_step = (last_completed_step + 1) % combo_size
	else:
		current_step = 0
		last_completed_step = -1

	combo_buffered = false
	queued_combo_presses = 0
	_start_combo_step(0.0)

func _start_combo_step(charge_ratio: float = 0.0) -> void:
	combo_buffered = false
	attack_timer = player.weapon.get_step_duration(current_step) if player.weapon else 0.36
	
	# Allow reversing direction between combo steps if steering
	var input_dir: float = Input.get_axis("move_left", "move_right")
	if abs(input_dir) > 0.1:
		player.update_facing(input_dir)

	var is_upward: bool = player.is_upward_attack_requested()
	var is_downward: bool = player.is_crouch_requested()
	
	var weapon_type: String = player._detect_weapon_type_string(player.weapon)
	var is_melee_combo: bool = weapon_type in ["sword", "hammer", "dagger", "axe"]
	
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
		var base_impulse: float = player.weapon.get_step_impulse(current_step) if player.weapon else 80.0
		var forward_impulse: float = base_impulse * impulse_mult
		player.velocity.x = player.facing_direction * forward_impulse
		if player.hitbox.has_node("CollisionShape2D"):
			var hb_metrics: Dictionary = player.weapon.get_step_hitbox_metrics(current_step) if player.weapon else {"position": Vector2(20.0, -20.0), "size": Vector2(32.0, 28.0)}
			player.hitbox.get_node("CollisionShape2D").position = hb_metrics["position"]
			(player.hitbox.get_node("CollisionShape2D").shape as RectangleShape2D).size = hb_metrics["size"]
		player.hitbox.knockback_direction = Vector2(player.facing_direction, -0.2).normalized()

	# When on ground, clamp vertical speed to 0; when in air, leave gravity/fall speed completely untouched!
	if player.is_on_floor():
		player.velocity.y = 0.0

	# Setup active hitbox with scaling per combo step and charge ratio
	var step_mult: float = player.weapon.get_step_damage_multiplier(current_step) if player.weapon else (1.0 + (current_step * 0.25))
	var charge_mult: float = 1.0 + charge_ratio * (player.weapon.charge_damage_multiplier - 1.0)
	var total_mult: float = step_mult * charge_mult

	# Elixir de Folha-de-Fogo: +20% no primeiro ataque pós-esquiva
	if player.has_meta("has_post_roll_buff") and player.get_meta("has_post_roll_buff"):
		total_mult *= 1.20
		player.set_meta("has_post_roll_buff", false)

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

	# Dedicated combo animation on normal ground attack for melee weapons (sword, hammer, dagger, axe)
	if player.is_on_floor() and not is_upward and not is_downward and is_melee_combo:
		var anim_name: StringName = player.weapon.get_step_body_animation(current_step) if player.weapon else &"attack1"
		player.play_animation(anim_name)
		if player.player_sprite:
			player.player_sprite.frame = 0
			var target_duration: float = maxf(0.01, attack_timer)
			var frame_count: int = 5
			if player.player_sprite.sprite_frames and player.player_sprite.sprite_frames.has_animation(anim_name):
				frame_count = player.player_sprite.sprite_frames.get_frame_count(anim_name)
			var base_duration: float = float(frame_count) / 10.0
			player.player_sprite.speed_scale = base_duration / target_duration
			player._update_weapon_socket_for_frame(anim_name, 0)
	else:
		if player.player_sprite:
			player.player_sprite.speed_scale = 1.0

	player.set_slash_visual(true, current_step, is_upward, is_downward)

func exit() -> void:
	is_charging = false
	if player.player_sprite:
		player.player_sprite.speed_scale = 1.0
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

		# Slide / Dodge cancel during charge
		if player.is_slide_requested():
			is_charging = false
			last_completed_step = -1
			state_machine.transition_to("slide")
			return

		# Release button: UNLEASH CHARGED SMASH!
		if not Input.is_action_pressed("attack_primary"):
			is_charging = false
			_start_combo_step(charge_progress)
		return

	attack_timer -= delta
	
	# Dodge-cancel: can always slide out of an attack immediately!
	if player.is_slide_requested():
		last_completed_step = -1
		state_machine.transition_to("slide")
		return
		
	# Input queue / buffer: any tap during the swing queues the next combo hit!
	if Input.is_action_just_pressed("attack_primary"):
		combo_buffered = true
		queued_combo_presses = mini(3, queued_combo_presses + 1)
		
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
		last_completed_step = current_step
		
		var combo_size: int = player.weapon.get_combo_step_count() if player.weapon else 2
		var is_looping: bool = player.weapon.is_combo_looping() if player.weapon else true
		var can_advance: bool = is_looping or (current_step + 1 < combo_size)
		
		# Combo continuation condition (Dead Cells design):
		# 1. Player is holding the attack button (continuous auto-chain combo)
		# 2. Player tapped attack again during the swing (queued/buffered next hit)
		var wants_combo: bool = combo_buffered or queued_combo_presses > 0 or Input.is_action_pressed("attack_primary")
		
		if wants_combo and can_advance:
			if queued_combo_presses > 0:
				queued_combo_presses -= 1
			current_step = (current_step + 1) % combo_size
			_start_combo_step(0.0)
			return
			
		# Step completed without immediate continuation (or end of non-looping set):
		if not can_advance:
			player.attack_cooldown_timer = player.weapon.get_finisher_cooldown() if player.weapon else 0.0
			last_completed_step = -1
		else:
			player.attack_cooldown_timer = 0.0
		queued_combo_presses = 0
		
		if player.player_sprite:
			player.player_sprite.speed_scale = 1.0
			
		if player.is_on_floor():
			if abs(Input.get_axis("move_left", "move_right")) > 0.1:
				state_machine.transition_to("run")
			else:
				state_machine.transition_to("idle")
		else:
			state_machine.transition_to("fall")
