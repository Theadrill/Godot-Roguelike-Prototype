extends Node

## ProgressionManager: Autoload central para gerenciar modificadores temporários da run atual,
## níveis permanentes da linhagem (Chás, Forja, Roupas), estatísticas e desbloqueio de pedestais.
## Inclui persistência criptografada em AES-256 no disco (user://saves/slot_1/meta_progression.dat).

signal run_modifiers_updated
signal permanent_upgrades_updated
signal skin_changed(new_skin_id: String)
signal metrics_updated

const SAVE_DIR: String = "user://saves/slot_1"
const SAVE_FILE_PATH: String = "user://saves/slot_1/meta_progression.dat"
const SAVE_SECRET_KEY: String = "SeveredDawn_EncryptedSalt_2026_xK9"

# Debug / Cheat Override (opcional para testes imediatos)
var debug_unlock_all_pedestals: bool = false

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
var weapon_sword_duplicates: int = 2 # 2 receitas disponíveis inicialmente para teste de aprimoramento e diálogos

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
var weapons_discovered_list: Array[String] = ["sword_base", "shield_base"]
var shield_upgrades_performed: int = 0
var perfect_parries_count: int = 0
var rally_hp_recovered: float = 0.0
var teas_consumed_count: int = 0
var total_deaths_count: int = 0
var pet_dog_count: int = 0
var pet_cat_count: int = 0

func _ready() -> void:
	load_profile()

func reset_daily_run() -> void:
	active_elixir = ""
	active_death_blessing = ""
	total_deaths_count += 1
	save_profile()
	run_modifiers_updated.emit()
	metrics_updated.emit()

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
	save_profile()
	skin_changed.emit(active_skin_id)

func get_bonus_max_hp() -> float:
	return float(tea_stone_root_level - 1) * 15.0

func get_tea_heal_multiplier() -> float:
	return 1.0 + float(tea_mountain_chamomile_level - 1) * 0.05

func get_sword_base_damage() -> float:
	return 15.0 + float(weapon_sword_level - 1) * 3.0

func get_bow_base_damage() -> float:
	return 12.0 + float(weapon_bow_level - 1) * 2.5

# --- Rastreamento de Eventos de Combate & Carreira ---
func add_souls(amount: int) -> void:
	total_souls_collected += amount
	save_profile()
	metrics_updated.emit()

func record_kill(category: EnemyCategories.Category, is_elite: bool = false) -> void:
	var current: int = kills_by_category.get(category, 0)
	kills_by_category[category] = current + 1
	if is_elite:
		elite_kills_count += 1
	save_profile()
	metrics_updated.emit()

func record_boss_defeat(boss_id: String) -> void:
	if not bosses_defeated_list.has(boss_id):
		bosses_defeated_list.append(boss_id)
		var current_boss_kills: int = kills_by_category.get(EnemyCategories.Category.BOSS, 0)
		kills_by_category[EnemyCategories.Category.BOSS] = current_boss_kills + 1
		save_profile()
		metrics_updated.emit()

func record_perfect_parry() -> void:
	perfect_parries_count += 1
	save_profile()
	metrics_updated.emit()

func record_rally_heal(amount: float) -> void:
	rally_hp_recovered += amount
	save_profile()
	metrics_updated.emit()

func record_tea_consumed() -> void:
	teas_consumed_count += 1
	save_profile()
	metrics_updated.emit()

func record_shield_upgrade() -> void:
	shield_upgrades_performed += 1
	save_profile()
	metrics_updated.emit()

const WEAPON_DISPLAY_NAMES: Dictionary = {
	"sword_base": "Espada do Viajante",
	"weapon_sword_base": "Espada do Viajante",
	"shield_base": "Broquel de Ferro",
	"shield_buckler_base": "Broquel de Ferro",
	"bow_base": "Arco de Caça",
	"weapon_bow_base": "Arco de Caça",
	"dagger_base": "Adagas Gêmeas",
	"weapon_dagger_base": "Adagas Gêmeas",
	"hammer_base": "Martelo de Guerra",
	"weapon_hammer_base": "Martelo de Guerra",
	"staff_base": "Cajado do Vazio",
	"weapon_staff_base": "Cajado do Vazio",
	"crossbow_base": "Besta de Repetição",
	"weapon_crossbow_base": "Besta de Repetição"
}

func get_weapon_display_name(weapon_id: String) -> String:
	var clean_id := weapon_id.to_lower().strip_edges()
	if WEAPON_DISPLAY_NAMES.has(clean_id):
		return WEAPON_DISPLAY_NAMES[clean_id]
	if clean_id.begins_with("weapon_test_"):
		return "Arma de Teste " + clean_id.trim_prefix("weapon_test_")
	return clean_id.replace("_", " ").capitalize()

func get_boss_display_name(boss_id: String) -> String:
	var clean_id := boss_id.to_lower().strip_edges()
	if clean_id.begins_with("boss_test_"):
		return "Chefão de Teste " + clean_id.trim_prefix("boss_test_")
	return clean_id.replace("_", " ").capitalize()

func record_weapon_discovered(weapon_id: String) -> void:
	if not weapons_discovered_list.has(weapon_id):
		weapons_discovered_list.append(weapon_id)
		save_profile()
		metrics_updated.emit()

func record_pet_interact(pet_name: String) -> void:
	if pet_name.to_lower().contains("dog") or pet_name.to_lower().contains("preta"):
		pet_dog_count += 1
	elif pet_name.to_lower().contains("cat") or pet_name.to_lower().contains("bela"):
		pet_cat_count += 1
	save_profile()
	metrics_updated.emit()

# --- Condições de Desbloqueio dos 6 Pedestais de Armas ---
func is_weapon_pedestal_unlocked(index: int) -> bool:
	if debug_unlock_all_pedestals:
		return true
	match index:
		0: return true # Espada Rústica inicial
		1: return weapons_discovered_list.size() >= 4 or true # Mantém acessível por padrão para testes de swap
		2: return bosses_defeated_list.size() >= 3 or true # Mantém acessível por padrão para testes de swap
		3: return elite_kills_count >= 10
		4: return total_souls_collected >= 500
		5: return kills_by_category.get(EnemyCategories.Category.ABOMINATION, 0) >= 50
		_: return false

func get_weapon_pedestal_condition_text(index: int) -> String:
	match index:
		0: return "Liberado (Espada Rústica)"
		1: 
			var count: int = weapons_discovered_list.size()
			return "Descobrir 4 armas (%d/4)" % count
		2: 
			var count: int = bosses_defeated_list.size()
			return "Derrotar 3 chefões diferentes (%d/3)" % count
		3: return "Derrotar 10 guardas de elite (%d/10)" % elite_kills_count
		4: return "Sugar 500 essências de monstros (%d/500)" % total_souls_collected
		5: return "Derrotar 50 abominações do Caos (%d/50)" % kills_by_category.get(EnemyCategories.Category.ABOMINATION, 0)
		_: return "Condição Desconhecida"

# --- Condições de Desbloqueio dos 3 Pedestais de Escudos ---
func is_shield_pedestal_unlocked(index: int) -> bool:
	if debug_unlock_all_pedestals:
		return true
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

# --- PERSISTÊNCIA CRIPTOGRAFADA AES-256 ---
func save_profile() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
		
	var data: Dictionary = {
		"version": 1,
		"active_skin_id": active_skin_id,
		"tea_stone_root_level": tea_stone_root_level,
		"tea_stone_root_duplicates": tea_stone_root_duplicates,
		"tea_mountain_chamomile_level": tea_mountain_chamomile_level,
		"tea_mountain_chamomile_duplicates": tea_mountain_chamomile_duplicates,
		"weapon_sword_level": weapon_sword_level,
		"weapon_sword_duplicates": weapon_sword_duplicates,
		"weapon_bow_level": weapon_bow_level,
		"weapon_bow_duplicates": weapon_bow_duplicates,
		"shield_upgrades_performed": shield_upgrades_performed,
		"total_souls_collected": total_souls_collected,
		"kills_undead": kills_by_category.get(EnemyCategories.Category.UNDEAD, 0),
		"kills_beast": kills_by_category.get(EnemyCategories.Category.BEAST, 0),
		"kills_abomination": kills_by_category.get(EnemyCategories.Category.ABOMINATION, 0),
		"kills_humanoid": kills_by_category.get(EnemyCategories.Category.HUMANOID, 0),
		"kills_boss": kills_by_category.get(EnemyCategories.Category.BOSS, 0),
		"elite_kills_count": elite_kills_count,
		"bosses_defeated_list": bosses_defeated_list,
		"weapons_discovered_list": weapons_discovered_list,
		"perfect_parries_count": perfect_parries_count,
		"rally_hp_recovered": rally_hp_recovered,
		"teas_consumed_count": teas_consumed_count,
		"total_deaths_count": total_deaths_count,
		"pet_dog_count": pet_dog_count,
		"pet_cat_count": pet_cat_count
	}
	
	var json_str: String = JSON.stringify(data)
	var file := FileAccess.open_encrypted_with_pass(SAVE_FILE_PATH, FileAccess.WRITE, SAVE_SECRET_KEY)
	if file:
		file.store_string(json_str)
		file.flush()
		file.close()

func load_profile() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		save_profile()
		return
		
	var file := FileAccess.open_encrypted_with_pass(SAVE_FILE_PATH, FileAccess.READ, SAVE_SECRET_KEY)
	if not file:
		return
		
	var content: String = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		return
		
	var data: Dictionary = json.data as Dictionary
	if not data:
		return
		
	active_skin_id = data.get("active_skin_id", "default")
	tea_stone_root_level = int(data.get("tea_stone_root_level", 1))
	tea_stone_root_duplicates = int(data.get("tea_stone_root_duplicates", 0))
	tea_mountain_chamomile_level = int(data.get("tea_mountain_chamomile_level", 1))
	tea_mountain_chamomile_duplicates = int(data.get("tea_mountain_chamomile_duplicates", 0))
	
	weapon_sword_level = int(data.get("weapon_sword_level", 1))
	weapon_sword_duplicates = int(data.get("weapon_sword_duplicates", 2))
	weapon_bow_level = int(data.get("weapon_bow_level", 1))
	weapon_bow_duplicates = int(data.get("weapon_bow_duplicates", 0))
	
	shield_upgrades_performed = int(data.get("shield_upgrades_performed", 0))
	total_souls_collected = int(data.get("total_souls_collected", 0))
	
	kills_by_category[EnemyCategories.Category.UNDEAD] = int(data.get("kills_undead", 0))
	kills_by_category[EnemyCategories.Category.BEAST] = int(data.get("kills_beast", 0))
	kills_by_category[EnemyCategories.Category.ABOMINATION] = int(data.get("kills_abomination", 0))
	kills_by_category[EnemyCategories.Category.HUMANOID] = int(data.get("kills_humanoid", 0))
	kills_by_category[EnemyCategories.Category.BOSS] = int(data.get("kills_boss", 0))
	
	elite_kills_count = int(data.get("elite_kills_count", 0))
	
	var b_list = data.get("bosses_defeated_list", [])
	bosses_defeated_list.clear()
	for b in b_list:
		bosses_defeated_list.append(str(b))
		
	var w_list = data.get("weapons_discovered_list", ["sword_base", "shield_base"])
	weapons_discovered_list.clear()
	for w in w_list:
		weapons_discovered_list.append(str(w))
		
	perfect_parries_count = int(data.get("perfect_parries_count", 0))
	rally_hp_recovered = float(data.get("rally_hp_recovered", 0.0))
	teas_consumed_count = int(data.get("teas_consumed_count", 0))
	total_deaths_count = int(data.get("total_deaths_count", 0))
	pet_dog_count = int(data.get("pet_dog_count", 0))
	pet_cat_count = int(data.get("pet_cat_count", 0))
	
	permanent_upgrades_updated.emit()
	metrics_updated.emit()

func reset_profile() -> void:
	tea_stone_root_level = 1
	tea_stone_root_duplicates = 0
	tea_mountain_chamomile_level = 1
	tea_mountain_chamomile_duplicates = 0
	active_skin_id = "default"
	weapon_sword_level = 1
	weapon_sword_duplicates = 2
	weapon_bow_level = 1
	weapon_bow_duplicates = 0
	shield_upgrades_performed = 0
	total_souls_collected = 0
	kills_by_category = {
		EnemyCategories.Category.UNDEAD: 0,
		EnemyCategories.Category.BEAST: 0,
		EnemyCategories.Category.ABOMINATION: 0,
		EnemyCategories.Category.HUMANOID: 0,
		EnemyCategories.Category.BOSS: 0
	}
	elite_kills_count = 0
	bosses_defeated_list = []
	weapons_discovered_list = ["sword_base", "shield_base"]
	perfect_parries_count = 0
	rally_hp_recovered = 0.0
	teas_consumed_count = 0
	total_deaths_count = 0
	pet_dog_count = 0
	pet_cat_count = 0
	save_profile()
	permanent_upgrades_updated.emit()
	metrics_updated.emit()

## Aplica os bônus, modificadores e skin ativa na entidade Player
func apply_to_player(player: CharacterBody2D) -> void:
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

func apply_skin_to_player(player: CharacterBody2D) -> void:
	if not player or not player.body_polygon:
		return
	if active_skin_id == "crimson":
		player.body_polygon.color = Color(0.78, 0.18, 0.22, 1.0) # Vermelho carmesim vibrante
	else:
		player.body_polygon.color = Color(0.85, 0.72, 0.52, 1.0) # Bege rústico do viajante
