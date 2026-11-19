class_name RadialShockwave
extends Node2D

## Modular shockwave component delivering radial force, optional damage, and procedural visual feedback.
## Shared between Ground Slam (area damage + knockback) and Shield Repulsion modifier (zero-damage pushback).

@export_range(10.0, 500.0, 5.0, "suffix:px") var radius: float = 100.0
@export_range(50.0, 1000.0, 10.0, "suffix:px/s") var force: float = 350.0
@export_range(0.0, 200.0, 1.0) var damage: float = 0.0
@export_range(0.05, 1.0, 0.02, "suffix:s") var duration: float = 0.22
@export var shockwave_color: Color = Color(1.0, 1.0, 1.0, 0.85)

const ENVIRONMENT_LAYER_MASK: int = 1
const RING_SEGMENTS: int = 48

var attacker: Node2D = null
var ignored_entity: Node2D = null

var _elapsed_time: float = 0.0
var _current_radius: float = 0.0
var _current_alpha: float = 1.0
var _ray_dirs: PackedVector2Array = PackedVector2Array()
var _ray_max_dists: PackedFloat32Array = PackedFloat32Array()

func _ready() -> void:
	_compute_visual_occlusion()
	_trigger_physics_shockwave()
	queue_redraw()

func setup(p_radius: float, p_force: float, p_damage: float, p_ignored: Node2D = null, p_attacker: Node2D = null, p_color: Color = Color.WHITE) -> void:
	radius = p_radius
	force = p_force
	damage = p_damage
	ignored_entity = p_ignored
	attacker = p_attacker
	shockwave_color = p_color

func _trigger_physics_shockwave() -> void:
	var space := get_world_2d().direct_space_state
	if not space:
		return

	# Query circle area around shockwave center
	var shape := CircleShape2D.new()
	shape.radius = radius

	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.collision_mask = 2 | 4 # Layer 2: Player/Characters, Layer 4: Hit/Hurtboxes

	var results := space.intersect_shape(query, 32)
	var processed_entities: Array[Node2D] = []

	for item in results:
		var collider: Object = item.collider
		if not collider:
			continue

		var entity: Node2D = null
		var hurtbox: Hurtbox = null

		if collider is Hurtbox:
			hurtbox = collider as Hurtbox
			entity = hurtbox.get_parent() as Node2D
		elif collider is CharacterBody2D:
			entity = collider as Node2D
			hurtbox = entity.get_node_or_null("Hurtbox") as Hurtbox

		if not entity or processed_entities.has(entity):
			continue
		if entity == ignored_entity or entity == attacker:
			continue

		processed_entities.append(entity)

		if not _has_clear_line_of_sight(space, entity):
			continue

		var diff: Vector2 = (entity.global_position + Vector2(0.0, -16.0)) - global_position
		var dir: Vector2 = diff.normalized()
		if dir == Vector2.ZERO:
			dir = Vector2.UP

		# Knockback with upward bias for satisfying gameplay feel
		var knockback_dir: Vector2 = Vector2(dir.x, minf(dir.y, -0.35)).normalized()

		if hurtbox:
			hurtbox.take_hit(damage, knockback_dir * force, 0.05 if damage > 0.0 else 0.0)
		elif entity is CharacterBody2D:
			(entity as CharacterBody2D).velocity = knockback_dir * force

func _has_clear_line_of_sight(space: PhysicsDirectSpaceState2D, entity: Node2D) -> bool:
	var origin: Vector2 = global_position + Vector2(0.0, -4.0)
	var sample_points: Array[Vector2] = [
		entity.global_position + Vector2(0.0, -16.0),
		entity.global_position + Vector2(0.0, -6.0)
	]
	for target_pos in sample_points:
		var ray_query := PhysicsRayQueryParameters2D.create(origin, target_pos, ENVIRONMENT_LAYER_MASK)
		ray_query.collide_with_areas = false
		ray_query.collide_with_bodies = true
		if space.intersect_ray(ray_query).is_empty():
			return true
	return false

func _compute_visual_occlusion() -> void:
	_ray_dirs.resize(RING_SEGMENTS)
	_ray_max_dists.resize(RING_SEGMENTS)
	var space := get_world_2d().direct_space_state
	for i in range(RING_SEGMENTS):
		var angle: float = (TAU * float(i)) / float(RING_SEGMENTS)
		var dir := Vector2(cos(angle), sin(angle))
		_ray_dirs[i] = dir
		var max_d: float = radius
		if space:
			var ray_query := PhysicsRayQueryParameters2D.create(global_position, global_position + dir * radius, ENVIRONMENT_LAYER_MASK)
			ray_query.collide_with_areas = false
			ray_query.collide_with_bodies = true
			var hit := space.intersect_ray(ray_query)
			if not hit.is_empty():
				max_d = global_position.distance_to(hit.position)
		_ray_max_dists[i] = max_d

func _process(delta: float) -> void:
	_elapsed_time += delta
	var progress := clampf(_elapsed_time / duration, 0.0, 1.0)
	# Ease out expansion
	_current_radius = radius * (1.0 - pow(1.0 - progress, 3))
	_current_alpha = (1.0 - progress) * shockwave_color.a
	queue_redraw()

	if _elapsed_time >= duration:
		queue_free()

func _draw() -> void:
	if _current_radius <= 0.0:
		return
	var col := shockwave_color
	col.a = _current_alpha
	if _ray_dirs.size() != RING_SEGMENTS or _ray_max_dists.size() != RING_SEGMENTS:
		draw_arc(Vector2.ZERO, _current_radius, 0.0, TAU, 32, col, 2.5, false)
		return
	for i in range(RING_SEGMENTS):
		var next_i: int = (i + 1) % RING_SEGMENTS
		var max0: float = _ray_max_dists[i]
		var max1: float = _ray_max_dists[next_i]
		if _current_radius > max0 + 1.5 and _current_radius > max1 + 1.5:
			continue
		var p0: Vector2 = _ray_dirs[i] * minf(_current_radius, max0)
		var p1: Vector2 = _ray_dirs[next_i] * minf(_current_radius, max1)
		draw_line(p0, p1, col, 2.5, false)
