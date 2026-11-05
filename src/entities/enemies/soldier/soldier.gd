class_name Soldier
extends CharacterBody2D

## Basic melee soldier enemy implementing FSM, 3-signal tactical combat, and diegetic feedback.

@export_group("Soldier Stats")
@export var stationary: bool = false
@export_range(-1, 1, 2) var initial_facing: int = 1
@export_range(10.0, 1000.0, 5.0) var max_health: float = 60.0
@export_range(10.0, 300.0, 5.0, "suffix:px/s") var patrol_speed: float = 40.0
@export_range(30.0, 400.0, 5.0, "suffix:px/s") var chase_speed: float = 85.0
@export_range(100.0, 3000.0, 50.0, "suffix:px/s") var friction: float = 800.0

@export_group("Perception & Range")
@export_range(50.0, 400.0, 10.0, "suffix:px") var spot_range: float = 160.0
@export_range(20.0, 200.0, 5.0, "suffix:px") var back_awareness_range: float = 64.0
@export_range(10.0, 100.0, 2.0, "suffix:px") var attack_range: float = 26.0
@export_range(100.0, 600.0, 10.0, "suffix:px") var lose_target_range: float = 240.0

@export_group("Attack Balancing")
@export_range(5.0, 100.0, 1.0) var normal_damage: float = 12.0
@export_range(10.0, 150.0, 1.0) var heavy_damage: float = 20.0
@export_range(15.0, 200.0, 1.0) var perilous_damage: float = 32.0
@export_range(0.1, 1.5, 0.05, "suffix:s") var telegraph_duration: float = 0.45

@export_group("Respawn (Test Mode)")
@export var respawn_enabled: bool = false
@export_range(1.0, 30.0, 0.5, "suffix:s") var respawn_delay: float = 5.0

var spawn_position: Vector2 = Vector2.ZERO

var current_health: float = 60.0
var facing_direction: int = 1
var target_player: Player = null
var is_hyper_armored: bool = false
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity", 980.0)
var flash_timer: float = 0.0
var flash_material: ShaderMaterial

@onready var visual: Node2D = $Visual
@onready var body_polygon: Polygon2D = $Visual/Body
@onready var telegraph_mark: Node2D = $Visual/TelegraphMark
@onready var yellow_mark: Polygon2D = $Visual/TelegraphMark/YellowMark
@onready var red_mark: Polygon2D = $Visual/TelegraphMark/RedMark
@onready var slash_arc: Polygon2D = $Visual/SlashArc
@onready var hitbox: Hitbox = $Visual/Hitbox
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var state_machine: StateMachine = $StateMachine

func _ready() -> void:
	spawn_position = global_position
	current_health = max_health
	if initial_facing != 0:
		update_facing(float(initial_facing))
	hurtbox.hit_received.connect(_on_hit_received)
	hide_telegraph()
	set_slash_active(false)

	# Setup hit flash shader material
	var shader := load("res://src/shaders/hit_flash.gdshader") as Shader
	if shader and body_polygon:
		flash_material = ShaderMaterial.new()
		flash_material.shader = shader
		body_polygon.material = flash_material

	# Set hitbox attacker reference
	if hitbox:
		hitbox.attacker = self

func _physics_process(delta: float) -> void:
	# Flash timer update
	if flash_timer > 0.0:
		flash_timer -= delta
		if flash_timer <= 0.0 and flash_material:
			flash_material.set_shader_parameter("flash_active", false)

	# Squash & stretch recovery
	visual.scale.y = move_toward(visual.scale.y, 1.0, 4.0 * delta)

func update_facing(dir: float) -> void:
	if dir > 0.0:
		facing_direction = 1
		visual.scale.x = 1.0
	elif dir < 0.0:
		facing_direction = -1
		visual.scale.x = -1.0

func _on_hit_received(damage: float, knockback: Vector2, hitstop: float) -> void:
	current_health -= damage

	# Hit flash
	if flash_material:
		flash_timer = hitstop + 0.06
		flash_material.set_shader_parameter("flash_active", true)

	visual.scale = Vector2(visual.scale.x, 0.75)

	# Check Death
	if current_health <= 0.0:
		state_machine.transition_to("death")
		return

	# Acquire target on hit if null
	if not target_player or not is_instance_valid(target_player):
		var tree := get_tree()
		if tree:
			var players := tree.get_nodes_in_group("player")
			if players.size() > 0 and players[0] is Player:
				target_player = players[0] as Player
			elif tree.current_scene:
				var p := tree.current_scene.find_child("Player", true, false)
				if p is Player:
					target_player = p as Player

	# Turn towards attacker based on knockback direction
	if absf(knockback.x) > 1.0:
		update_facing(-signf(knockback.x))

	# Zero Hyper-Armor Rule:
	# If NOT hyper-armored, take full knockback and get interrupted into HurtState!
	if not is_hyper_armored:
		velocity = knockback
		state_machine.transition_to("hurt")
	else:
		# Hyper-Armor Active:
		# Still take damage and flash, but resist interruption with minimal pushback
		velocity = knockback * 0.2

## Telegraph visual helpers
func show_yellow_telegraph() -> void:
	if telegraph_mark:
		telegraph_mark.visible = true
	if yellow_mark:
		yellow_mark.visible = true
	if red_mark:
		red_mark.visible = false

func show_red_telegraph() -> void:
	if telegraph_mark:
		telegraph_mark.visible = true
	if yellow_mark:
		yellow_mark.visible = false
	if red_mark:
		red_mark.visible = true

func hide_telegraph() -> void:
	if telegraph_mark:
		telegraph_mark.visible = false
	if yellow_mark:
		yellow_mark.visible = false
	if red_mark:
		red_mark.visible = false

func set_slash_active(active: bool) -> void:
	if slash_arc:
		slash_arc.visible = active
