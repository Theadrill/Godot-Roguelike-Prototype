class_name WeaponData
extends EquipmentData

## ============================================================================
## RECURSO DE DADOS DE ARMA (WeaponData) — ARQUITETURA DE ATTACK SETS & SLASHES
## ============================================================================
## Guia completo em: 'docs/ARQUITETURA_ATTACK_SETS_E_SLASHES.md'
##
## COMO CRIAR UMA NOVA ARMA (EX: "ESPADA LONGA DO CAOS"):
## 1. DUPLICAR O ARQUIVO .TRES:
##    - No painel 'FileSystem' do Godot, clique com o botão direito em uma arma existente
##      (ex: 'src/entities/equipment/swords/weapon_sword_base.tres') e escolha 'Duplicate...'.
##    - Renomeie para a nova arma (ex: 'weapon_espada_do_caos.tres').
##
## 2. ESCOLHER O CONJUNTO DE ATAQUES (ATTACK SET):
##    - No grupo 'Combo & Attack Set (Moveset)', arraste um Set da pasta 'res://src/combat/sets/'
##      (ex: 'set_sword_standard.tres' ou 'set_hammer_crusher.tres') para o campo 'Attack Set'.
##    - O Set já define quais animações de ataque (attack1, attack2...) e quais slashes padrão
##      cada golpe vai tocar!
##
## 3. AJUSTAR O TAMANHO / POSIÇÃO DO SLASH PARA ESTA ARMA (SE ELA FOR MAIOR/MENOR):
##    - Se esta arma for mais comprida e o slash precisar ir +3 pixels para frente no eixo X:
##      Vá em 'Attack Slash Effect -> Slash Offset' e coloque Vector2(3, 0)!
##    - Esse valor (+3 no X) é SOMADO automaticamente à posição base do slash do Set!
##    - Se quiser que apenas o Ataque 2 tenha um ajuste extra além disso, use 'Slash Step Offsets'.
##    - Com 'Sync Hitbox With Slash' ativado, a área física de dano (Hitbox) avança e cresce
##      automaticamente junto com o seu slash!
## ============================================================================

const DEFAULT_WEAPON_GUIDE: String = (
	"GUIA RÁPIDO — COMO CONFIGURAR ESTA ARMA:\n"
	+ "1. DEFINIR O SET DE ATAQUES: No grupo 'Combo & Attack Set', arraste um arquivo de 'res://src/combat/sets/' para 'Attack Set'.\n"
	+ "2. AJUSTAR OFFSET DE TAMANHO (+X / +Y): Se esta arma é mais longa que a arma base do Set (ex: +3px), vá em 'Attack Slash Effect -> Slash Offset' e digite (3, 0). O corte e a Hitbox avançarão +3px automaticamente!\n"
	+ "3. TROCAR SLASHES POR GOLPE (OPCIONAL): Se esta arma tiver desenhos de corte exclusivos em cada golpe, preencha 'Slash Step Animations'. Se deixar vazio, ela usa os slashes padrão do Set.\n"
	+ "4. CRIAR UM NOVO SET: Duplique qualquer arquivo em 'res://src/combat/sets/' e edite a lista 'Steps' dele!"
)

enum WeaponCategory {
	MELEE,
	RANGED_BOW,
	RANGED_CROSSBOW,
	RANGED_SPELL
}

@export_group("Guia Rápido (Como Modificar Armas e Sets)")

## Manual interativo visível diretamente no Inspector do Godot explicando como configurar Sets e Offsets.
@export_multiline var guia_de_uso_da_arma: String = DEFAULT_WEAPON_GUIDE

@export_group("Weapon Identity")

## Define a categoria comportamental da arma (Corpo a Corpo, Arco, Besta ou Cajado/Magia).
@export var weapon_category: WeaponCategory = WeaponCategory.MELEE

## Nome de exibição da arma (sincronizado automaticamente com 'equipment_name').
@export var weapon_name: String = "Broadsword":
	set(value):
		weapon_name = value
		equipment_name = value

@export_group("Socket & Anchoring Profile")

## Perfil customizado de ancoragem frame a frame da arma na mão e nas costas do personagem.
## Arraste um arquivo '.tres' de 'res://src/entities/equipment/socket_profiles/' ou deixe vazio para usar o dropdown 'socket_profile'.
@export var custom_socket_profile: WeaponSocketProfile

## Perfil predefinido de ancoragem da arma (ex: sword, sword_2, dagger, hammer, axe, staff, bow, crossbow).
## Carrega automaticamente 'res://src/entities/equipment/socket_profiles/<nome>.tres' quando 'custom_socket_profile' está vazio.
@export_enum("sword", "sword_2", "dagger", "dagger_2", "hammer", "hammer_2", "axe", "axe_2", "staff", "staff_2", "bow", "bow_2", "crossbow", "crossbow_2") var socket_profile: String = "sword"

func get_socket_profile() -> WeaponSocketProfile:
	if custom_socket_profile:
		return custom_socket_profile
	var profile_res_path := "res://src/entities/equipment/socket_profiles/%s.tres" % socket_profile
	if ResourceLoader.exists(profile_res_path):
		var prof := load(profile_res_path) as WeaponSocketProfile
		if prof:
			return prof
	return load("res://src/entities/equipment/socket_profiles/sword.tres") as WeaponSocketProfile

@export_group("Combo & Attack Set (Moveset)")

## O Conjunto de Ataques (AttackSetData) que esta arma utiliza!
## Arraste um recurso de 'res://src/combat/sets/' (ex: 'set_sword_standard.tres', 'set_hammer_crusher.tres').
## Ele define a sequência de animações do corpo (attack1, attack2...), os slashes padrão de cada golpe,
## durações e impulsos. Se deixado vazio, usa os valores de fallback abaixo.
@export var attack_set: AttackSetData

@export_subgroup("Fallback / Legacy Combo Arrays (Usado apenas se Attack Set estiver vazio)")

## [Fallback] Durações de cada golpe em segundos caso 'attack_set' não esteja atribuído.
@export var combo_durations: Array[float] = [0.36, 0.36]

## [Fallback] Impulsos físicos horizontais (px/s) de cada golpe caso 'attack_set' não esteja atribuído.
@export var forward_impulses: Array[float] = [80.0, 100.0]

## [Fallback] Cooldown básico entre golpes caso 'attack_set' não esteja atribuído.
@export_range(0.0, 1.0, 0.02, "suffix:s") var attack_cooldown: float = 0.0

## [Fallback] Cooldown após o último golpe caso 'attack_set' não esteja atribuído.
@export_range(0.0, 1.0, 0.02, "suffix:s") var combo_finisher_cooldown: float = 0.0

@export_group("Damage & Feedback")

## Dano base da arma no primeiro golpe (multiplicado pelo 'damage_multiplier' de cada passo do Set).
@export_range(1.0, 500.0, 1.0, "or_greater") var base_damage: float = 25.0

## Força de repulsão (knockback em px/s) aplicada aos inimigos atingidos.
@export_range(0.0, 800.0, 10.0, "suffix:px/s") var knockback_force: float = 160.0

## Duração do congelamento de impacto (hitstop em segundos) ao acertar um inimigo.
@export_range(0.0, 0.3, 0.01, "suffix:s") var hitstop_duration: float = 0.05

@export_group("Ranged Metrics (Bow & Crossbow)")

## Cena do projétil disparado por armas de combate à distância (Arcos, Bestas, Cajados).
@export var projectile_scene: PackedScene

## Velocidade de voo do projétil disparado (em pixels por segundo).
@export_range(200.0, 1600.0, 50.0, "suffix:px/s") var projectile_speed: float = 650.0

## Tempo de puxada da corda para arcos (em segundos).
@export_range(0.05, 1.0, 0.02, "suffix:s") var charge_time: float = 0.22

## Tempo de recarga após o disparo para bestas (em segundos).
@export_range(0.05, 1.0, 0.02, "suffix:s") var reload_time: float = 0.32

## Offset visual aplicado à instância da arma durante a postura de mira/disparo.
@export var attack_visual_offset: Vector2 = Vector2.ZERO

## Rotação em graus aplicada à instância da arma durante a postura de mira/disparo.
@export var attack_visual_rotation_degrees: float = 0.0

@export_group("Gamepad Vibration")

## Intensidade do motor fraco de vibração do controle ao atingir um alvo (0.0 a 1.0).
@export_range(0.0, 1.0, 0.05) var rumble_weak: float = 0.4

## Intensidade do motor forte de vibração do controle ao atingir um alvo (0.0 a 1.0).
@export_range(0.0, 1.0, 0.05) var rumble_strong: float = 0.7

## Duração da vibração do controle em segundos.
@export_range(0.01, 0.5, 0.01, "suffix:s") var rumble_duration: float = 0.08

@export_group("Attack Behavior & Charge FX")

## Se 'true', segurar o botão de ataque carrega energia até soltar para desferir um golpe esmagador carregado.
## Se 'false', segurar ou apertar o botão executa os golpes do Attack Set em sequência fluida.
@export var is_charge_attack: bool = false

## Tempo necessário segurando o botão para atingir 100% de carga máxima (em segundos).
@export_range(0.05, 3.0, 0.05, "suffix:s") var max_charge_time: float = 0.5

## Multiplicador máximo de dano quando o ataque carregado atinge 100% de carga.
@export_range(1.0, 5.0, 0.1) var charge_damage_multiplier: float = 1.8

## Ativa tremor físico na arma enquanto o jogador segura e acumula carga.
@export var charge_has_tremor: bool = true

## Ativa brilho energético pulsante na arma enquanto o jogador acumula carga.
@export var charge_has_energize: bool = false

## Cor do brilho energético emitido durante o carregamento da arma.
@export var charge_energy_color: Color = Color(0.2, 0.9, 1.0, 1.0)

@export_group("Attack Slash Effect", "slash_")

## Ativa ou desativa a exibição do rastro/efeito visual de corte (slash) para esta arma.
@export var slash_enabled: bool = true

## [Fallback] Nome da animação de corte padrão caso o Attack Set não especifique uma.
@export var slash_animation: StringName = &"slash_sword"

## [Opcional] Recurso SpriteFrames customizado exclusivo desta arma.
## Deixe vazio para usar a biblioteca global padrão ('res://assets/effects/slashes/slash_frames.tres').
@export var slash_custom_frames: SpriteFrames = null

## Tonalidade / Cor de modulação do corte. Permite colorir o efeito sem redesenhar o PNG!
## Exemplos: Branco (original), Roxo (Caos), Vermelho (Fogo), Ciano (Gelo), Amarelo (Sagrado).
@export var slash_modulate: Color = Color.WHITE

## Fator de escala global do efeito de corte desta arma (multiplicado pela escala do passo no Set).
## Ex: Vector2(1.0, 1.0) = original; Vector2(1.25, 1.25) = 25% maior para armas longas/pesadas.
@export var slash_scale: Vector2 = Vector2.ONE

## OVERRIDE DE TAMANHO DA ARMA (Soma Aditiva em pixels):
## Desloca todos os slashes desta arma para compensar lâminas mais longas ou mais curtas!
## Exemplo: Se esta espada é 3 pixels mais comprida e o slash precisa ir mais para frente,
## basta colocar Vector2(3, 0) aqui! X positivo (+) move para frente; Y negativo (-) move para cima.
@export var slash_offset: Vector2 = Vector2.ZERO

## Ordem de desenho (Z-Index) do corte relativo ao personagem (padrão 4 = desenha na frente).
@export var slash_z_index: int = 4

@export_group("Attack Slash Overrides (Por Golpe - Opcional)", "slash_step_")

## [Opcional] Sobrescreve a animação de slash de cada golpe do Set individualmente para esta arma.
## Exemplo: Se o Set tem 2 ataques e esta arma tem cortes exclusivos, adicione 2 itens:
## Índice 0 = &"slash_fogo_1", Índice 1 = &"slash_fogo_2". Se vazio, usa os slashes do Set!
@export var slash_step_animations: Array[StringName] = []

## [Opcional] Ajuste fino EXTRA de posição (em pixels) para cada golpe individual desta arma.
## Somado ao 'slash_offset' da arma e ao offset do Set!
## Exemplo: Se 'slash_offset = (3, 0)' ficou perfeito no Ataque 1, mas no Ataque 2 você quer
## mais +2px no eixo X, coloque [Vector2(0, 0), Vector2(2, 0)].
@export var slash_step_offsets: Array[Vector2] = []

## [Opcional] Multiplicador EXTRA de escala para cada golpe individual desta arma.
## Exemplo: [Vector2(1, 1), Vector2(1.2, 1.2)] deixa apenas o segundo golpe 20% maior.
@export var slash_step_scales: Array[Vector2] = []

@export_group("Hitbox & Reach Synchronization", "hitbox_")

## Se 'true' (recomendado), a caixa de dano física (Hitbox) avança e escala automaticamente
## acompanhando o 'slash_offset' (ex: +3 no X) e a 'slash_scale' desta arma!
## Garante que o alcance real do dano nunca minta para o efeito visual do corte.
@export var hitbox_sync_with_slash: bool = true

## Bônus manual extra de tamanho (Largura, Altura em pixels) somado à Hitbox desta arma em todos os golpes.
@export var hitbox_extra_reach: Vector2 = Vector2.ZERO


# ============================================================================
# API DE RESOLUÇÃO DE DADOS DO COMBO (SET + OVERRIDES DA ARMA)
# ============================================================================

## Retorna quantos passos o combo desta arma possui (lê do AttackSetData ou do array legado).
func get_combo_step_count() -> int:
	if attack_set and not attack_set.steps.is_empty():
		return attack_set.get_step_count()
	return maxi(1, combo_durations.size())

## Retorna a janela de tempo (em segundos) para continuar o combo antes de resetar para o passo 0.
func get_combo_window() -> float:
	if attack_set:
		return attack_set.combo_window
	return 1.35

## Retorna se o combo deve ciclar continuamente do último passo de volta para o primeiro.
func is_combo_looping() -> bool:
	if attack_set:
		return attack_set.loop_combo
	return true

## Retorna o tempo de recuperação após o golpe finalizador (quando is_combo_looping() == false).
func get_finisher_cooldown() -> float:
	if attack_set:
		return attack_set.finisher_cooldown
	return combo_finisher_cooldown

## Retorna o nome da animação do corpo do aventureiro para o passo informado (ex: &"attack1", &"attack2").
func get_step_body_animation(step_index: int) -> StringName:
	if attack_set and not attack_set.steps.is_empty():
		var step_data: ComboStepData = attack_set.get_step(step_index)
		if step_data and step_data.body_animation != &"":
			return step_data.body_animation
	if step_index == 1:
		return &"attack2"
	elif step_index >= 2:
		return &"attack3"
	return &"attack1"

## Retorna a duração em segundos do golpe no passo informado.
func get_step_duration(step_index: int) -> float:
	if attack_set and not attack_set.steps.is_empty():
		var step_data: ComboStepData = attack_set.get_step(step_index)
		if step_data:
			return maxf(0.05, step_data.duration)
	if combo_durations.is_empty():
		return 0.36
	var idx: int = clampi(step_index, 0, combo_durations.size() - 1)
	return maxf(0.05, combo_durations[idx])

## Retorna o impulso horizontal (px/s) do golpe no passo informado.
func get_step_impulse(step_index: int) -> float:
	if attack_set and not attack_set.steps.is_empty():
		var step_data: ComboStepData = attack_set.get_step(step_index)
		if step_data:
			return step_data.forward_impulse
	if forward_impulses.is_empty():
		return 80.0
	var idx: int = clampi(step_index, 0, forward_impulses.size() - 1)
	return forward_impulses[idx]

## Retorna o multiplicador de dano do golpe no passo informado.
func get_step_damage_multiplier(step_index: int) -> float:
	if attack_set and not attack_set.steps.is_empty():
		var step_data: ComboStepData = attack_set.get_step(step_index)
		if step_data:
			return step_data.damage_multiplier
	return 1.0 + (float(step_index) * 0.25)

## Retorna a animação de slash a ser usada no passo informado (Prioridade: Override da Arma -> Set -> Fallback).
func get_step_slash_animation(step_index: int) -> StringName:
	if step_index >= 0 and step_index < slash_step_animations.size():
		var override_anim: StringName = slash_step_animations[step_index]
		if override_anim != &"":
			return override_anim
	if attack_set and not attack_set.steps.is_empty():
		var step_data: ComboStepData = attack_set.get_step(step_index)
		if step_data and step_data.slash_animation != &"":
			return step_data.slash_animation
	return slash_animation if slash_animation != &"" else &"slash_sword"

## Retorna o deslocamento total (Offset Aditivo) do slash para o passo informado:
## Offset do Passo (no Set) + Slash Offset Global da Arma (ex: +3 no X) + Slash Step Offset da Arma.
func get_step_total_slash_offset(step_index: int) -> Vector2:
	var total_offset: Vector2 = Vector2.ZERO
	if attack_set and not attack_set.steps.is_empty():
		var step_data: ComboStepData = attack_set.get_step(step_index)
		if step_data:
			total_offset += step_data.step_slash_offset
	total_offset += slash_offset
	if step_index >= 0 and step_index < slash_step_offsets.size():
		total_offset += slash_step_offsets[step_index]
	return total_offset

## Retorna a escala total (Multiplicativa) do slash para o passo informado:
## Escala do Passo (no Set) * Slash Scale Global da Arma * Slash Step Scale da Arma.
func get_step_total_slash_scale(step_index: int) -> Vector2:
	var total_scale: Vector2 = Vector2.ONE
	if attack_set and not attack_set.steps.is_empty():
		var step_data: ComboStepData = attack_set.get_step(step_index)
		if step_data:
			total_scale *= step_data.step_slash_scale
	total_scale *= slash_scale
	if step_index >= 0 and step_index < slash_step_scales.size():
		var step_sc: Vector2 = slash_step_scales[step_index]
		if step_sc != Vector2.ZERO:
			total_scale *= step_sc
	return total_scale

## Retorna se o slash deve sofrer flip horizontal neste passo.
func get_step_slash_flip_h(step_index: int) -> bool:
	if attack_set and not attack_set.steps.is_empty():
		var step_data: ComboStepData = attack_set.get_step(step_index)
		if step_data:
			return step_data.step_slash_flip_h
	return false

## Retorna se o slash deve sofrer flip vertical neste passo.
func get_step_slash_flip_v(step_index: int) -> bool:
	if attack_set and not attack_set.steps.is_empty():
		var step_data: ComboStepData = attack_set.get_step(step_index)
		if step_data:
			return step_data.step_slash_flip_v
	return false

## Calcula a posição e tamanho finais da Hitbox física do golpe no chão,
## sincronizando automaticamente com o offset/escala do slash se 'hitbox_sync_with_slash' estiver ativo.
func get_step_hitbox_metrics(step_index: int) -> Dictionary:
	var base_size: Vector2 = Vector2(32.0, 28.0)
	var base_pos: Vector2 = Vector2(20.0, -20.0)
	if attack_set and not attack_set.steps.is_empty():
		var step_data: ComboStepData = attack_set.get_step(step_index)
		if step_data:
			base_size = step_data.hitbox_size
			base_pos = step_data.hitbox_position

	var final_size: Vector2 = base_size + hitbox_extra_reach
	var final_pos: Vector2 = base_pos

	if hitbox_sync_with_slash:
		var total_slash_off: Vector2 = get_step_total_slash_offset(step_index)
		var total_slash_sc: Vector2 = get_step_total_slash_scale(step_index)
		final_size = Vector2(base_size.x * total_slash_sc.x, base_size.y * total_slash_sc.y) + hitbox_extra_reach
		# Avança o centro da hitbox de acordo com o offset X/Y e metade do ganho de largura
		var extra_width: float = final_size.x - base_size.x
		final_pos.x += total_slash_off.x + (extra_width * 0.5)
		final_pos.y += total_slash_off.y

	return {
		"position": final_pos,
		"size": final_size
	}
