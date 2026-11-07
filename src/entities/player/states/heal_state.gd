class_name HealState
extends State

## Heal State: Garrafa de Chá da Mãe (Health Flask).
## Canalização estacionária de 0.55s com telegraph diegético esmeralda.
## Se interrompido por dano inimigo, a cura falha mas a carga é preservada (padrão Nine Sols).

var player: Player
var channel_timer: float = 0.0
var is_channeling: bool = false
var original_body_color: Color = Color(0.85, 0.72, 0.52, 1.0)

func enter() -> void:
	player = character as Player
	channel_timer = 0.0
	is_channeling = false
	
	if not player:
		state_machine.transition_to("idle")
		return

	if player.body_polygon:
		original_body_color = player.body_polygon.color

	if not player.is_on_floor():
		state_machine.transition_to("fall")
		return

	# Se não tiver cargas de chá: não canaliza, dispara bark apenas se o anterior tiver se dissipado completamente
	if player.current_flask_charges <= 0:
		if not player.is_bark_active():
			var bark_text: String = LocalizationService.get_random_variant("BARK_TEA_EMPTY", 4)
			player.show_bark(bark_text)
		state_machine.transition_to("idle")
		return
	
	# Se a vida já estiver cheia (100%), não gasta o chá
	if player.current_health >= player.max_health:
		state_machine.transition_to("idle")
		return

	# Inicia canalização estacionária
	is_channeling = true
	player.velocity.x = 0.0
	
	if player.body_polygon:
		player.body_polygon.color = Color(0.2, 0.95, 0.5, 1.0)

func exit() -> void:
	if is_channeling and player:
		ProgressionManager.apply_skin_to_player(player)
	is_channeling = false

func handle_incoming_hit(_damage: float, _knockback: Vector2, _hitstop: float, _incoming_hitbox: Hitbox) -> bool:
	# Padrão Nine Sols: interrompe a canalização imediatamente, preservando a carga intacta
	if is_channeling and player:
		ProgressionManager.apply_skin_to_player(player)
	is_channeling = false
	state_machine.transition_to("idle")
	return false # Deixa o dano, recuo e hitstop serem processados normalmente pelo player

func physics_update(delta: float) -> void:
	if not is_channeling:
		return
		
	if not player.is_on_floor():
		state_machine.transition_to("fall")
		return
		
	# Trava pés no chão
	player.velocity.x = 0.0
	channel_timer += delta
	
	# Pulso visual esmeralda diegético no tronco durante a canalização
	if player.body_polygon:
		var pulse: float = (sin(channel_timer * 20.0) + 1.0) * 0.5
		player.body_polygon.color = original_body_color.lerp(Color(0.2, 0.95, 0.5, 1.0), 0.5 + pulse * 0.5)
	
	if channel_timer >= player.flask_channel_duration:
		_complete_heal()

func _complete_heal() -> void:
	if player.current_flask_charges > 0:
		player.current_flask_charges -= 1
		var heal_amount: float = player.max_health * player.flask_heal_percent * ProgressionManager.get_tea_heal_multiplier()
		player.current_health = minf(player.current_health + heal_amount, player.max_health)
		player.emit_signal("flask_charges_changed", player.current_flask_charges, player.max_flask_charges)
		ProgressionManager.record_tea_consumed()
		
		# Feedback sutil de sucesso: flash de luz rápida
		if player.flash_material:
			player.flash_timer = 0.12
			player.flash_material.set_shader_parameter("flash_active", true)
		
	state_machine.transition_to("idle")
