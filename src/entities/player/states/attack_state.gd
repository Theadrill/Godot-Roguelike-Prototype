class_name AttackState
extends State

## Attack State with 3-step weapon combo, forward impulse, and dodge-cancel.

var player: Player
var current_step: int = 0
var attack_timer: float = 0.0
var combo_buffered: bool = false
var last_attack_end_msec: int = -10000

const COMBO_WINDOW: float = 0.32

func enter() -> void:
	player = character as Player
	
	var elapsed_sec: float = float(Time.get_ticks_msec() - last_attack_end_msec) / 1000.0
	if elapsed_sec <= COMBO_WINDOW:
		current_step = (current_step + 1) % player.weapon.combo_durations.size()
	else:
		current_step = 0
		
	_start_combo_step()

func _start_combo_step() -> void:
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
		# Forward physical step
		var forward_impulse: float = player.weapon.forward_impulses[current_step]
		player.velocity.x = player.facing_direction * forward_impulse
		if player.hitbox.has_node("CollisionShape2D"):
			player.hitbox.get_node("CollisionShape2D").position = Vector2(20.0, -20.0)
			(player.hitbox.get_node("CollisionShape2D").shape as RectangleShape2D).size = Vector2(32.0, 28.0)
		player.hitbox.knockback_direction = Vector2(player.facing_direction, -0.2).normalized()

	# When on ground, clamp vertical speed to 0; when in air, leave gravity/fall speed completely untouched!
	if player.is_on_floor():
		player.velocity.y = 0.0

	# Setup active hitbox with scaling per combo step
	var step_mult: float = 1.0 + (current_step * 0.25)
	player.hitbox.damage = player.weapon.base_damage * step_mult
	player.hitbox.knockback_force = player.weapon.knockback_force * step_mult
	player.hitbox.hitstop_duration = player.weapon.hitstop_duration
	player.hitbox.rumble_weak = player.weapon.rumble_weak
	player.hitbox.rumble_strong = player.weapon.rumble_strong
	player.hitbox.rumble_duration = player.weapon.rumble_duration
	player.hitbox.combo_step = current_step + 1
	
	player.hitbox.set_active(false)
	player.hitbox.set_active(true)
	player.set_slash_visual(true, current_step, is_upward, is_downward)

func exit() -> void:
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
	attack_timer -= delta
	
	# Dodge-cancel: can always roll out of an attack immediately!
	if Input.is_action_just_pressed("roll"):
		state_machine.transition_to("roll")
		return
		
	# Input buffer for next combo hit (only allowed if cooldown ready)
	if Input.is_action_just_pressed("attack_primary"):
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
			_start_combo_step()
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
