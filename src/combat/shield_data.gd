class_name ShieldData
extends EquipmentData

## Data container for shields, parry timings, guard absorption, and forge upgrades.

@export_group("Shield Defense Attributes")
## Damage reduction percentage when holding simple guard (0.0 to 1.0, where 0.85 = 85% absorbed, 15% chip damage)
@export_range(0.0, 1.0, 0.05) var guard_absorption: float = 0.85

## Parry window duration in seconds (active frame window for perfect parry)
@export_range(0.05, 0.3, 0.01, "suffix:s") var parry_window: float = 0.12

## Penalty cooldown when missing a parry in the air or out of timing (seconds)
@export_range(0.2, 2.0, 0.05, "suffix:s") var parry_fail_cooldown: float = 1.0

## Stun duration applied to the attacker on successful parry (seconds)
@export_range(0.2, 2.0, 0.05, "suffix:s") var parry_stun_duration: float = 0.85

@export_group("Forge Modifiers (Sanctuary Brother)")
## Repulsion shockwave modifier: knocks back and pushes other surrounding enemies away on parry
@export var has_repulsion_modifier: bool = false
@export_range(50.0, 400.0, 10.0, "suffix:px") var repulsion_radius: float = 120.0
@export_range(100.0, 800.0, 20.0, "suffix:px/s") var repulsion_force: float = 380.0

func _init() -> void:
	slot_type = SlotType.OFF_HAND
	equipment_name = "Buckler"
