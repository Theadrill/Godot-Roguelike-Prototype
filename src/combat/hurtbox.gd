class_name Hurtbox
extends Area2D

## Defensive receiver area on characters/targets that receives hits.

signal hit_received(damage: float, knockback: Vector2, hitstop: float)

@export var is_invulnerable: bool = false
var last_hitbox: Hitbox = null

func take_hit(amount: float, knockback: Vector2, hitstop: float, source_hitbox: Hitbox = null) -> void:
	if is_invulnerable:
		return
	last_hitbox = source_hitbox
	hit_received.emit(amount, knockback, hitstop)
