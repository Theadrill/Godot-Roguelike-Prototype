class_name Projectile
extends Area2D

## Modular 2D projectile component supporting physical flight, immediate hit destruction,
## damage delivery, and parry deflection (reflecting projectiles back at shooters).

@export var speed: float = 650.0
@export var damage: float = 24.0
@export var knockback_force: float = 180.0
@export var hitstop_duration: float = 0.06
@export var max_lifetime: float = 4.0
@export var is_enemy_projectile: bool = false

var direction: Vector2 = Vector2.RIGHT
var shooter: Node2D = null
var is_reflected: bool = false
var _lifetime: float = 0.0
var _has_hit: bool = false

@onready var visual: Node2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var internal_hitbox: Hitbox = $Hitbox

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()
	if internal_hitbox:
		internal_hitbox.attacker = shooter
		internal_hitbox.damage = damage
		internal_hitbox.knockback_force = knockback_force
		internal_hitbox.attack_category = Hitbox.AttackCategory.NORMAL
		internal_hitbox.monitoring = false
		internal_hitbox.monitorable = false

func setup(p_direction: Vector2, p_speed: float, p_damage: float, p_shooter: Node2D, p_is_enemy: bool = false) -> void:
	direction = p_direction.normalized()
	speed = p_speed
	damage = p_damage
	shooter = p_shooter
	is_enemy_projectile = p_is_enemy
	rotation = direction.angle()

	# Set collision masks based on projectile source:
	# Layer 1 = World/Walls, Layer 2 = Player, Layer 4 = Enemies
	collision_mask = 1 # Environment
	if is_enemy_projectile:
		collision_mask |= 2 # Can hit Player
	else:
		collision_mask |= 4 # Can hit Enemies

	if internal_hitbox:
		internal_hitbox.attacker = shooter
		internal_hitbox.damage = damage
		internal_hitbox.knockback_force = knockback_force
		internal_hitbox.monitoring = false
		internal_hitbox.monitorable = false

func _physics_process(delta: float) -> void:
	if _has_hit:
		return

	# Move forward in flight direction
	global_position += direction * speed * delta
	_lifetime += delta
	if _lifetime >= max_lifetime:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if _has_hit:
		return

	if area is Hurtbox:
		var hurtbox := area as Hurtbox
		var target_entity := hurtbox.get_parent()
		if target_entity == shooter:
			return

		# Check if Player is actively parrying this projectile
		if target_entity is Player:
			var player := target_entity as Player
			if player.state_machine and player.state_machine.current_state is GuardState:
				var guard := player.state_machine.current_state as GuardState
				if guard.is_parry_active:
					_reflect_projectile(player)
					return

		# Apply hit and destroy instantly
		_has_hit = true
		hurtbox.take_hit(damage, direction * knockback_force, hitstop_duration, internal_hitbox)
		CombatFeedback.apply_hit_feedback(hitstop_duration, 0.3, 0.6, 0.08)
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if _has_hit or body == shooter:
		return

	# Check if body is an entity with a Hurtbox (like Soldier or Dummy)
	var hurtbox: Hurtbox = body.get_node_or_null("Hurtbox") as Hurtbox
	if hurtbox:
		if body is Player:
			var player := body as Player
			if player.state_machine and player.state_machine.current_state is GuardState:
				var guard := player.state_machine.current_state as GuardState
				if guard.is_parry_active:
					_reflect_projectile(player)
					return
		_has_hit = true
		hurtbox.take_hit(damage, direction * knockback_force, hitstop_duration, internal_hitbox)
		CombatFeedback.apply_hit_feedback(hitstop_duration, 0.3, 0.6, 0.08)
		queue_free()
		return

	# Solid wall or obstacle: destroy immediately on contact
	_has_hit = true
	queue_free()

## Reflects the projectile when parried by the player
func _reflect_projectile(player: Player) -> void:
	is_reflected = true
	is_enemy_projectile = false
	shooter = player
	direction = -direction
	rotation = direction.angle()
	speed *= 1.35
	damage *= 1.8 # Critical reflect damage!
	_lifetime = 0.0

	# Reconfigure collision masks to hit enemies now
	collision_mask = 1 | 4 # World + Enemies

	# Visual juice on parry reflect: pure bright cyan trail
	modulate = Color(0.4, 0.9, 1.0, 1.0)
	CombatFeedback.apply_hit_feedback(0.12, 0.6, 0.9, 0.15)
