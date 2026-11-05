class_name Hitbox
extends Area2D

## Active attack area delivering damage, knockback, and juice to Hurtboxes.

@export var damage: float = 20.0
@export var knockback_force: float = 160.0
@export var hitstop_duration: float = 0.05
@export var rumble_weak: float = 0.4
@export var rumble_strong: float = 0.7
@export var rumble_duration: float = 0.08

var attacker: Node2D
var knockback_direction: Vector2 = Vector2.RIGHT
var _hit_targets: Array[Hurtbox] = []

func _ready() -> void:
	area_entered.connect(_on_area_entered)

func _physics_process(_delta: float) -> void:
	if not monitoring:
		return
	for area in get_overlapping_areas():
		_try_hit_area(area)

func set_active(active: bool) -> void:
	_hit_targets.clear()
	monitoring = active
	for child in get_children():
		if child is CollisionShape2D:
			child.disabled = not active

func _on_area_entered(area: Area2D) -> void:
	if not monitoring:
		return
	_try_hit_area(area)

func _try_hit_area(area: Area2D) -> void:
	if area is Hurtbox:
		var hurtbox: Hurtbox = area as Hurtbox
		if _hit_targets.has(hurtbox):
			return
		_hit_targets.append(hurtbox)
		hurtbox.take_hit(damage, knockback_direction * knockback_force, hitstop_duration)
		CombatFeedback.apply_hit_feedback(hitstop_duration, rumble_weak, rumble_strong, rumble_duration)
