class_name WeaponData
extends Resource

## Data container for weapon combat metrics and cadence.

@export var weapon_name: String = "Broadsword"
@export var base_damage: float = 25.0
@export var knockback_force: float = 160.0
@export var hitstop_duration: float = 0.05
@export var rumble_weak: float = 0.4
@export var rumble_strong: float = 0.7
@export var rumble_duration: float = 0.08

# Combo cadences (seconds per step)
@export var combo_durations: Array[float] = [0.18, 0.18, 0.28]
# Forward step impulse on each swing (px/s)
@export var forward_impulses: Array[float] = [80.0, 100.0, 140.0]
