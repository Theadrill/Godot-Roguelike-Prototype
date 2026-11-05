class_name Hurtbox
extends Area2D

## Defensive receiver area on characters/targets that receives hits.

signal hit_received(damage: float, knockback: Vector2, hitstop: float)

@export var is_invulnerable: bool = false

func take_hit(amount: float, knockback: Vector2, hitstop: float) -> void:
	if is_invulnerable:
		return
	hit_received.emit(amount, knockback, hitstop)
