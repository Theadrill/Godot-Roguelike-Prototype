@tool
class_name EquipmentData
extends Resource

## Base data container for socketed equipments (weapons, shields, tools).

enum SlotType {
	MAIN_HAND,
	OFF_HAND,
	TWO_HANDED
}

@export_group("Identity")
@export var equipment_name: String = "Basic Equipment"
@export var slot_type: SlotType = SlotType.MAIN_HAND

@export_group("Visual Representation")
## PackedScene representing the visual item attached to player sockets.
@export var visual_scene: PackedScene
@export var visual_offset: Vector2 = Vector2.ZERO
@export var visual_rotation_degrees: float = 0.0
@export var back_offset: Vector2 = Vector2.ZERO
@export var back_rotation_degrees: float = 0.0
