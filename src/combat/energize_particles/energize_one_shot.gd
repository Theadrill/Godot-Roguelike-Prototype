extends CPUParticles2D

func _ready() -> void:
	one_shot = true
	finished.connect(queue_free)
	call_deferred("_start_burst")

func _start_burst() -> void:
	if not is_inside_tree():
		return
	restart()
	emitting = true
