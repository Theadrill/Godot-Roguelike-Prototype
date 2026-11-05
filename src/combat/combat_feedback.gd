extends Node

## Global Game Feel Juice: Hitstop & Gamepad Haptics

var _is_frozen: bool = false

func trigger_hitstop(duration: float = 0.05) -> void:
	if _is_frozen:
		return
	_is_frozen = true
	Engine.time_scale = 0.0
	
	# Timer that ignores Engine.time_scale (process_always = true)
	await get_tree().create_timer(duration, true, false, true).timeout
	
	Engine.time_scale = 1.0
	_is_frozen = false

func trigger_rumble(weak: float = 0.4, strong: float = 0.7, duration: float = 0.08) -> void:
	# Device 0 is the primary connected gamepad
	Input.start_joy_vibration(0, weak, strong, duration)

func apply_hit_feedback(hitstop: float = 0.05, weak_rumble: float = 0.4, strong_rumble: float = 0.7, rumble_dur: float = 0.08) -> void:
	trigger_rumble(weak_rumble, strong_rumble, rumble_dur)
	trigger_hitstop(hitstop)
