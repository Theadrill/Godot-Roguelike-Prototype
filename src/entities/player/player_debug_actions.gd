class_name PlayerDebugActions
extends RefCounted

## Sub-controlador de atalhos e comandos de debug em runtime do Player (teclas T, Y, troca rápida de armas/modificadores).
## Mantém lógica de inspeção/cheat fora da classe principal Player de produção.

const RESERVE_WEAPON_PATHS: Array[String] = [
	"res://src/entities/equipment/bows/weapon_bow_base.tres",
	"res://src/entities/equipment/crossbows/weapon_crossbow_base.tres",
	"res://src/entities/equipment/swords/weapon_sword_base.tres",
	"res://src/entities/equipment/axes/weapon_axe_base.tres",
	"res://src/entities/equipment/hammers/weapon_hammer_base.tres",
	"res://src/entities/equipment/staffs/weapon_staff_base.tres",
	"res://src/entities/equipment/daggers/weapon_dagger_base.tres"
]

var _player: CharacterBody2D = null
var _reserve_cycle_idx: int = -1


func setup(player_ref: CharacterBody2D) -> void:
	_player = player_ref


## Processa atalhos de debug em _unhandled_input; retorna true se o evento foi tratado.
func handle_debug_input(event: InputEvent) -> bool:
	if not OS.is_debug_build():
		return false
	if event.is_action_pressed("cycle_weapon_debug") and not event.is_echo():
		cycle_reserve_weapon()
		return true
	if event.is_action_pressed("toggle_shield_repulsion_debug") and not event.is_echo():
		toggle_shield_repulsion()
		return true
	if event.is_action_pressed("cycle_energize_debug") and not event.is_echo():
		_player.cycle_axe_energize_profile_debug()
		return true
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_T:
			cycle_enemy_tier_live()
			return true
	return false


## Alterna a arma reserva (costas) entre todas as categorias base para testes rápidos.
func cycle_reserve_weapon() -> void:
	var secondary: WeaponData = _player.secondary_weapon
	if _reserve_cycle_idx < 0 and secondary:
		for i in range(RESERVE_WEAPON_PATHS.size()):
			var base_name: String = RESERVE_WEAPON_PATHS[i].get_file().get_basename()
			if not secondary.resource_path.is_empty() and base_name in secondary.resource_path:
				_reserve_cycle_idx = i
				break

	_reserve_cycle_idx = (_reserve_cycle_idx + 1) % RESERVE_WEAPON_PATHS.size()
	var next_res := load(RESERVE_WEAPON_PATHS[_reserve_cycle_idx]) as WeaponData
	if _player.weapon and next_res and next_res.equipment_name == _player.weapon.equipment_name:
		_reserve_cycle_idx = (_reserve_cycle_idx + 1) % RESERVE_WEAPON_PATHS.size()
		next_res = load(RESERVE_WEAPON_PATHS[_reserve_cycle_idx]) as WeaponData

	if next_res:
		_player.equip_secondary_weapon(next_res.duplicate() as WeaponData)


## Alterna em runtime o modificador de onda repulsiva no escudo equipado.
func toggle_shield_repulsion() -> void:
	if _player.shield:
		if not _player.shield.resource_path.is_empty():
			_player.equip_shield(_player.shield.duplicate() as ShieldData)
		_player.shield.has_repulsion_modifier = not _player.shield.has_repulsion_modifier


## Alterna em tempo real o nível simulado do Player para escalar Tiers 1/2/3 dos inimigos na cena.
func cycle_enemy_tier_live() -> void:
	match _player.player_level:
		1:
			_player.player_level = 4 # Tier 2 (Veterano)
		4:
			_player.player_level = 8 # Tier 3 (Elite)
		_:
			_player.player_level = 1 # Tier 1 (Recruta)

	var tier_num: int = 1
	var tier_name: String = TranslationServer.translate("UI_TIER_RECRUIT")
	if _player.player_level >= 8:
		tier_num = 3
		tier_name = TranslationServer.translate("UI_TIER_ELITE")
	elif _player.player_level >= 4:
		tier_num = 2
		tier_name = TranslationServer.translate("UI_TIER_VETERAN")

	var tree: SceneTree = _player.get_tree()
	if not tree:
		return

	for enemy in tree.get_nodes_in_group("enemies"):
		if enemy.has_method("apply_tier_by_level"):
			enemy.apply_tier_by_level(_player.player_level)
		if enemy.has_method("respawn") and enemy.respawn_enabled:
			enemy.respawn()

	var hud := _player.get_node_or_null("HUD") as CanvasLayer
	if not hud and tree.current_scene:
		hud = tree.current_scene.find_child("HUD", true, false) as CanvasLayer
	if hud and hud.has_method("show_tier_toast"):
		hud.show_tier_toast(tier_num, tier_name, _player.player_level)
