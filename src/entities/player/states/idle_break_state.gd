class_name IdleBreakState
extends State

## Estado de Idle Break extensível com sorteio aleatório anti-repetição e transição opcional de guarda nas costas (idle_sheathe).
## Armas na cintura (dagger, crossbow) ou personagem desarmado entram direto no Idle Break sorteado.

enum Phase {
	SHEATHING,
	PLAYING_BREAK
}

@export_group("Idle Break Pool")
## Lista de animações de Idle Break sorteadas aleatoriamente após a espera em Idle.
@export var idle_break_animations: Array[StringName] = [&"idle_break_1"]
## Tempo opcional (s) para sortear outro Idle Break quando a animação atual é em loop (0 = mantém até o jogador agir).
@export_range(0.0, 30.0, 0.5, "suffix:s") var loop_break_switch_interval: float = 0.0

var player: Player
var _phase: Phase = Phase.PLAYING_BREAK
var _active_break_anim: StringName = &""
var _last_picked_break: StringName = &""
var _break_elapsed: float = 0.0


func enter() -> void:
	player = character as Player
	if not player:
		return
	player.velocity.x = 0.0
	_break_elapsed = 0.0

	_active_break_anim = _pick_random_break_animation()
	if _active_break_anim == &"":
		state_machine.transition_to("idle")
		return

	var has_sheathe: bool = (
		player.weapon != null
		and not player.are_weapons_hidden
		and player.weapon.can_use_back_sheathe()
		and player.player_sprite != null
		and player.player_sprite.sprite_frames != null
		and player.player_sprite.sprite_frames.has_animation(&"idle_sheathe")
	)

	if has_sheathe:
		_phase = Phase.SHEATHING
		player.play_animation(&"idle_sheathe")
		if player.player_sprite:
			player.player_sprite.frame = 0
		player._update_weapon_socket_for_frame(&"idle_sheathe", 0)
	else:
		_start_break_animation()


func exit() -> void:
	_break_elapsed = 0.0
	if player:
		player.stop_animation()


func handle_incoming_hit(_damage: float, _knockback: Vector2, _hitstop: float, _incoming_hitbox: Hitbox) -> bool:
	state_machine.transition_to("idle")
	return false


func physics_update(delta: float) -> void:
	if not player:
		return

	if not player.is_on_floor():
		state_machine.transition_to("fall")
		return

	if player.is_input_locked:
		state_machine.transition_to("idle")
		return

	if player.jump_buffer_timer > 0.0:
		player.jump_buffer_timer = 0.0
		state_machine.transition_to("jump")
		return

	if player.is_crouch_requested():
		state_machine.transition_to("crouch")
		return

	if Input.is_action_just_pressed("heal"):
		state_machine.transition_to("heal")
		return

	if Input.is_action_just_pressed("defend") and player.can_defend():
		state_machine.transition_to("guard")
		return

	if (Input.is_action_pressed("attack_primary") or player.attack_buffer_timer > 0.0) and player.can_attack():
		player.attack_buffer_timer = 0.0
		if player.is_ranged_weapon_equipped():
			state_machine.transition_to("rangedattack")
		else:
			state_machine.transition_to("attack")
		return

	if player.is_slide_requested():
		state_machine.transition_to("slide")
		return

	var direction := Input.get_axis("move_left", "move_right")
	if absf(direction) > 0.1:
		state_machine.transition_to("run")
		return

	player.move_and_slide()

	if not player.player_sprite or not player.player_sprite.sprite_frames:
		state_machine.transition_to("idle")
		return

	match _phase:
		Phase.SHEATHING:
			if player.player_sprite.animation == &"idle_sheathe" and not player.player_sprite.is_playing():
				_start_break_animation()
		Phase.PLAYING_BREAK:
			var is_looping: bool = player.player_sprite.sprite_frames.get_animation_loop(_active_break_anim)
			if not is_looping:
				if player.player_sprite.animation == _active_break_anim and not player.player_sprite.is_playing():
					state_machine.transition_to("idle")
			elif loop_break_switch_interval > 0.0:
				_break_elapsed += delta
				if _break_elapsed >= loop_break_switch_interval:
					var valid := _get_valid_break_animations()
					if valid.size() >= 2:
						_active_break_anim = _pick_random_break_animation()
						_start_break_animation()
					else:
						_break_elapsed = 0.0


func _start_break_animation() -> void:
	_phase = Phase.PLAYING_BREAK
	_break_elapsed = 0.0
	if _active_break_anim == &"" or not player or not player.player_sprite:
		state_machine.transition_to("idle")
		return
	player.play_animation(_active_break_anim)
	player.player_sprite.frame = 0
	player._update_weapon_socket_for_frame(_active_break_anim, 0)


func _get_valid_break_animations() -> Array[StringName]:
	var valid: Array[StringName] = []
	if not player or not player.player_sprite or not player.player_sprite.sprite_frames:
		return valid
	for anim_name in idle_break_animations:
		if anim_name != &"" and player.player_sprite.sprite_frames.has_animation(anim_name):
			valid.append(anim_name)
	return valid


func _pick_random_break_animation() -> StringName:
	var valid := _get_valid_break_animations()
	if valid.is_empty():
		return &""
	if valid.size() == 1:
		_last_picked_break = valid[0]
		return valid[0]
	var candidates: Array[StringName] = []
	for anim_name in valid:
		if anim_name != _last_picked_break:
			candidates.append(anim_name)
	var chosen: StringName = candidates.pick_random() if not candidates.is_empty() else valid.pick_random()
	_last_picked_break = chosen
	return chosen
