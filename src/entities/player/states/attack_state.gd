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

var _step_duration: float = 0.36
var _step_total_frames: int = 5
var _step_active_start_frame: int = 2
var _step_active_end_frame: int = 3
var _hitbox_opened_for_step: bool = false
var _pending_forward_impulse: float = 0.0
var _step_body_anim_active: bool = false

enum PlungePhase {
	PREP,
	FALL_LOOP,
	IMPACT,
	RECOVERY
}

var _is_plunge_active: bool = false
var _plunge_phase: PlungePhase = PlungePhase.PREP
var _plunge_timer: float = 0.0
var _plunge_loop_accum: float = 0.0
var _plunge_cur_frame: int = 0
var _plunge_prep_duration: float = 0.12
var _plunge_fall_speed: float = 420.0
var _plunge_loop_fps: float = 12.0
var _plunge_impact_duration: float = 0.20
var _plunge_recovery_duration: float = 0.14
var _plunge_loop_start: int = 1
var _plunge_loop_end: int = 3
var _plunge_impact_start: int = 4
var _plunge_impact_end: int = 5
var _plunge_recovery_frame: int = 6
var _plunge_triggered_in_air: bool = false

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
	var combo_window: float = player.weapon.get_combo_window(last_completed_step) if player.weapon else (COMBO_WINDOW * 0.5 if last_completed_step == 1 else COMBO_WINDOW)
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
	var is_airborne: bool = not player.is_on_floor()
	_step_duration = player.weapon.get_step_duration(current_step) if player.weapon else 0.36
	attack_timer = _step_duration
	_step_active_start_frame = player.weapon.get_step_active_start_frame(current_step, is_airborne) if player.weapon else (3 if current_step == 1 else 2)
	_step_active_end_frame = player.weapon.get_step_active_end_frame(current_step, is_airborne) if player.weapon else (4 if current_step == 1 else 3)
	_step_total_frames = 4 if (is_airborne and current_step == 0) else (6 if current_step >= 1 else 5)
	_hitbox_opened_for_step = false
	_pending_forward_impulse = 0.0
	_step_body_anim_active = false
	
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
			_pending_forward_impulse = 25.0
			player.velocity.x = player.facing_direction * 8.0
			if player.hitbox.has_node("CollisionShape2D"):
				player.hitbox.get_node("CollisionShape2D").position = Vector2(20.0, -10.0)
				(player.hitbox.get_node("CollisionShape2D").shape as RectangleShape2D).size = Vector2(32.0, 20.0)
			player.hitbox.knockback_direction = Vector2(player.facing_direction, -0.1).normalized()
	else:
		# Forward physical step synchronized with windup -> active slash release (Dead Cells / Blasphemous pattern)
		var impulse_mult: float = 1.0 + charge_ratio * 0.4
		var base_impulse: float = player.weapon.get_step_impulse(current_step) if player.weapon else 80.0
		var forward_impulse: float = base_impulse * impulse_mult
		_pending_forward_impulse = forward_impulse
		# Slight foot shift during windup; full lunge unleashes on the active slash frame!
		player.velocity.x = player.facing_direction * (forward_impulse * 0.25)
		if player.hitbox.has_node("CollisionShape2D"):
			var hb_metrics: Dictionary = player.weapon.get_step_hitbox_metrics(current_step, is_airborne) if player.weapon else {"position": Vector2(20.0, -20.0), "size": Vector2(32.0, 28.0)}
			player.hitbox.get_node("CollisionShape2D").position = hb_metrics["position"]
			(player.hitbox.get_node("CollisionShape2D").shape as RectangleShape2D).size = hb_metrics["size"]
		player.hitbox.knockback_direction = Vector2(player.facing_direction, -0.2).normalized()

	# When on ground, clamp vertical speed to 0; when in air, leave gravity/fall speed completely untouched!
	if player.is_on_floor():
		player.velocity.y = 0.0

	# Setup active hitbox metrics with scaling per combo step and charge ratio
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
	
	# Keep Hitbox OFF during Windup frames! It will activate on _step_active_start_frame.
	player.hitbox.set_active(false)
	_is_plunge_active = false

	# Dedicated combo animation on normal ground and air attacks for melee weapons (sword, hammer, dagger, axe)
	if not is_upward and not is_downward and is_melee_combo:
		var anim_name: StringName = player.weapon.get_step_body_animation(current_step, is_airborne) if player.weapon else (&"air_attack1" if is_airborne else &"attack1")
		if player.player_sprite and player.player_sprite.sprite_frames and not player.player_sprite.sprite_frames.has_animation(anim_name):
			# Fallback seguro: se air_attack2 / air_attack3 ainda não estiverem no SpriteFrames, usa a animação do chão correspondente (ou air_attack1)
			var ground_fallback: StringName = player.weapon.get_step_body_animation(current_step, false) if player.weapon else &"attack1"
			if player.player_sprite.sprite_frames.has_animation(ground_fallback):
				anim_name = ground_fallback
			elif player.player_sprite.sprite_frames.has_animation(&"air_attack1"):
				anim_name = &"air_attack1"
			else:
				anim_name = &"attack1"

		# Check if this airborne melee attack uses the 4-phase Plunge / Dive state machine (e.g. Hammer in air_attack3)
		if is_airborne and player.weapon and player.weapon.is_step_air_plunge(current_step) and anim_name == &"air_attack3":
			_start_air_plunge(anim_name)
			return

		player.play_animation(anim_name)
		_step_body_anim_active = true
		if player.player_sprite:
			player.player_sprite.frame = 0
			var target_duration: float = maxf(0.01, attack_timer)
			var frame_count: int = 5
			var total_duration_units: float = 5.0
			var anim_fps: float = 10.0
			if player.player_sprite.sprite_frames and player.player_sprite.sprite_frames.has_animation(anim_name):
				frame_count = player.player_sprite.sprite_frames.get_frame_count(anim_name)
				anim_fps = maxf(1.0, player.player_sprite.sprite_frames.get_animation_speed(anim_name))
				total_duration_units = 0.0
				for i in range(frame_count):
					total_duration_units += player.player_sprite.sprite_frames.get_frame_duration(anim_name, i)
			_step_total_frames = maxi(1, frame_count)
			var base_duration: float = total_duration_units / anim_fps
			player.player_sprite.speed_scale = base_duration / target_duration
			player._update_weapon_socket_for_frame(anim_name, 0)
	else:
		if player.player_sprite:
			player.player_sprite.speed_scale = 1.0

	player.set_slash_visual(true, current_step, is_upward, is_downward)
	_update_active_hitbox_window()

func exit() -> void:
	is_charging = false
	_is_plunge_active = false
	if player and player.hitbox and player.hitbox.hit_landed.is_connected(_on_plunge_hit_landed):
		player.hitbox.hit_landed.disconnect(_on_plunge_hit_landed)
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

	if _is_plunge_active:
		_update_air_plunge(delta)
		return

	attack_timer -= delta
	_update_active_hitbox_window()
	
	# Dodge-cancel: allowed during Windup (spin 0..1) and final Recovery pause (frame 5), blocked only during the Slash frames (2..4)!
	var can_dodge_cancel: bool = true
	var cur_frame: int = _get_current_attack_frame()
	if player.weapon and player.weapon.is_step_dodge_locked_after_windup(current_step):
		if cur_frame >= _step_active_start_frame and cur_frame < (_step_total_frames - 1):
			can_dodge_cancel = false
	elif not player.weapon and current_step >= 2:
		if cur_frame >= _step_active_start_frame and cur_frame < (_step_total_frames - 1):
			can_dodge_cancel = false

	if can_dodge_cancel and player.is_slide_requested():
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

func _get_current_attack_frame() -> int:
	if _step_body_anim_active and player.player_sprite and player.player_sprite.visible:
		return player.player_sprite.frame
	if player.slash_effect and player.slash_effect.visible and player.slash_effect is AnimatedSprite2D:
		return (player.slash_effect as AnimatedSprite2D).frame
	var elapsed: float = clampf(_step_duration - attack_timer, 0.0, _step_duration)
	var ratio: float = elapsed / maxf(0.01, _step_duration)
	return mini(_step_total_frames - 1, int(floor(ratio * float(_step_total_frames))))

func _update_active_hitbox_window() -> void:
	if not player or not player.hitbox:
		return
	var cur_frame: int = _get_current_attack_frame()
	if cur_frame >= _step_active_start_frame and not _hitbox_opened_for_step:
		_hitbox_opened_for_step = true
		player.hitbox.set_active(true)
		# Apply full forward lunge at the exact moment the blade/slash unleashes!
		if _pending_forward_impulse > 0.0:
			player.velocity.x = player.facing_direction * _pending_forward_impulse
	elif _hitbox_opened_for_step and cur_frame > _step_active_end_frame and player.hitbox.monitoring:
		player.hitbox.set_active(false)

func _start_air_plunge(anim_name: StringName) -> void:
	_is_plunge_active = true
	_step_body_anim_active = true
	var step_data: ComboStepData = player.weapon.get_step_data(current_step) if player.weapon else null
	_plunge_prep_duration = step_data.plunge_prep_duration if step_data else 0.12
	_plunge_fall_speed = step_data.plunge_fall_speed if step_data else 420.0
	_plunge_loop_fps = step_data.plunge_loop_fps if step_data else 12.0
	_plunge_impact_duration = step_data.plunge_impact_duration if step_data else 0.20
	_plunge_recovery_duration = step_data.plunge_recovery_duration if step_data else 0.14
	_plunge_loop_start = step_data.plunge_loop_start_frame if step_data else 1
	_plunge_loop_end = step_data.plunge_loop_end_frame if step_data else 3
	_plunge_impact_start = step_data.plunge_impact_start_frame if step_data else 4
	_plunge_impact_end = step_data.plunge_impact_end_frame if step_data else 5
	_plunge_recovery_frame = step_data.plunge_recovery_frame if step_data else 6

	_plunge_phase = PlungePhase.PREP
	_plunge_timer = _plunge_prep_duration
	_plunge_loop_accum = 0.0
	_plunge_cur_frame = 0
	_plunge_triggered_in_air = false

	# Brief mid-air suspension during Frame 0 windup
	player.velocity.x *= 0.35
	player.velocity.y = minf(player.velocity.y, 35.0)

	player.hitbox.set_active(false)
	player.set_slash_visual(false, 0, false, false)

	if player.hitbox and not player.hitbox.hit_landed.is_connected(_on_plunge_hit_landed):
		player.hitbox.hit_landed.connect(_on_plunge_hit_landed)

	player.play_animation(anim_name)
	if player.player_sprite:
		player.player_sprite.pause()
		player.player_sprite.frame = 0
		player.player_sprite.speed_scale = 1.0
		player._update_weapon_socket_for_frame(anim_name, 0)

func _on_plunge_hit_landed(_hurtbox: Hurtbox) -> void:
	if not _is_plunge_active:
		return
	if _plunge_phase == PlungePhase.FALL_LOOP:
		# Enemy touched during fall loop: immediately trigger Frames 4 & 5 (the strike!) with mid-air brake!
		_enter_plunge_impact(not player.is_on_floor())

func _enter_plunge_impact(in_midair: bool) -> void:
	if _plunge_phase == PlungePhase.IMPACT or _plunge_phase == PlungePhase.RECOVERY:
		return
	_plunge_phase = PlungePhase.IMPACT
	_plunge_triggered_in_air = in_midair
	_plunge_timer = _plunge_impact_duration
	_plunge_cur_frame = _plunge_impact_start

	if in_midair:
		# Opção 1: Freio no ar curto para executar os frames 4 e 5 na altura do inimigo, sem flutuar infinitamente!
		player.velocity.y = 0.0
		player.velocity.x = player.facing_direction * (_pending_forward_impulse * 0.45)
	else:
		player.velocity.y = 0.0
		player.velocity.x = player.facing_direction * _pending_forward_impulse

	# Posiciona e ativa a Hitbox do golpe (frames 4 e 5) preservando alvos já atingidos no mergulho para evitar hit duplo
	if player.hitbox.has_node("CollisionShape2D"):
		var hb_metrics: Dictionary = player.weapon.get_step_hitbox_metrics(current_step, in_midair) if player.weapon else {"position": Vector2(21.0, -20.0), "size": Vector2(36.0, 32.0)}
		player.hitbox.get_node("CollisionShape2D").position = hb_metrics["position"]
		(player.hitbox.get_node("CollisionShape2D").shape as RectangleShape2D).size = hb_metrics["size"]
	player.hitbox.knockback_direction = Vector2(player.facing_direction, -0.2).normalized()
	if not player.hitbox.monitoring:
		player.hitbox.set_active(true)

	if player.player_sprite:
		player.player_sprite.pause()
		player.player_sprite.frame = _plunge_cur_frame
		player._update_weapon_socket_for_frame(player.player_sprite.animation, _plunge_cur_frame)

	player.set_slash_visual(true, current_step, false, false)

func _update_air_plunge(delta: float) -> void:
	# Allow dodge-cancel during PREP, FALL_LOOP, and final RECOVERY (locked only during IMPACT strike frames 4..5)
	if _plunge_phase != PlungePhase.IMPACT and player.is_slide_requested():
		_is_plunge_active = false
		if player.hitbox and player.hitbox.hit_landed.is_connected(_on_plunge_hit_landed):
			player.hitbox.hit_landed.disconnect(_on_plunge_hit_landed)
		last_completed_step = -1
		state_machine.transition_to("slide")
		return

	match _plunge_phase:
		PlungePhase.PREP:
			_plunge_timer -= delta
			player.velocity.y = move_toward(player.velocity.y, 60.0, 400.0 * delta)
			player.move_and_slide()
			if player.is_on_floor():
				_enter_plunge_impact(false)
				return
			if _plunge_timer <= 0.0:
				_plunge_phase = PlungePhase.FALL_LOOP
				_plunge_cur_frame = _plunge_loop_start
				_plunge_loop_accum = 0.0
				# Ativa a Hitbox de descida posicionada embaixo/frente acompanhando a cabeça do martelo
				if player.hitbox.has_node("CollisionShape2D"):
					player.hitbox.get_node("CollisionShape2D").position = Vector2(10.0, -6.0)
					(player.hitbox.get_node("CollisionShape2D").shape as RectangleShape2D).size = Vector2(34.0, 28.0)
				player.hitbox.knockback_direction = Vector2(player.facing_direction * 0.5, 0.85).normalized()
				player.hitbox.set_active(false)
				player.hitbox.set_active(true)
				if player.player_sprite:
					player.player_sprite.pause()
					player.player_sprite.frame = _plunge_cur_frame
					player._update_weapon_socket_for_frame(player.player_sprite.animation, _plunge_cur_frame)

		PlungePhase.FALL_LOOP:
			# Continua caindo e ciclando entre os frames de loop enquanto não toca em ninguém nem chega no chão
			var input_dir: float = Input.get_axis("move_left", "move_right")
			player.velocity.x = move_toward(player.velocity.x, input_dir * (player.run_speed * 0.45), 500.0 * delta)
			player.velocity.y = maxf(player.velocity.y + (player.gravity * player.fall_gravity_multiplier) * delta, _plunge_fall_speed)
			player.move_and_slide()

			# Caso hit_landed tenha disparado durante move_and_slide(), _plunge_phase já mudou para IMPACT
			if _plunge_phase != PlungePhase.FALL_LOOP:
				return

			if player.is_on_floor():
				_enter_plunge_impact(false)
				return

			_plunge_loop_accum += delta * _plunge_loop_fps
			if _plunge_loop_accum >= 1.0:
				_plunge_loop_accum -= 1.0
				_plunge_cur_frame += 1
				if _plunge_cur_frame > _plunge_loop_end:
					_plunge_cur_frame = _plunge_loop_start
				if player.player_sprite:
					player.player_sprite.frame = _plunge_cur_frame
					player._update_weapon_socket_for_frame(player.player_sprite.animation, _plunge_cur_frame)

		PlungePhase.IMPACT:
			_plunge_timer -= delta
			var progress: float = 1.0 - clampf(_plunge_timer / maxf(0.01, _plunge_impact_duration), 0.0, 1.0)
			var impact_frame_span: int = maxi(1, _plunge_impact_end - _plunge_impact_start + 1)
			var target_frame: int = clampi(_plunge_impact_start + int(floor(progress * float(impact_frame_span))), _plunge_impact_start, _plunge_impact_end)
			if target_frame != _plunge_cur_frame:
				_plunge_cur_frame = target_frame
				if player.player_sprite:
					player.player_sprite.frame = _plunge_cur_frame
					player._update_weapon_socket_for_frame(player.player_sprite.animation, _plunge_cur_frame)

			if player.is_on_floor():
				player.velocity.x = move_toward(player.velocity.x, 0.0, 700.0 * delta)
			else:
				# Freio no ar durante os frames 4 e 5 (gravidade amortecida em 20% por apenas ~0.20s)
				player.velocity.x = move_toward(player.velocity.x, 0.0, 500.0 * delta)
				player.velocity.y += (player.gravity * 0.20) * delta

			player.move_and_slide()

			if _plunge_timer <= 0.0:
				_plunge_phase = PlungePhase.RECOVERY
				_plunge_timer = _plunge_recovery_duration
				_plunge_cur_frame = _plunge_recovery_frame
				player.hitbox.set_active(false)
				player.set_slash_visual(false, 0, false, false)
				if player.player_sprite:
					player.player_sprite.frame = _plunge_cur_frame
					player._update_weapon_socket_for_frame(player.player_sprite.animation, _plunge_cur_frame)

		PlungePhase.RECOVERY:
			_plunge_timer -= delta
			if player.is_on_floor():
				player.velocity.x = move_toward(player.velocity.x, 0.0, 800.0 * delta)
			else:
				# Gravidade normal retomada imediatamente na finalização para não flutuar no ar!
				player.velocity.y += (player.gravity * player.fall_gravity_multiplier) * delta
			player.move_and_slide()

			if _plunge_timer <= 0.0:
				_is_plunge_active = false
				if player.hitbox and player.hitbox.hit_landed.is_connected(_on_plunge_hit_landed):
					player.hitbox.hit_landed.disconnect(_on_plunge_hit_landed)
				player.hitbox.set_active(false)
				player.set_slash_visual(false, 0, false, false)
				last_attack_end_msec = Time.get_ticks_msec()
				last_completed_step = current_step
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
