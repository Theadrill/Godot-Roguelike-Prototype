class_name IdleState
extends State

var player: Player

# Idle breaks architecture (prepared)
@export var idle_break_delay: float = 5.0
var idle_timer: float = 0.0

func enter() -> void:
	player = character as Player
	player.velocity.x = 0.0
	idle_timer = 0.0
	player.fall_peak_y = player.global_position.y

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
		idle_timer = 0.0
		# Stub for idle break variation

	player.move_and_slide()
