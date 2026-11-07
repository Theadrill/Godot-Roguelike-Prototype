class_name DebugMetricsPanel
extends CanvasLayer

## Painel de Debug em tempo real para monitorar Métricas, Persistência e Desbloqueio dos Pedestais.
## Acionado a qualquer momento com a tecla F3 (Teclado) ou botão Select/Back (Gamepad).

@onready var main_panel: Panel = $MainPanel
@onready var metrics_label: RichTextLabel = $MainPanel/ContentHBox/MetricsScroll/MetricsLabel
@onready var btn_close: Button = $MainPanel/Header/BtnClose

# Botões de Teste
@onready var btn_add_souls: Button = $MainPanel/ContentHBox/ActionsScroll/ActionsVBox/BtnAddSouls
@onready var btn_add_elite: Button = $MainPanel/ContentHBox/ActionsScroll/ActionsVBox/BtnAddElite
@onready var btn_add_boss: Button = $MainPanel/ContentHBox/ActionsScroll/ActionsVBox/BtnAddBoss
@onready var btn_add_parry: Button = $MainPanel/ContentHBox/ActionsScroll/ActionsVBox/BtnAddParry
@onready var btn_add_weapon: Button = $MainPanel/ContentHBox/ActionsScroll/ActionsVBox/BtnAddWeapon
@onready var btn_add_shield_up: Button = $MainPanel/ContentHBox/ActionsScroll/ActionsVBox/BtnAddShieldUp
@onready var btn_add_abomination: Button = $MainPanel/ContentHBox/ActionsScroll/ActionsVBox/BtnAddAbomination
@onready var btn_pet_animals: Button = $MainPanel/ContentHBox/ActionsScroll/ActionsVBox/BtnPetAnimals
@onready var btn_toggle_cheat: Button = $MainPanel/ContentHBox/ActionsScroll/ActionsVBox/BtnToggleCheat
@onready var btn_save: Button = $MainPanel/ContentHBox/ActionsScroll/ActionsVBox/BtnSave
@onready var btn_reset: Button = $MainPanel/ContentHBox/ActionsScroll/ActionsVBox/BtnReset

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_buttons()
	ProgressionManager.metrics_updated.connect(_refresh_metrics)

func _setup_buttons() -> void:
	if btn_close:
		btn_close.pressed.connect(toggle_panel)
		
	btn_add_souls.pressed.connect(func() -> void: ProgressionManager.add_souls(50))
	btn_add_elite.pressed.connect(func() -> void: ProgressionManager.record_kill(EnemyCategories.Category.HUMANOID, true))
	btn_add_boss.pressed.connect(func() -> void: 
		var next_boss_id: String = "boss_test_" + str(ProgressionManager.bosses_defeated_list.size() + 1)
		ProgressionManager.record_boss_defeat(next_boss_id)
	)
	btn_add_parry.pressed.connect(func() -> void: 
		for i in range(5):
			ProgressionManager.record_perfect_parry()
	)
	btn_add_weapon.pressed.connect(func() -> void: 
		var next_w: String = "weapon_test_" + str(ProgressionManager.weapons_discovered_list.size() + 1)
		ProgressionManager.record_weapon_discovered(next_w)
	)
	btn_add_shield_up.pressed.connect(func() -> void: ProgressionManager.record_shield_upgrade())
	btn_add_abomination.pressed.connect(func() -> void: 
		for i in range(5):
			ProgressionManager.record_kill(EnemyCategories.Category.ABOMINATION, false)
	)
	btn_pet_animals.pressed.connect(func() -> void: 
		ProgressionManager.record_pet_interact("preta")
		ProgressionManager.record_pet_interact("bela")
	)
	btn_toggle_cheat.pressed.connect(func() -> void: 
		ProgressionManager.debug_unlock_all_pedestals = not ProgressionManager.debug_unlock_all_pedestals
		_refresh_metrics()
	)
	btn_save.pressed.connect(func() -> void: 
		ProgressionManager.save_profile()
		_refresh_metrics()
	)
	btn_reset.pressed.connect(func() -> void: 
		ProgressionManager.reset_profile()
		_refresh_metrics()
	)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_metrics"):
		get_viewport().set_input_as_handled()
		toggle_panel()
	elif visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		toggle_panel()

func toggle_panel() -> void:
	visible = not visible
	if visible:
		_refresh_metrics()
		await get_tree().process_frame
		btn_add_souls.grab_focus()

func _refresh_metrics() -> void:
	if not metrics_label:
		return
		
	var pm := ProgressionManager
	var bbcode: String = ""
	
	# Cabeçalho
	bbcode += "[b][color=#64d8cb]=== METAPROGRESSÃO & ESTATÍSTICAS DA LINHAGEM ===[/color][/b]\n"
	bbcode += "[color=#e0e0e0]Arquivo AES-256:[/color] [color=#ffcc80]user://saves/slot_1/meta_progression.dat[/color]\n\n"
	
	# Economia e Sobrevivência
	bbcode += "[b][color=#80cbc4]1. Economia & Sobrevivência:[/color][/b]\n"
	bbcode += "  • Almas Totais Sugadas: [color=#ffeb3b][b]%d[/b][/color]\n" % pm.total_souls_collected
	bbcode += "  • Mortes Registradas: [color=#ef5350]%d[/color]\n" % pm.total_deaths_count
	bbcode += "  • Frascos de Chá Bebidos: [color=#81c784]%d[/color]\n\n" % pm.teas_consumed_count
	
	# Maestria de Combate
	bbcode += "[b][color=#80cbc4]2. Maestria de Combate:[/color][/b]\n"
	bbcode += "  • Parries Perfeitos: [color=#4fc3f7][b]%d[/b][/color]\n" % pm.perfect_parries_count
	bbcode += "  • Vida Recuperada (Tactical Rally): [color=#81c784]%.1f HP[/color]\n" % pm.rally_hp_recovered
	bbcode += "  • Upgrades de Escudo: [color=#ffb74d]%d[/color]\n\n" % pm.shield_upgrades_performed
	
	# Bestiário e Abates
	bbcode += "[b][color=#80cbc4]3. Bestiário & Abates por Categoria:[/color][/b]\n"
	bbcode += "  • Mortos-Vivos / Zumbis: %d\n" % pm.kills_by_category.get(EnemyCategories.Category.UNDEAD, 0)
	bbcode += "  • Feras / Animais: %d\n" % pm.kills_by_category.get(EnemyCategories.Category.BEAST, 0)
	bbcode += "  • Abominações do Caos: [color=#ba68c8]%d[/color]\n" % pm.kills_by_category.get(EnemyCategories.Category.ABOMINATION, 0)
	bbcode += "  • Soldados / Humanoides: %d\n" % pm.kills_by_category.get(EnemyCategories.Category.HUMANOID, 0)
	bbcode += "  • Guardas de Elite: [color=#ff7043][b]%d[/b][/color]\n" % pm.elite_kills_count
	bbcode += "  • Chefões Únicos Vencidos: [color=#ff5252][b]%d[/b] (%s)[/color]\n\n" % [pm.bosses_defeated_list.size(), str(pm.bosses_defeated_list)]
	
	# Afeto & Hub
	bbcode += "[b][color=#80cbc4]4. Afeto no Hub:[/color][/b]\n"
	bbcode += "  • Carinhos na Preta (Cadela): %d\n" % pm.pet_dog_count
	bbcode += "  • Carinhos na Bela (Gata): %d\n" % pm.pet_cat_count
	bbcode += "  • Túnica Ativa: [color=#ffb74d]%s[/color]\n\n" % pm.active_skin_id
	
	# Pedestais de Armas
	bbcode += "[b][color=#64d8cb]=== ESTADO DOS PEDESTAIS DE ARMAS ===[/color][/b]\n"
	for i in range(6):
		var unlocked: bool = pm.is_weapon_pedestal_unlocked(i)
		var status_color: String = "#81c784" if unlocked else "#e57373"
		var status_text: String = "[DESBLOQUEADO]" if unlocked else "[TRANÇADO]"
		bbcode += "  • P%d: [color=%s]%s[/color] - %s\n" % [i + 1, status_color, status_text, pm.get_weapon_pedestal_condition_text(i)]
	bbcode += "\n"
	
	# Pedestais de Escudos
	bbcode += "[b][color=#64d8cb]=== ESTADO DOS PEDESTAIS DE ESCUDOS ===[/color][/b]\n"
	for j in range(3):
		var unlocked: bool = pm.is_shield_pedestal_unlocked(j)
		var status_color: String = "#81c784" if unlocked else "#e57373"
		var status_text: String = "[DESBLOQUEADO]" if unlocked else "[TRANÇADO]"
		bbcode += "  • E%d: [color=%s]%s[/color] - %s\n" % [j + 1, status_color, status_text, pm.get_shield_pedestal_condition_text(j)]
		
	if pm.debug_unlock_all_pedestals:
		bbcode += "\n[b][color=#ffeb3b]⚠ MODO CHEAT ATIVO: TODOS OS PEDESTAIS FORÇADOS A DESBLOQUEAR![/color][/b]"
		
	metrics_label.text = bbcode
