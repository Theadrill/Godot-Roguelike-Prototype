extends Node

const EnemyCategories = preload("res://src/core/enemy_category.gd")

## ProgressionManager: Autoload central para gerenciar modificadores temporários da run atual,
## níveis permanentes da linhagem (Chás, Forja, Roupas), estatísticas e desbloqueio de pedestais.

signal run_modifiers_updated
signal permanent_upgrades_updated
signal skin_changed(new_skin_id: String)

# Modificadores Temporários da Run (Resetados a cada despertar)
var active_elixir: String = "" # "folha_de_fogo" ou "caldo_revigorante"
var active_death_blessing: String = "" # "onda_espectral" ou "olhar_da_ruina"

# Aprimoramentos Permanentes da Linhagem (Chás da Mãe)
var tea_stone_root_level: int = 1
var tea_stone_root_duplicates: int = 0

var tea_mountain_chamomile_level: int = 1
var tea_mountain_chamomile_duplicates: int = 0

# Roupas & Túnicas (Skins da Mãe)
var active_skin_id: String = "default" # "default" (Viajante) ou "crimson" (Manto Carmesim)

# Aprimoramentos Permanentes da Forja (Irmão)
var weapon_sword_level: int = 1
var weapon_sword_duplicates: int = 0

var weapon_bow_level: int = 1
var weapon_bow_duplicates: int = 0

# Estado de Armas Equipadas no Hub
var are_weapons_equipped: bool = false

# --- SISTEMA DE RASTREIO GLOBAL (Metaprogressão e Estatísticas) ---
var total_souls_collected: int = 0
var kills_by_category: Dictionary = {
	EnemyCategories.Category.UNDEAD: 0,
	EnemyCategories.Category.BEAST: 0,
	EnemyCategories.Category.ABOMINATION: 0,
	EnemyCategories.Category.HUMANOID: 0,
	EnemyCategories.Category.BOSS: 0
}
var elite_kills_count: int = 0
var bosses_defeated_list: Array[String] = []
var weapons_discovered_count: int = 1
var shield_upgrades_performed: int = 0
var perfect_parries_count: int = 0
var total_deaths_count: int = 0

func reset_daily_run() -> void:
	active_elixir = ""
	active_death_blessing = ""
	total_deaths_count += 1
	run_modifiers_updated.emit()

func select_elixir(id: String) -> void:
	if active_elixir == id:
		active_elixir = ""
	else:
		active_elixir = id
	run_modifiers_updated.emit()

func select_death_blessing(id: String) -> void:
	active_death_blessing = id
	run_modifiers_updated.emit()

func select_skin(skin_id: String) -> void:
	active_skin_id = skin_id
	skin_changed.emit(active_skin_id)

func get_bonus_max_hp() -> float:
	return float(tea_stone_root_level - 1) * 15.0

func get_tea_heal_multiplier() -> float:
	return 1.0 + float(tea_mountain_chamomile_level - 1) * 0.05

func get_sword_base_damage() -> float:
	return 15.0 + float(weapon_sword_level - 1) * 3.0

func get_bow_base_damage() -> float:
	return 12.0 + float(weapon_bow_level - 1) * 2.5

# --- Rastreamento de Eventos de Combate ---
func add_souls(amount: int) -> void:
	total_souls_collected += amount

func record_kill(category: EnemyCategories.Category, is_elite: bool = false) -> void:
	var current: int = kills_by_category.get(category, 0)
	kills_by_category[category] = current + 1
	if is_elite:
		elite_kills_count += 1

func record_boss_defeat(boss_id: String) -> void:
	if not bosses_defeated_list.has(boss_id):
		bosses_defeated_list.append(boss_id)

func record_perfect_parry() -> void:
	perfect_parries_count += 1

func record_shield_upgrade() -> void:
	shield_upgrades_performed += 1

# --- Condições de Desbloqueio dos 6 Pedestais de Armas ---
func is_weapon_pedestal_unlocked(index: int) -> bool:
	match index:
		0: return true # Espada Rústica inicial
		1: return weapons_discovered_count >= 4
		2: return bosses_defeated_list.size() >= 3
		3: return elite_kills_count >= 10
		4: return total_souls_collected >= 500
		5: return kills_by_category.get(EnemyCategories.Category.ABOMINATION, 0) >= 50
		_: return false

func get_weapon_pedestal_condition_text(index: int) -> String:
	match index:
		0: return "Liberado (Espada Rústica)"
		1: return "Descobrir 4 armas nas expedições (%d/4)" % weapons_discovered_count
		2: return "Derrotar 3 chefões diferentes (%d/3)" % bosses_defeated_list.size()
		3: return "Derrotar 10 guardas de elite (%d/10)" % elite_kills_count
		4: return "Sugar 500 essências de monstros (%d/500)" % total_souls_collected
		5: return "Derrotar 50 abominações do Caos (%d/50)" % kills_by_category.get(EnemyCategories.Category.ABOMINATION, 0)
		_: return "Condição Desconhecida"

# --- Condições de Desbloqueio dos 3 Pedestais de Escudos ---
func is_shield_pedestal_unlocked(index: int) -> bool:
	match index:
		0: return true # Broquel de Ferro inicial
		1: return shield_upgrades_performed >= 3
		2: return perfect_parries_count >= 25
		_: return false

func get_shield_pedestal_condition_text(index: int) -> String:
	match index:
		0: return "Liberado (Broquel de Ferro)"
		1: return "Realizar 3 aprimoramentos de escudo (%d/3)" % shield_upgrades_performed
		2: return "Executar 25 parries perfeitos (%d/25)" % perfect_parries_count
		_: return "Condição Desconhecida"

## Aplica os bônus, modificadores e skin ativa na entidade Player
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

	# 5. Aplicação cosmética da Skin/Túnica
	apply_skin_to_player(player)

func apply_skin_to_player(player: Player) -> void:
	if not player or not player.body_polygon:
		return
	if active_skin_id == "crimson":
		player.body_polygon.color = Color(0.78, 0.18, 0.22, 1.0) # Vermelho carmesim vibrante
	else:
		player.body_polygon.color = Color(0.85, 0.72, 0.52, 1.0) # Bege rústico do viajante
