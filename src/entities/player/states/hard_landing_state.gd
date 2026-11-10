class_name HardLandingState
extends State

## Hard Landing / Knee-Impact Recovery State.
## Plays when the player lands from a high altitude drop.
## Squashes the character into a knee-drop pose for a brief moment (e.g. 180ms)
## before smoothly rising back up to stand or run.

var player: Player
var recovery_timer: float = 0.0

func enter() -> void:
	player = character as Player
	player.velocity = Vector2.ZERO
	recovery_timer = 0.0
	player.play_animation(&"idle")

	# Squash on knee impact: squashed Y (crouch height) and wider X
	var face: float = float(player.facing_direction)
	player.visual.scale = Vector2(face * 1.25, 0.55)

func exit() -> void:
	var face: float = float(player.facing_direction)
	player.visual.scale = Vector2(face, 1.0)
	player.stop_animation()

func physics_update(delta: float) -> void:
	player.velocity.x = 0.0
	recovery_timer += delta

	var face: float = float(player.facing_direction)
	var t: float = clampf(recovery_timer / maxf(player.hard_landing_duration, 0.01), 0.0, 1.0)
	# Smooth easing: springs up from squashed knee-impact to standing
	var current_scale_y: float = lerpf(0.55, 1.0, t * t)
	var current_scale_x: float = lerpf(1.25, 1.0, t * t)
	player.visual.scale = Vector2(face * current_scale_x, current_scale_y)

	player.move_and_slide()

	if recovery_timer >= player.hard_landing_duration:
		player.visual.scale = Vector2(face, 1.0)
		var h_dir: float = Input.get_axis("move_left", "move_right")
		if absf(h_dir) > 0.1:
			state_machine.transition_to("run")
		else:
			state_machine.transition_to("idle")
