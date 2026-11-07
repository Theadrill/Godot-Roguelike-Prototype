extends Node

## ProgressionManager: Autoload central para gerenciar modificadores temporários da run atual
## e os níveis permanentes da linhagem (Chás da Mãe e Forja do Irmão).

signal run_modifiers_updated
signal permanent_upgrades_updated

# Modificadores Temporários da Run (Resetados a cada despertar)
var active_elixir: String = "" # "folha_de_fogo" ou "caldo_revigorante"
var active_death_blessing: String = "" # "onda_espectral" ou "olhar_da_ruina"

# Aprimoramentos Permanentes da Linhagem (Chás da Mãe)
var tea_stone_root_level: int = 1
var tea_stone_root_duplicates: int = 0

var tea_mountain_chamomile_level: int = 1
var tea_mountain_chamomile_duplicates: int = 0

# Aprimoramentos Permanentes da Forja (Irmão)
var weapon_sword_level: int = 1
var weapon_sword_duplicates: int = 0

var weapon_bow_level: int = 1
var weapon_bow_duplicates: int = 0

# Estado de Armas Equipadas no Hub
var are_weapons_equipped: bool = false

func reset_daily_run() -> void:
	active_elixir = ""
	active_death_blessing = ""
	run_modifiers_updated.emit()

func select_elixir(id: String) -> void:
	if active_elixir == id:
		active_elixir = "" # Permite alternar
	else:
		active_elixir = id
	run_modifiers_updated.emit()

func select_death_blessing(id: String) -> void:
	active_death_blessing = id
	run_modifiers_updated.emit()

func get_bonus_max_hp() -> float:
	return float(tea_stone_root_level - 1) * 15.0

func get_tea_heal_multiplier() -> float:
	return 1.0 + float(tea_mountain_chamomile_level - 1) * 0.05

func get_sword_base_damage() -> float:
	return 15.0 + float(weapon_sword_level - 1) * 3.0

func get_bow_base_damage() -> float:
	return 12.0 + float(weapon_bow_level - 1) * 2.5

## Aplica os bônus e modificadores ativos na entidade Player
func apply_to_player(player: Player) -> void:
	if not player:
		return

	# 1. Bônus de Vida da Linhagem (Chá de Raiz-de-Pedra)
	var base_hp: float = 100.0
	player.max_health = base_hp + get_bonus_max_hp()
	player.current_health = player.max_health

	# 2. Elixir: Caldo Revigorante (+1 Carga Inicial do Frasco de Chá)
	if active_elixir == "caldo_revigorante":
		player.max_flask_charges = 2
		player.current_flask_charges = 2
	else:
		player.max_flask_charges = 1
		player.current_flask_charges = 1
	player.flask_charges_changed.emit(player.current_flask_charges, player.max_flask_charges)

	# 3. Metadados de combate para a run
	player.set_meta("mod_folha_de_fogo", active_elixir == "folha_de_fogo")
	player.set_meta("mod_onda_espectral", active_death_blessing == "onda_espectral")
	player.set_meta("mod_olhar_da_ruina", active_death_blessing == "olhar_da_ruina")

	# 4. Escala de dano das armas caso equipadas
	if player.weapon:
		if player.weapon.equipment_name == "Espada Rústica" or player.weapon.equipment_name.contains("Espada"):
			player.weapon.base_damage = get_sword_base_damage()
	if player.secondary_weapon:
		if player.secondary_weapon.equipment_name == "Arco de Caça" or player.secondary_weapon.equipment_name.contains("Arco"):
			player.secondary_weapon.base_damage = get_bow_base_damage()
