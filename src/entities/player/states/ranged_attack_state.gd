class_name RangedAttackState
extends State

## Ranged Attack State for Bow and Crossbow:
## Implements continuous fire (holding button to continuously loose arrows/bolts),
## charge mechanics for charge weapons/spells, directional aiming, and tactical recovery.

const DEFAULT_PROJECTILE_SCENE: PackedScene = preload("res://src/combat/projectile.tscn")

var player: Player

var attack_phase: int = 0 # 0: Aim/Draw/Channeling, 1: Spell Cast Windup->Release, 2: Recovery/Reload
var phase_timer: float = 0.0
var charge_progress: float = 0.0
var has_fired: bool = false
var _cast_total_duration: float = 0.36
var _charge_base_weapon_scale: Vector2 = Vector2.ONE
var _is_bow_repeat_shot: bool = false
var _bow_released_early: bool = false
var _bow_anim_name: StringName = &"bow_attack"

func enter() -> void:
	player = character as Player
	if not player.weapon:
		_exit_to_movement()
		return

	var is_spell: bool = player.weapon.weapon_category == WeaponData.WeaponCategory.RANGED_SPELL
	if not is_spell and player.main_weapon_instance and player.weapon.get_socket_profile() == null:
		player.main_weapon_instance.position = player.weapon.attack_visual_offset
		player.main_weapon_instance.rotation_degrees = player.weapon.attack_visual_rotation_degrees
	_charge_base_weapon_scale = player.main_weapon_instance.scale if player.main_weapon_instance else Vector2.ONE

	_start_shot_cycle(false)

func _start_shot_cycle(is_repeat: bool = false) -> void:
	has_fired = false
	charge_progress = 0.0
	phase_timer = 0.0
	_is_bow_repeat_shot = is_repeat
	_bow_released_early = false

	var is_spell: bool = player.weapon.weapon_category == WeaponData.WeaponCategory.RANGED_SPELL

	# Crossbow fires instantly on trigger; if charge weapon is airborne and not chargeable_in_the_air, fire/cast immediately!
	var skip_air_charge: bool = player.weapon.is_charge_attack and (not player.is_on_floor()) and (not player.weapon.chargeable_in_the_air)
	if player.weapon.weapon_category == WeaponData.WeaponCategory.RANGED_CROSSBOW:
		var cb_anim: StringName = &"crossbow_attack" if player.is_on_floor() else &"crossbow_air_attack"
		attack_phase = 0
		player.play_animation(cb_anim)
		if player.player_sprite:
			player.player_sprite.pause()
			player.player_sprite.frame = 0
		player._update_weapon_socket_for_frame(cb_anim, 0)
	elif is_spell:
		if skip_air_charge:
			_start_spell_cast()
		else:
			attack_phase = 0
			if player.player_sprite:
				player.player_sprite.speed_scale = 1.0
			player.play_animation(&"channeling")
			player._update_weapon_socket_for_frame(&"channeling", 0)
	else:
		if skip_air_charge:
			_fire_projectile()
		else:
			attack_phase = 0
			if player.weapon.weapon_category == WeaponData.WeaponCategory.RANGED_BOW:
				_bow_anim_name = &"bow_attack" if player.is_on_floor() else &"bow_air_attack"
				var start_frame: int = 2 if _is_bow_repeat_shot else 0
				player.play_animation(_bow_anim_name)
				if player.player_sprite:
					player.player_sprite.pause()
					player.player_sprite.frame = start_frame
				player._update_weapon_socket_for_frame(_bow_anim_name, start_frame)
			else:
				if player.main_hand_socket:
					player.main_hand_socket.rotation_degrees = 0.0

func exit() -> void:
	has_fired = false
	if player and player.weapon and player.weapon.is_charge_attack:
		CombatFeedback.stop_rumble()
	if player.player_sprite:
		player.player_sprite.speed_scale = 1.0
	# Restore resting grip stance (visual_offset and visual_rotation_degrees)
	if player.weapon and player.main_weapon_instance:
		var has_socket_profile: bool = player.weapon.get_socket_profile() != null
		player.main_weapon_instance.position = Vector2.ZERO if has_socket_profile else player.weapon.visual_offset
		player.main_weapon_instance.rotation_degrees = 0.0 if has_socket_profile else player.weapon.visual_rotation_degrees
		player.clear_weapon_energize(_charge_base_weapon_scale)
	elif player:
		player.clear_weapon_energize(_charge_base_weapon_scale)
	if player.main_hand_socket:
		player.main_hand_socket.rotation_degrees = -35.0

func physics_update(delta: float) -> void:
	# Gravity in air
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
	else:
		player.velocity.y = 0.0

	var is_spell: bool = player.weapon.weapon_category == WeaponData.WeaponCategory.RANGED_SPELL

	match attack_phase:
		0:
			# Slide / Dodge cancel while channeling or aiming
			if player.is_slide_requested():
				state_machine.transition_to("slide")
				return

			# Drawing / Charging / Channeling
			var charge_duration: float = player.weapon.max_charge_time if player.weapon.is_charge_attack else player.weapon.charge_time
			charge_progress = minf(1.0, charge_progress + delta / maxf(0.05, charge_duration))

			# Tremor feedback flag
			var jitter: float = 0.0
			if player.weapon.charge_has_tremor:
				jitter = (randf() - 0.5) * 4.5 * charge_progress

			if is_spell:
				if player.player_sprite and player.player_sprite.animation != &"channeling":
					player.play_animation(&"channeling")
				if player.main_weapon_instance:
					player.main_weapon_instance.rotation_degrees = jitter
			elif player.weapon.weapon_category == WeaponData.WeaponCategory.RANGED_BOW:
				var draw_max: int = 3 if _bow_anim_name == &"bow_air_attack" else 4
				var start_f: int = 2 if _is_bow_repeat_shot else 0
				var span: float = float((draw_max + 1) - start_f)
				var draw_frame: int = clampi(start_f + int(floor(charge_progress * span)), start_f, draw_max)
				if player.player_sprite:
					var anim_switched: bool = player.player_sprite.animation != _bow_anim_name
					if anim_switched:
						player.play_animation(_bow_anim_name)
						player.player_sprite.pause()
					if anim_switched or player.player_sprite.frame != draw_frame:
						player.player_sprite.frame = draw_frame
						player._update_weapon_socket_for_frame(_bow_anim_name, draw_frame)
			else:
				if player.main_hand_socket and player.weapon.get_socket_profile() == null:
					player.main_hand_socket.rotation_degrees = jitter

			# Energizing glow & particle FX controlled by WeaponData's EnergizeProfile
			player.update_weapon_energize(charge_progress, _charge_base_weapon_scale)
			if player.weapon.is_charge_attack:
				CombatFeedback.update_charge_rumble(charge_progress)

			# Planted stance while aiming/charging on floor (matches Dead Cells bow/spell lock)
			if player.is_on_floor():
				var move_dir := Input.get_axis(&"move_left", &"move_right")
				player.velocity.x = move_toward(player.velocity.x, 0.0, 800.0 * delta)
				if move_dir != 0.0:
					player.update_facing(move_dir)
			else:
				player.velocity.x = move_toward(player.velocity.x, 0.0, 300.0 * delta)

			player.move_and_slide()

			# Determine when to loose projectile or start spell cast:
			if player.weapon.is_charge_attack:
				if not Input.is_action_pressed(&"attack_primary"):
					CombatFeedback.stop_rumble()
					if is_spell:
						_start_spell_cast()
					else:
						_fire_projectile()
			elif player.weapon.weapon_category == WeaponData.WeaponCategory.RANGED_BOW:
				if not Input.is_action_pressed(&"attack_primary"):
					_bow_released_early = true
				# Bow always reaches the penultimate frame (frame 5 / 1-based frame 6) to shoot!
				if charge_progress >= 1.0:
					_fire_projectile()
			else:
				if charge_progress >= 1.0 or not Input.is_action_pressed(&"attack_primary"):
					if is_spell:
						_start_spell_cast()
					else:
						_fire_projectile()

		1:
			# Spell Cast animation phase (4 frames: 0, 1, 2 -> fires projectile on frame 3!)
			if player.is_slide_requested():
				state_machine.transition_to("slide")
				return

			phase_timer -= delta
			player.velocity.x = move_toward(player.velocity.x, 0.0, 700.0 * delta)
			player.move_and_slide()

			var cur_frame: int = player.player_sprite.frame if player.player_sprite else 3
			if not has_fired and (cur_frame >= 3 or phase_timer <= _cast_total_duration * 0.25):
				_fire_projectile(false)

			if phase_timer <= 0.0:
				if not has_fired:
					_fire_projectile(false)
				attack_phase = 2
				phase_timer = player.weapon.reload_time

		2:
			# Recovery / Reload phase
			phase_timer -= delta
			if player.weapon and player.weapon.weapon_category == WeaponData.WeaponCategory.RANGED_BOW and player.player_sprite:
				var shoot_f: int = 4 if _bow_anim_name == &"bow_air_attack" else 5
				var rec_f: int = shoot_f + 1
				var rec_frame: int = rec_f if phase_timer <= (player.weapon.reload_time * 0.5) else shoot_f
				if player.player_sprite.frame != rec_frame:
					player.player_sprite.frame = rec_frame
					player._update_weapon_socket_for_frame(_bow_anim_name, rec_frame)
			elif player.weapon and player.weapon.weapon_category == WeaponData.WeaponCategory.RANGED_CROSSBOW and player.player_sprite and player.player_sprite.animation in [&"crossbow_attack", &"crossbow_air_attack"]:
				var cb_anim: StringName = player.player_sprite.animation
				var cb_frame: int = 2 if phase_timer <= (player.weapon.reload_time * 0.5) else 1
				if player.player_sprite.frame != cb_frame:
					player.player_sprite.frame = cb_frame
					player._update_weapon_socket_for_frame(cb_anim, cb_frame)
			player.velocity.x = move_toward(player.velocity.x, 0.0, 700.0 * delta)
			player.move_and_slide()

			# Slide cancel during reload
			if player.is_slide_requested():
				state_machine.transition_to("slide")
				return

			# Guard cancel during reload
			if Input.is_action_just_pressed(&"defend") and player.can_defend():
				state_machine.transition_to("guard")
				return

			if phase_timer <= 0.0:
				if Input.is_action_pressed(&"attack_primary") and not player.weapon.is_charge_attack and not _bow_released_early:
					# Keep firing while holding attack (Bow cycles from ready frame 2 -> shoot frame 5)!
					_start_shot_cycle(true)
				else:
					_exit_to_movement()

func _start_spell_cast() -> void:
	attack_phase = 1
	has_fired = false
	_cast_total_duration = 0.36
	phase_timer = _cast_total_duration
	if player.main_weapon_instance:
		player.main_weapon_instance.rotation_degrees = 0.0
	player.play_animation(&"cast")
	if player.player_sprite:
		player.player_sprite.frame = 0
		var frame_count: int = 4
		var fps: float = 10.0
		if player.player_sprite.sprite_frames and player.player_sprite.sprite_frames.has_animation(&"cast"):
			frame_count = player.player_sprite.sprite_frames.get_frame_count(&"cast")
			fps = maxf(1.0, player.player_sprite.sprite_frames.get_animation_speed(&"cast"))
		var base_dur: float = float(frame_count) / fps
		player.player_sprite.speed_scale = base_dur / maxf(0.05, _cast_total_duration)
		player._update_weapon_socket_for_frame(&"cast", 0)

func _fire_projectile(advance_to_recovery: bool = true) -> void:
	if has_fired:
		return
	has_fired = true
	if advance_to_recovery:
		attack_phase = 2 # Enter recovery/reload

	# Reset visual charge aura and spawn release burst upon discharge
	player.trigger_weapon_energize_release()
	player.clear_weapon_energize(_charge_base_weapon_scale)
	if player.main_weapon_instance:
		player.main_weapon_instance.rotation_degrees = 0.0

	var weapon := player.weapon
	var is_spell: bool = weapon.weapon_category == WeaponData.WeaponCategory.RANGED_SPELL
	var proj_scene: PackedScene = weapon.projectile_scene if weapon.projectile_scene else DEFAULT_PROJECTILE_SCENE
	if not proj_scene:
		_exit_to_movement()
		return

	var is_bow: bool = weapon.weapon_category == WeaponData.WeaponCategory.RANGED_BOW
	var is_crossbow: bool = weapon.weapon_category == WeaponData.WeaponCategory.RANGED_CROSSBOW
	if is_bow and player.player_sprite:
		var shoot_frame: int = 4 if _bow_anim_name == &"bow_air_attack" else 5
		player.play_animation(_bow_anim_name)
		player.player_sprite.pause()
		player.player_sprite.frame = shoot_frame
		player._update_weapon_socket_for_frame(_bow_anim_name, shoot_frame)
	elif is_crossbow and player.player_sprite:
		var cb_anim: StringName = &"crossbow_attack" if player.is_on_floor() else &"crossbow_air_attack"
		player.play_animation(cb_anim)
		player.player_sprite.pause()
		player.player_sprite.frame = 1
		player._update_weapon_socket_for_frame(cb_anim, 1)

	# Player ranged shots always fire straight horizontally
	var shoot_dir := Vector2(float(player.facing_direction), 0.0)
	if player.main_hand_socket and not is_spell and not is_bow and weapon.get_socket_profile() == null:
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

	# Firing recoil & tactile feedback (Bows and Staffs keep player planted; Crossbow has heavy kickback)
	var recoil_force: float = 120.0 if weapon.weapon_category == WeaponData.WeaponCategory.RANGED_CROSSBOW else 0.0
	if recoil_force > 0.0:
		player.velocity.x = -player.facing_direction * recoil_force
	else:
		player.velocity.x = 0.0
	if not weapon.is_charge_attack:
		CombatFeedback.apply_hit_feedback(0.04, weapon.rumble_weak, weapon.rumble_strong, weapon.rumble_duration)

	# Set reload/recovery cadence
	if advance_to_recovery:
		phase_timer = weapon.reload_time

func _exit_to_movement() -> void:
	if not player.is_on_floor():
		state_machine.transition_to("fall")
	else:
		var dir := Input.get_axis(&"move_left", &"move_right")
		if abs(dir) > 0.1:
			state_machine.transition_to("run")
		else:
			state_machine.transition_to("idle")
