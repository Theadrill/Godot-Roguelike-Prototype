class_name IdleState
extends State

var player: Player

# Idle breaks architecture
@export var idle_break_delay: float = 5.0
var idle_timer: float = 0.0
var is_in_idle_break: bool = false
var break_anim_time: float = 0.0

func enter() -> void:
	player = character as Player
	player.velocity.x = 0.0
	idle_timer = 0.0
	is_in_idle_break = false
	break_anim_time = 0.0
	player.fall_peak_y = player.global_position.y
	_reset_break_visuals()

func exit() -> void:
	_reset_break_visuals()

func _reset_break_visuals() -> void:
	is_in_idle_break = false
	if player and player.body_polygon:
		player.body_polygon.position.y = 0.0
	if player and player.visual:
		var headband := player.visual.get_node_or_null("HeadbandPlaceholder") as Polygon2D
		if headband:
			headband.position.y = 0.0

func physics_update(delta: float) -> void:
	# Fall check
	if not player.is_on_floor():
		state_machine.transition_to("fall")
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

	# Guard / Parry check
	if Input.is_action_just_pressed("defend") and player.can_defend():
		state_machine.transition_to("guard")
		return

	# Attack check
	if Input.is_action_just_pressed("attack_primary") and player.can_attack():
		state_machine.transition_to("attack")
		return

	# Roll check
	if Input.is_action_just_pressed("roll"):
		state_machine.transition_to("roll")
		return

	# Run check
	var direction := Input.get_axis("move_left", "move_right")
	if abs(direction) > 0.1:
		state_machine.transition_to("run")
		return

	# Idle breaks timer
	idle_timer += delta
	if idle_timer >= idle_break_delay:
		is_in_idle_break = true
		break_anim_time += delta

		# Subtle 2px breathing oscillation on torso + micro-wave on headband
		var breath_offset: float = sin(break_anim_time * 2.5) * 1.5
		if player.body_polygon:
			player.body_polygon.position.y = breath_offset
		if player.visual:
			var headband := player.visual.get_node_or_null("HeadbandPlaceholder") as Polygon2D
			if headband:
				headband.position.y = breath_offset + sin(break_anim_time * 4.0) * 0.8
	else:
		_reset_break_visuals()

	player.move_and_slide()
