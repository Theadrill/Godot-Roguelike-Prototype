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

func update_charge_rumble(charge_progress: float) -> void:
	var t: float = clampf(charge_progress, 0.0, 1.0)
	var weak: float = lerpf(0.06, 0.45, t)
	var strong: float = lerpf(0.0, 0.65, t * t)
	Input.start_joy_vibration(0, weak, strong, 0.08)

func stop_rumble() -> void:
	Input.stop_joy_vibration(0)

func trigger_double_rumble(weak: float = 0.35, strong: float = 0.30, pulse_duration: float = 0.06, gap_duration: float = 0.14) -> void:
	trigger_rumble(weak, strong, pulse_duration)
	if not is_inside_tree():
		return
	await get_tree().create_timer(pulse_duration + gap_duration, true, false, true).timeout
	trigger_rumble(weak, strong, pulse_duration)

func apply_hit_feedback(hitstop: float = 0.05, weak_rumble: float = 0.4, strong_rumble: float = 0.7, rumble_dur: float = 0.08) -> void:
	trigger_rumble(weak_rumble, strong_rumble, rumble_dur)
	trigger_hitstop(hitstop)
