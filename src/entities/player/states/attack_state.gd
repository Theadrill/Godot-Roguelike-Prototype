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
	
	# Forward physical step
	var forward_impulse: float = player.weapon.forward_impulses[current_step]
	player.velocity.x = player.facing_direction * forward_impulse
	if player.is_on_floor():
		player.velocity.y = 0.0
	else:
		player.velocity.y = min(player.velocity.y, 40.0)
		
	# Setup active hitbox with scaling per combo step
	var step_mult: float = 1.0 + (current_step * 0.25)
	player.hitbox.damage = player.weapon.base_damage * step_mult
	player.hitbox.knockback_force = player.weapon.knockback_force * step_mult
	player.hitbox.knockback_direction = Vector2(player.facing_direction, -0.2).normalized()
	player.hitbox.hitstop_duration = player.weapon.hitstop_duration
	player.hitbox.rumble_weak = player.weapon.rumble_weak
	player.hitbox.rumble_strong = player.weapon.rumble_strong
	player.hitbox.rumble_duration = player.weapon.rumble_duration
	
	player.hitbox.set_active(false)
	player.hitbox.set_active(true)
	player.set_slash_visual(true, current_step)

func exit() -> void:
	player.hitbox.set_active(false)
	player.set_slash_visual(false, 0)
	combo_buffered = false
	last_attack_end_msec = Time.get_ticks_msec()

func physics_update(delta: float) -> void:
	attack_timer -= delta
	
	# Dodge-cancel: can always roll out of an attack immediately!
	if Input.is_action_just_pressed("roll"):
		state_machine.transition_to("roll")
		return
		
	# Input buffer for next combo hit
	if Input.is_action_just_pressed("attack_primary"):
		combo_buffered = true
		
	# Decelerate forward step
	if player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0.0, 700.0 * delta)
	else:
		player.velocity.y += (player.gravity * 0.8) * delta
		
	player.move_and_slide()
	
	# Attack frame completed
	if attack_timer <= 0.0:
		player.hitbox.set_active(false)
		player.set_slash_visual(false, 0)
		last_attack_end_msec = Time.get_ticks_msec()
		
		if combo_buffered:
			current_step = (current_step + 1) % player.weapon.combo_durations.size()
			_start_combo_step()
			return
			
		if player.is_on_floor():
			if abs(Input.get_axis("move_left", "move_right")) > 0.1:
				state_machine.transition_to("run")
			else:
				state_machine.transition_to("idle")
		else:
			state_machine.transition_to("fall")
