class_name WeaponData
extends Resource

## Data container for weapon combat metrics and cadence.

@export_group("Weapon Identity")
@export var weapon_name: String = "Broadsword"

@export_group("Damage & Feedback")
@export_range(1.0, 500.0, 1.0, "or_greater") var base_damage: float = 25.0
@export_range(0.0, 800.0, 10.0, "suffix:px/s") var knockback_force: float = 160.0
@export_range(0.0, 0.3, 0.01, "suffix:s") var hitstop_duration: float = 0.05

@export_group("Gamepad Vibration")
@export_range(0.0, 1.0, 0.05) var rumble_weak: float = 0.4
@export_range(0.0, 1.0, 0.05) var rumble_strong: float = 0.7
@export_range(0.01, 0.5, 0.01, "suffix:s") var rumble_duration: float = 0.08

@export_group("Combo Configuration")
# Combo cadences (seconds per step)
@export var combo_durations: Array[float] = [0.18, 0.18, 0.28]
# Forward step impulse on each swing (px/s)
@export var forward_impulses: Array[float] = [80.0, 100.0, 140.0]
