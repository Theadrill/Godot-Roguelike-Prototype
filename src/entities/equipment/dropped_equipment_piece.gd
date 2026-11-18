class_name DroppedEquipmentPiece
extends RigidBody2D

## Peca fisica temporaria gerada ao morrer (Dead Cells style) para que armas/escudos
## caiam no chao colidindo naturalmente com paredes e plataformas sem clipar.

var _pending_global_pos: Vector2 = Vector2.ZERO
var _pending_rotation: float = 0.0
var _pending_impulse: Vector2 = Vector2.ZERO
var _pending_spin: float = 0.0
var _has_pending_transform: bool = false

func _ready() -> void:
	if _has_pending_transform:
		global_position = _pending_global_pos
		rotation = _pending_rotation
		linear_velocity = _pending_impulse
		angular_velocity = _pending_spin
		_has_pending_transform = false

static func spawn_from_visual(
	source_visual: Node2D,
	spawn_global_pos: Vector2,
	initial_rotation: float,
	impulse: Vector2,
	spin_speed: float,
	parent_node: Node
) -> DroppedEquipmentPiece:
	if not source_visual or not is_instance_valid(source_visual) or not parent_node:
		return null

	var piece := DroppedEquipmentPiece.new()
	piece.collision_layer = 0
	piece.collision_mask = 1
	piece.gravity_scale = 0.85
	piece.linear_damp = 0.45
	piece.angular_damp = 1.4
	piece.z_index = 3

	var mat := PhysicsMaterial.new()
	mat.bounce = 0.28
	mat.friction = 0.85
	piece.physics_material_override = mat

	var col := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	col.shape = circle
	piece.add_child(col)

	var cloned := source_visual.duplicate() as Node2D
	if not cloned:
		piece.queue_free()
		return null
	cloned.position = Vector2.ZERO
	cloned.rotation = 0.0
	cloned.visible = true
	piece.add_child(cloned)

	piece._pending_global_pos = spawn_global_pos
	piece._pending_rotation = initial_rotation
	piece._pending_impulse = impulse
	piece._pending_spin = spin_speed
	piece._has_pending_transform = true

	parent_node.call_deferred("add_child", piece)
	return piece
