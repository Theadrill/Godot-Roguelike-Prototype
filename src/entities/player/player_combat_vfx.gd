class_name PlayerCombatVFX
extends RefCounted

## Sub-controlador modular de VFX de combate do Player (SlashEffect, Energize, Ground Impact e Pickup Burst).
## Mantém paridade matemática 1:1 com o WeaponSocketCalibrator para posicionamento e escala do Slash.

var _player: CharacterBody2D = null

var _slash_combo_step: int = 0
var _slash_is_upward: bool = false
var _slash_is_downward: bool = false
var _slash_is_airborne: bool = false

var _active_energize_particles: Node2D = null
var _slash_shader_mat: ShaderMaterial = null
var _pickup_effect_profile: PickupEffectProfile = null
var _item_pickup_base_scale: Vector2 = Vector2.ONE
var _pickup_fx_tween: Tween = null


func setup(player_ref: CharacterBody2D) -> void:
	_player = player_ref


func set_slash_visual(is_active: bool, combo_step: int = 0, is_upward: bool = false, is_downward: bool = false, charge_ratio: float = 0.0) -> void:
	var slash_effect: AnimatedSprite2D = _player.slash_effect
	if not slash_effect:
		return

	var weapon: WeaponData = _player.weapon
	if not is_active or not weapon or not weapon.slash_enabled:
		slash_effect.visible = false
		if slash_effect.is_playing():
			slash_effect.stop()
		apply_slash_energize_shader(0.0)
		return

	var is_airborne: bool = not _player.is_on_floor()

	var target_frames: SpriteFrames = weapon.slash_custom_frames if weapon.slash_custom_frames else (_player.default_slash_frames as SpriteFrames)
	if target_frames and slash_effect.sprite_frames != target_frames:
		slash_effect.sprite_frames = target_frames

	var anim_name: StringName = weapon.get_step_slash_animation(combo_step, is_airborne) if weapon else &"slash_attack1"
	if slash_effect.sprite_frames and not slash_effect.sprite_frames.has_animation(anim_name):
		anim_name = weapon.get_step_slash_animation(combo_step, false) if weapon else &"slash_attack1"
	if slash_effect.sprite_frames and not slash_effect.sprite_frames.has_animation(anim_name):
		anim_name = weapon.slash_animation if (weapon and weapon.slash_animation) else &"slash_attack1"
	if slash_effect.sprite_frames and slash_effect.sprite_frames.has_animation(anim_name):
		slash_effect.animation = anim_name
		slash_effect.frame = 0
		var step_dur: float = weapon.get_step_duration(combo_step) if weapon else 0.36
		var slash_frame_count: int = maxi(1, slash_effect.sprite_frames.get_frame_count(anim_name))
		var slash_fps: float = maxf(1.0, slash_effect.sprite_frames.get_animation_speed(anim_name))
		var total_slash_units: float = 0.0
		for i in range(slash_frame_count):
			total_slash_units += slash_effect.sprite_frames.get_frame_duration(anim_name, i)
		var base_slash_dur: float = total_slash_units / slash_fps
		slash_effect.speed_scale = base_slash_dur / maxf(0.05, step_dur)
		slash_effect.play(anim_name)

	slash_effect.flip_h = weapon.get_step_slash_flip_h(combo_step) if weapon else false
	slash_effect.flip_v = weapon.get_step_slash_flip_v(combo_step) if weapon else false

	_slash_combo_step = combo_step
	_slash_is_upward = is_upward
	_slash_is_downward = is_downward
	_slash_is_airborne = is_airborne
	var custom_mod: Color = weapon.slash_modulate if weapon else Color.WHITE
	var custom_z: int = weapon.slash_z_index if weapon else 4
	update_slash_frame_transform(0)

	slash_effect.modulate = custom_mod
	slash_effect.z_index = custom_z
	apply_slash_energize_shader(charge_ratio)
	slash_effect.visible = true

	if _player.main_hand_socket:
		if is_active:
			if is_upward:
				_player.main_hand_socket.rotation_degrees = -90.0
			elif is_downward:
				_player.main_hand_socket.rotation_degrees = 90.0
		else:
			_player.main_hand_socket.rotation_degrees = -35.0


func on_slash_effect_frame_changed() -> void:
	if _player.slash_effect and _player.slash_effect.visible:
		update_slash_frame_transform(_player.slash_effect.frame)


func update_slash_frame_transform(frame_idx: int) -> void:
	var slash_effect: AnimatedSprite2D = _player.slash_effect
	if not slash_effect or not is_instance_valid(slash_effect):
		return
	var base_pos: Vector2 = _player.player_sprite.position if _player.player_sprite else Vector2(-2, -29)
	var weapon: WeaponData = _player.weapon
	var custom_offset: Vector2 = weapon.get_step_total_slash_offset(_slash_combo_step, _slash_is_airborne, frame_idx) if weapon else Vector2.ZERO
	var custom_scale: Vector2 = weapon.get_step_total_slash_scale(_slash_combo_step, _slash_is_airborne, frame_idx) if weapon else Vector2.ONE

	if _slash_is_upward:
		slash_effect.position = base_pos + Vector2(0.0, -8.0) + custom_offset
		slash_effect.rotation_degrees = -90.0
		slash_effect.scale = custom_scale * 1.1
	elif _slash_is_downward:
		slash_effect.position = base_pos + Vector2(4.0, 10.0) + custom_offset
		slash_effect.rotation_degrees = 90.0
		slash_effect.scale = custom_scale * 1.1
	else:
		slash_effect.position = base_pos + custom_offset
		slash_effect.rotation_degrees = 0.0
		slash_effect.scale = custom_scale


func apply_slash_energize_shader(charge_ratio: float) -> void:
	var slash_effect: AnimatedSprite2D = _player.slash_effect
	if not slash_effect:
		return
	if not _slash_shader_mat:
		var sh := load("res://src/combat/slash_colorize.gdshader") as Shader
		if sh:
			_slash_shader_mat = ShaderMaterial.new()
			_slash_shader_mat.shader = sh
			slash_effect.material = _slash_shader_mat
	if not _slash_shader_mat:
		return
	var weapon: WeaponData = _player.weapon
	if weapon and weapon.charge_has_energize and charge_ratio > 0.0:
		var prof: EnergizeProfile = weapon.get_energize_profile()
		if prof and prof.tint_slash:
			_slash_shader_mat.set_shader_parameter("tint_color", prof.glow_color)
			var strength: float = prof.slash_tint_strength * clampf(0.35 + charge_ratio * 0.65, 0.0, 1.0)
			_slash_shader_mat.set_shader_parameter("tint_strength", strength)
			return
	_slash_shader_mat.set_shader_parameter("tint_strength", 0.0)


func update_weapon_energize(charge_progress: float, base_scale: Vector2) -> void:
	var main_inst: Node2D = _player.main_weapon_instance
	if not main_inst or not is_instance_valid(main_inst):
		return
	var weapon: WeaponData = _player.weapon
	if not weapon or not weapon.charge_has_energize:
		clear_weapon_energize(base_scale)
		return
	var prof: EnergizeProfile = weapon.get_energize_profile()
	if prof:
		main_inst.modulate = prof.compute_modulate(charge_progress)
		main_inst.scale = prof.compute_scale(base_scale, charge_progress)
		if prof.particle_scene and _player.main_hand_socket:
			if not _active_energize_particles or not is_instance_valid(_active_energize_particles):
				var p_inst := prof.particle_scene.instantiate() as Node2D
				if p_inst:
					_player.main_hand_socket.add_child(p_inst)
					p_inst.position = weapon.energize_offset
					_active_energize_particles = p_inst
			else:
				_active_energize_particles.position = weapon.energize_offset
	else:
		main_inst.modulate = Color.WHITE
		main_inst.scale = base_scale


func trigger_weapon_energize_release() -> void:
	var weapon: WeaponData = _player.weapon
	if not weapon or not weapon.charge_has_energize:
		return
	var prof: EnergizeProfile = weapon.get_energize_profile()
	if not prof or not prof.release_particle_scene:
		return
	var burst := prof.release_particle_scene.instantiate() as Node2D
	if not burst:
		return
	var spawn_parent: Node = _player.get_tree().current_scene if (_player.get_tree() and _player.get_tree().current_scene) else _player.get_parent()
	if not spawn_parent:
		burst.queue_free()
		return
	var world_pos: Vector2 = _player.main_hand_socket.to_global(weapon.energize_offset) if _player.main_hand_socket else _player.global_position
	spawn_parent.add_child(burst)
	burst.global_position = world_pos
	burst.z_index = 5


func stop_weapon_energize_particles() -> void:
	if _active_energize_particles and is_instance_valid(_active_energize_particles):
		_active_energize_particles.queue_free()
	_active_energize_particles = null


func clear_weapon_energize(base_scale: Vector2) -> void:
	var main_inst: Node2D = _player.main_weapon_instance
	if main_inst and is_instance_valid(main_inst):
		main_inst.modulate = Color.WHITE
		var cur_s: Vector2 = main_inst.scale
		var sx: float = (-1.0 if cur_s.x < 0.0 else 1.0) * absf(base_scale.x)
		var sy: float = (-1.0 if cur_s.y < 0.0 else 1.0) * absf(base_scale.y)
		main_inst.scale = Vector2(sx, sy)
	stop_weapon_energize_particles()


func cycle_axe_energize_profile_debug() -> void:
	var weapon: WeaponData = _player.weapon
	if not weapon or weapon.get_archetype_id() != "axe":
		return
	var presets: PackedStringArray = []
	var dir := DirAccess.open("res://src/combat/energize_profiles")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				presets.append(file_name.get_basename())
			file_name = dir.get_next()
		dir.list_dir_end()
	presets.sort()
	if presets.is_empty():
		presets = PackedStringArray(["earth", "fire", "glow_and_bigger", "ice", "water", "wind"])
	var idx: int = presets.find(weapon.energize_profile)
	var next_name: String = presets[(idx + 1) % presets.size()]
	weapon.charge_has_energize = true
	weapon.custom_energize_profile = null
	weapon.energize_profile = next_name
	var prof: EnergizeProfile = weapon.get_energize_profile()
	var label: String = prof.profile_name if (prof and prof.profile_name != "") else next_name
	print("[DEBUG] Axe Energize Profile -> %s (%s)" % [label, next_name])
	if _player.has_method("show_bark"):
		_player.show_bark("Energize: %s" % label)


func spawn_ground_impact_particles(center_x: float, ground_y: float, width: float, facing: int = 1, fallback_scene_path: String = "") -> void:
	var target_scene: PackedScene = null
	var weapon: WeaponData = _player.weapon
	if weapon and weapon.charge_has_energize:
		var prof: EnergizeProfile = weapon.get_energize_profile()
		if prof and prof.ground_impact_scene:
			target_scene = prof.ground_impact_scene
	if not target_scene and fallback_scene_path != "" and ResourceLoader.exists(fallback_scene_path):
		target_scene = load(fallback_scene_path) as PackedScene
	if not target_scene:
		return
	var fx := target_scene.instantiate() as CPUParticles2D
	if not fx:
		return
	var spawn_parent: Node = _player.get_tree().current_scene if (_player.get_tree() and _player.get_tree().current_scene) else _player.get_parent()
	if not spawn_parent:
		fx.queue_free()
		return
	var half_w: float = maxf(8.0, width * 0.5)
	var left_x: float = center_x - half_w
	var right_x: float = center_x + half_w

	var space: PhysicsDirectSpaceState2D = _player.get_world_2d().direct_space_state if _player.get_world_2d() else null
	if space:
		var wall_y: float = ground_y - 6.0
		var left_wall_q := PhysicsRayQueryParameters2D.create(Vector2(center_x, wall_y), Vector2(left_x, wall_y), 1)
		left_wall_q.collide_with_areas = false
		var left_hit := space.intersect_ray(left_wall_q)
		if not left_hit.is_empty():
			left_x = minf(center_x, left_hit.position.x + 2.0)

		var right_wall_q := PhysicsRayQueryParameters2D.create(Vector2(center_x, wall_y), Vector2(right_x, wall_y), 1)
		right_wall_q.collide_with_areas = false
		var right_hit := space.intersect_ray(right_wall_q)
		if not right_hit.is_empty():
			right_x = maxf(center_x, right_hit.position.x - 2.0)

		# Recorta nas bordas da plataforma para não spawnar partículas flutuando no vazio
		var step_px: float = 8.0
		var valid_left: float = center_x
		var probe_x: float = center_x - step_px
		while probe_x >= left_x:
			var floor_q := PhysicsRayQueryParameters2D.create(Vector2(probe_x, ground_y - 4.0), Vector2(probe_x, ground_y + 10.0), 1)
			floor_q.collide_with_areas = false
			if space.intersect_ray(floor_q).is_empty():
				break
			valid_left = probe_x
			probe_x -= step_px
		left_x = maxf(left_x, valid_left)

		var valid_right: float = center_x
		probe_x = center_x + step_px
		while probe_x <= right_x:
			var floor_q := PhysicsRayQueryParameters2D.create(Vector2(probe_x, ground_y - 4.0), Vector2(probe_x, ground_y + 10.0), 1)
			floor_q.collide_with_areas = false
			if space.intersect_ray(floor_q).is_empty():
				break
			valid_right = probe_x
			probe_x += step_px
		right_x = minf(right_x, valid_right)

	var clamped_half_w: float = maxf(4.0, (right_x - left_x) * 0.5)
	var clamped_center_x: float = (left_x + right_x) * 0.5

	fx.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fx.emission_rect_extents = Vector2(clamped_half_w, 2.0)
	if facing < 0:
		fx.direction.x = -absf(fx.direction.x)
	spawn_parent.add_child(fx)
	fx.global_position = Vector2(clamped_center_x, ground_y - 1.0)
	fx.z_index = 5


func set_pickup_item_visual(source_visual: Node2D, effect_profile: PickupEffectProfile = null) -> void:
	clear_pickup_item_visual()
	_pickup_effect_profile = effect_profile
	if not _pickup_effect_profile and ResourceLoader.exists("res://src/world/items/pickup_profiles/default_pickup.tres"):
		_pickup_effect_profile = load("res://src/world/items/pickup_profiles/default_pickup.tres") as PickupEffectProfile
	if not _player.item_pickup_socket or not source_visual or not is_instance_valid(source_visual):
		return
	var cloned := source_visual.duplicate() as Node2D
	if not cloned:
		return
	_item_pickup_base_scale = cloned.scale
	cloned.position = Vector2.ZERO
	cloned.rotation_degrees = 0.0
	cloned.visible = false
	_player.item_pickup_socket.add_child(cloned)
	_player.item_pickup_instance = cloned


func clear_pickup_item_visual() -> void:
	if _pickup_fx_tween and _pickup_fx_tween.is_valid():
		_pickup_fx_tween.kill()
	_pickup_fx_tween = null
	if _player.item_pickup_instance and is_instance_valid(_player.item_pickup_instance):
		_player.item_pickup_instance.queue_free()
	_player.item_pickup_instance = null
	_pickup_effect_profile = null


func play_pickup_item_burst() -> void:
	var prof: PickupEffectProfile = _pickup_effect_profile
	if not prof and ResourceLoader.exists("res://src/world/items/pickup_profiles/default_pickup.tres"):
		prof = load("res://src/world/items/pickup_profiles/default_pickup.tres") as PickupEffectProfile
	if not prof:
		return

	if prof.rumble_duration > 0.0 and (prof.rumble_weak > 0.0 or prof.rumble_strong > 0.0):
		CombatFeedback.trigger_rumble(prof.rumble_weak, prof.rumble_strong, prof.rumble_duration)

	if prof.burst_particle_scene and _player.item_pickup_socket:
		var fx := prof.burst_particle_scene.instantiate() as CPUParticles2D
		if fx:
			var spawn_parent: Node = _player.get_tree().current_scene if (_player.get_tree() and _player.get_tree().current_scene) else _player.get_parent()
			if spawn_parent:
				if prof.tint_particles:
					fx.modulate = prof.glow_color
				spawn_parent.add_child(fx)
				fx.global_position = _player.item_pickup_socket.global_position
				fx.z_index = 6
			else:
				fx.queue_free()

	var inst: Node2D = _player.item_pickup_instance
	if inst and is_instance_valid(inst):
		if _pickup_fx_tween and _pickup_fx_tween.is_valid():
			_pickup_fx_tween.kill()
		var sx_sign: float = -1.0 if inst.scale.x < 0.0 else 1.0
		var sy_sign: float = -1.0 if inst.scale.y < 0.0 else 1.0
		var target_scale := Vector2(_item_pickup_base_scale.x * sx_sign, _item_pickup_base_scale.y * sy_sign)
		inst.scale = target_scale * (1.0 + prof.scale_pop)
		inst.modulate = prof.compute_peak_modulate()
		_pickup_fx_tween = _player.create_tween()
		_pickup_fx_tween.set_parallel(true)
		_pickup_fx_tween.tween_property(inst, "scale", target_scale, prof.effect_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_pickup_fx_tween.tween_property(inst, "modulate", Color.WHITE, prof.effect_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
