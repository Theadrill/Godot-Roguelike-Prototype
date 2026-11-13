class_name GuardState
extends State

## Guard & Parry State:
## Implements active 120ms perfect parry window, continuous simple guard with chip damage,
## guard breaks against red attacks, and strict 1.0s spam penalty on whiff.

var player: Player

var parry_timer: float = 0.0
var is_parry_active: bool = false
var has_parried: bool = false
var guard_held_time: float = 0.0
var block_recoil_timer: float = 0.0

func enter() -> void:
	player = character as Player
	player.set_shield_raised(true)
	player.play_animation(&"block")
	has_parried = false
	guard_held_time = 0.0
	block_recoil_timer = 0.0

	var parry_window: float = player.shield.parry_window if player.shield else 0.12
	parry_timer = parry_window
	is_parry_active = true

func exit() -> void:
	is_parry_active = false
	player.set_shield_raised(false)

	# Strict 1.0s whiff penalty: applied if player tapped/released guard without absorbing an attack
	if not has_parried:
		var penalty: float = player.shield.parry_fail_cooldown if player.shield else 1.0
		player.parry_cooldown_timer = penalty

func physics_update(delta: float) -> void:
	guard_held_time += delta

	# Parry active window countdown (~120ms)
	if is_parry_active:
		parry_timer -= delta
		if parry_timer <= 0.0:
			is_parry_active = false

	# Gravity
	if not player.is_on_floor():
		player.velocity.y += player.gravity * delta
	else:
		player.velocity.y = 0.0

	# Movement & block recoil pushback
	if block_recoil_timer > 0.0:
		block_recoil_timer -= delta
		player.velocity.x = move_toward(player.velocity.x, 0.0, 700.0 * delta)
	else:
		if player.is_on_floor():
			var direction := Input.get_axis("move_left", "move_right")
			player.velocity.x = move_toward(player.velocity.x, 0.0, 900.0 * delta)
			if direction != 0.0:
				player.update_facing(direction)
		else:
			var direction := Input.get_axis("move_left", "move_right")
			player.velocity.x = move_toward(player.velocity.x, direction * (player.run_speed * 0.5), 600.0 * delta)

	player.move_and_slide()

	# Release button: exit guard
	if not Input.is_action_pressed("defend"):
		_exit_to_movement()
		return

	# Instant attack out of guard / parry
	if Input.is_action_just_pressed("attack_primary") and player.can_attack():
		if player.is_ranged_weapon_equipped():
			state_machine.transition_to("rangedattack")
		else:
			state_machine.transition_to("attack")
		return

	# Slide / Dodge cancel
	if player.is_slide_requested():
		state_machine.transition_to("slide")
		return

func _exit_to_movement() -> void:
	if not player.is_on_floor():
		state_machine.transition_to("fall")
	else:
		var direction := Input.get_axis("move_left", "move_right")
		if abs(direction) > 0.1:
			state_machine.transition_to("run")
		else:
			state_machine.transition_to("idle")

## Intercepts incoming hits from Hurtbox
## Returns true if the hit was completely or partially handled by the shield
func handle_incoming_hit(damage: float, knockback: Vector2, hitstop: float, incoming_hitbox: Hitbox) -> bool:
	var category: Hitbox.AttackCategory = incoming_hitbox.attack_category if incoming_hitbox else Hitbox.AttackCategory.NORMAL

	# --- 1. PERFECT PARRY (Active 120ms Window) ---
	if is_parry_active:
		has_parried = true
		player.parry_cooldown_timer = 0.0 # Instant reset on success!
		ProgressionManager.record_perfect_parry()

		# Visual & Tactile Juice
		CombatFeedback.apply_hit_feedback(0.12, 0.6, 0.9, 0.15)
		if player.flash_material:
			player.flash_timer = 0.15
			player.flash_material.set_shader_parameter("flash_active", true)

		# Stun the attacker
		var attacker := incoming_hitbox.attacker if incoming_hitbox else null
		if attacker and attacker.has_method("apply_parry_stun"):
			var stun_dur: float = player.shield.parry_stun_duration if player.shield else 0.85
			attacker.apply_parry_stun(stun_dur)
		if attacker and attacker.has_method("on_attack_blocked"):
			attacker.on_attack_blocked(true)

		# Tactical Life Rally: Perfect Parry recovers recent lost health!
		player.apply_parry_rally()

		# Forge Modifier & Death Blessing: Repulsion / Spectral Shockwave
		var has_spectral: bool = player.has_meta("mod_onda_espectral") and player.get_meta("mod_onda_espectral")
		if (player.shield and player.shield.has_repulsion_modifier) or has_spectral:
			var shockwave_scene := load("res://src/combat/radial_shockwave.tscn") as PackedScene
			if shockwave_scene:
				var sw := shockwave_scene.instantiate() as RadialShockwave
				sw.global_position = player.global_position + Vector2(0.0, -18.0)
				var wave_color := Color(0.42, 0.85, 0.7, 0.95) if has_spectral else Color(0.3, 0.85, 1.0, 0.9)
				var wave_radius: float = 80.0 if has_spectral else (player.shield.repulsion_radius if player.shield else 60.0)
				var wave_force: float = 300.0 if has_spectral else (player.shield.repulsion_force if player.shield else 220.0)
				var wave_dmg: float = 8.0 if has_spectral else 0.0
				sw.setup(
					wave_radius,
					wave_force,
					wave_dmg,
					attacker, # Ignores the parried attacker
					player,
					wave_color
				)
				player.get_parent().add_child(sw)

		# Zero damage taken!
		return true

	# --- 2. CONTINUOUS SIMPLE GUARD (Holding shield past parry window) ---
	var blocker_attacker := incoming_hitbox.attacker if incoming_hitbox else null
	if blocker_attacker and blocker_attacker.has_method("on_attack_blocked"):
		blocker_attacker.on_attack_blocked(false)

	match category:
		Hitbox.AttackCategory.NORMAL:
			# 100% absorbed, 0 damage
			has_parried = true
			block_recoil_timer = 0.12
			player.velocity.x = -player.facing_direction * 70.0
			CombatFeedback.apply_hit_feedback(0.04, 0.25, 0.4, 0.08)
			return true

		Hitbox.AttackCategory.HEAVY:
			# Chip damage (85% absorbed, 15% damage taken)
			has_parried = true
			var absorption: float = player.shield.guard_absorption if player.shield else 0.85
			var chip_damage: float = damage * (1.0 - absorption)
			player.current_health = max(0.0, player.current_health - chip_damage)
			if player.current_health > 0.0:
				player.rally_recoverable_hp = minf(player.rally_recoverable_hp + chip_damage, player.max_health - player.current_health)
				player.rally_timer = player.RALLY_DURATION
			block_recoil_timer = 0.18
			player.velocity.x = -player.facing_direction * 150.0

			if player.flash_material:
				player.flash_timer = 0.08
				player.flash_material.set_shader_parameter("flash_active", true)
			CombatFeedback.apply_hit_feedback(0.06, 0.4, 0.6, 0.1)
			return true

		Hitbox.AttackCategory.PERILOUS:
			# GUARD BREAK! 100% damage, staggered, shield dropped and put on long cooldown
			player.current_health = max(0.0, player.current_health - damage)
			if player.current_health > 0.0:
				player.rally_recoverable_hp = minf(player.rally_recoverable_hp + damage, player.max_health - player.current_health)
				player.rally_timer = player.RALLY_DURATION
			player.velocity = knockback
			player.parry_cooldown_timer = 1.5 # Guard break penalty

			if player.flash_material:
				player.flash_timer = 0.25
				player.flash_material.set_shader_parameter("flash_active", true)
			CombatFeedback.apply_hit_feedback(0.15, 0.7, 1.0, 0.2)

			# Drop shield and enter long crouched stagger
			player.set_shield_raised(false)
			player.trigger_stagger(0.55)
			return true

	return false
