class_name DroppedEquipmentPiece
extends CharacterBody2D

## Peca fisica leve gerada ao morrer (Dead Cells style) para que armas/escudos
## caiam e quiquem no chao/paredes via move_and_collide sem nunca clipar
## e sem risco de NaN no solver do RigidBody2D quando time_scale = 0.

var _pending_global_pos: Vector2 = Vector2.ZERO
var _pending_rotation: float = 0.0
var _pending_impulse: Vector2 = Vector2.ZERO
var _pending_spin: float = 0.0
var _has_pending_transform: bool = false
var _spin_speed: float = 0.0
var _is_settled: bool = false
var _gravity: float = 820.0

func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)) * 0.85
	if _has_pending_transform:
		global_position = _pending_global_pos
		rotation = _pending_rotation
		velocity = _pending_impulse
		_spin_speed = _pending_spin
		_has_pending_transform = false

func _physics_process(delta: float) -> void:
	if _is_settled or delta <= 0.0001:
		return

	velocity.y += _gravity * delta
	velocity.x = move_toward(velocity.x, 0.0, 35.0 * delta)
	rotation += _spin_speed * delta

	var collision := move_and_collide(velocity * delta)
	if collision:
		var normal: Vector2 = collision.get_normal()
		if normal.is_finite() and normal.length_squared() > 0.001:
			velocity = velocity.bounce(normal) * 0.32
		else:
			velocity = Vector2.ZERO
		_spin_speed *= 0.45
		if normal.y < -0.5 and velocity.length_squared() < 140.0:
			velocity = Vector2.ZERO
			_spin_speed = 0.0
			_is_settled = true

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
	piece.z_index = 3

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
