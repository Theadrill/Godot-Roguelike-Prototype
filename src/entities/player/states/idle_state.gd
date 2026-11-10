class_name IdleState
extends State

var player: Player

# Idle breaks architecture
@export var idle_break_delay: float = 4.5
var idle_timer: float = 0.0
var breath_time: float = 0.0
var is_in_idle_break: bool = false
var break_anim_time: float = 0.0

const BASE_BODY_SCALE := Vector2(1.0, 1.0)
const BASE_BODY_POS := Vector2(0.0, 0.0)
const BASE_HEADBAND_POS := Vector2(0.0, 0.0)
const BASE_MAIN_HAND_POS := Vector2(6.0, -20.0)
const BASE_OFF_HAND_POS := Vector2(7.0, -19.0)
const BASE_BACK_WEAPON_POS := Vector2(-3.0, -20.0)
const BASE_BACK_SHIELD_POS := Vector2(-6.0, -20.0)

func enter() -> void:
	player = character as Player
	player.velocity.x = 0.0
	idle_timer = 0.0
	breath_time = 0.0
	is_in_idle_break = false
	break_anim_time = 0.0
	player.fall_peak_y = player.global_position.y
	_reset_break_visuals()
	player.play_animation(&"idle")

func exit() -> void:
	_reset_break_visuals()
	player.stop_animation()

func _reset_break_visuals() -> void:
	is_in_idle_break = false
	if player:
		if player.body_polygon:
			player.body_polygon.scale = BASE_BODY_SCALE
			player.body_polygon.position = BASE_BODY_POS
		if player.visual:
			var headband := player.visual.get_node_or_null("HeadbandPlaceholder") as Polygon2D
			if headband:
				headband.position = BASE_HEADBAND_POS
				headband.rotation_degrees = 0.0
		if player.main_hand_socket:
			player.main_hand_socket.position = BASE_MAIN_HAND_POS
		if player.off_hand_socket:
			player.off_hand_socket.position = BASE_OFF_HAND_POS
		if player.back_socket_weapon:
			player.back_socket_weapon.position = BASE_BACK_WEAPON_POS
		if player.back_socket_shield:
			player.back_socket_shield.position = BASE_BACK_SHIELD_POS

func physics_update(delta: float) -> void:
	# Fall check
	if not player.is_on_floor():
		state_machine.transition_to("fall")
		return

	# Se os controles do jogador estiverem travados (menus/diálogos), apenas anima a respiração sem reagir a botões
	if player.is_input_locked:
		_process_breathing_visuals(delta)
		player.move_and_slide()
		return

	# Jump check (buffered or instant)
	if player.jump_buffer_timer > 0.0:
		player.jump_buffer_timer = 0.0
		state_machine.transition_to("jump")
		return

	# Crouch check
	if player.is_crouch_requested():
		state_machine.transition_to("crouch")
		return

	# Heal check (Garrafa de Chá da Mãe)
	if Input.is_action_just_pressed("heal"):
		state_machine.transition_to("heal")
		return

	# Guard / Parry check
	if Input.is_action_just_pressed("defend") and player.can_defend():
		state_machine.transition_to("guard")
		return

	# Attack check (Melee vs Ranged - supports holding button)
	if Input.is_action_pressed("attack_primary") and player.can_attack():
		if player.is_ranged_weapon_equipped():
			state_machine.transition_to("rangedattack")
		else:
			state_machine.transition_to("attack")
		return

	# Roll check
	if player.is_roll_requested():
		state_machine.transition_to("roll")
		return

	# Run check
	var direction := Input.get_axis("move_left", "move_right")
	if abs(direction) > 0.1:
		state_machine.transition_to("run")
		return

	_process_breathing_visuals(delta)
	player.move_and_slide()

func _process_breathing_visuals(delta: float) -> void:
	if player.idle_sprite and player.idle_sprite.visible:
		# O sprite já possui sua própria animação de respiração desenhada nos frames
		player.move_and_slide()
		return

	# Continuous Breathing (Occurs constantly while idle)
	# Feet (y = 0) stay 100% planted on the ground; only upper body squashes and stretches gently.
	breath_time += delta
	var breath_phase: float = sin(breath_time * 2.6)
	var compression_px: float = (breath_phase + 1.0) * 0.5 * 1.5 # Ranges from 0.0 to 1.5px

	if player.body_polygon:
		player.body_polygon.position = BASE_BODY_POS # Grounded at 0.0
		player.body_polygon.scale.y = 1.0 - (compression_px / 40.0)
		player.body_polygon.scale.x = 1.0 + (compression_px / 40.0) * 0.25

	# Headband & all equipment sockets follow the breathing movement in perfect sync (only for placeholder)
	var is_using_sprite: bool = player.player_sprite and player.player_sprite.visible
	if not is_using_sprite:
		var torso_offset_y: float = compression_px * 0.5
		if player.main_hand_socket:
			player.main_hand_socket.position.y = BASE_MAIN_HAND_POS.y + torso_offset_y
		if player.off_hand_socket:
			player.off_hand_socket.position.y = BASE_OFF_HAND_POS.y + torso_offset_y
		if player.back_socket_weapon:
			player.back_socket_weapon.position.y = BASE_BACK_WEAPON_POS.y + torso_offset_y
		if player.back_socket_shield:
			player.back_socket_shield.position.y = BASE_BACK_SHIELD_POS.y + torso_offset_y

	var headband := player.visual.get_node_or_null("HeadbandPlaceholder") as Polygon2D if player.visual else null

	# Idle breaks timer: after standing still for longer, character looks around
	idle_timer += delta
	if idle_timer >= idle_break_delay:
		is_in_idle_break = true
		break_anim_time += delta

		if headband:
			# Look-around sequence:
			# 0.0s - 0.8s: Glance over shoulder (headband shifts back)
			# 0.8s - 1.4s: Return to front
			# 1.4s - 2.0s: Slight inquisitive head tilt forward
			# > 2.2s: Resets idle timer and returns to regular breathing
			if break_anim_time < 0.8:
				var look_progress: float = clampf(break_anim_time / 0.3, 0.0, 1.0)
				headband.position.x = lerpf(0.0, -3.5, look_progress)
				headband.position.y = -compression_px
				headband.rotation_degrees = lerpf(0.0, 6.0, look_progress)
			elif break_anim_time < 1.4:
				var return_progress: float = clampf((break_anim_time - 0.8) / 0.3, 0.0, 1.0)
				headband.position.x = lerpf(-3.5, 0.0, return_progress)
				headband.position.y = -compression_px
				headband.rotation_degrees = lerpf(6.0, 0.0, return_progress)
			elif break_anim_time < 2.0:
				headband.position.x = 1.5
				headband.position.y = -compression_px - 0.8
				headband.rotation_degrees = -3.0
			else:
				# Complete idle break, loop back
				idle_timer = 0.0
				break_anim_time = 0.0
				is_in_idle_break = false
				headband.position = BASE_HEADBAND_POS
				headband.rotation_degrees = 0.0
	else:
		if headband:
			headband.position.x = BASE_HEADBAND_POS.x
			headband.position.y = -compression_px + (sin(breath_time * 5.2) * 0.3)
			headband.rotation_degrees = 0.0

	player.move_and_slide()
