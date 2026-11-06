class_name StaggerState
extends State

## Stagger / Stun State:
## Triggered when taking perilous Red attacks or suffering a Guard Break.
## Visually forces the crouched animation/posture and locks player control for the stun duration.

var player: Player
var duration: float = 0.22
var timer: float = 0.0

func enter() -> void:
	player = character as Player
	timer = duration
	player.set_crouched(true)

func exit() -> void:
	player.set_crouched(false)

func physics_update(delta: float) -> void:
	# Decelerate knockback smoothly
	if player.is_on_floor():
		player.velocity.x = move_toward(player.velocity.x, 0.0, 700.0 * delta)
		player.velocity.y = 0.0
	else:
		player.velocity.y += player.gravity * delta
		player.velocity.x = move_toward(player.velocity.x, 0.0, 400.0 * delta)

	player.move_and_slide()

	timer -= delta
	if timer <= 0.0:
		if not player.is_on_floor():
			state_machine.transition_to("fall")
		else:
			var dir := Input.get_axis("move_left", "move_right")
			if abs(dir) > 0.1:
				state_machine.transition_to("run")
			else:
				state_machine.transition_to("idle")
