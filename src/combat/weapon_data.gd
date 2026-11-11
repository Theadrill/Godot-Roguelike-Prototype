class_name WeaponData
extends EquipmentData

## ============================================================================
## TUTORIAL RÁPIDO: COMO CRIAR UMA NOVA ARMA (EX: "ESPADA DO CAOS")
## ============================================================================
## 1. DUPLICAR O ARQUIVO .TRES:
##    - No painel 'FileSystem' do Godot, clique com o botão direito em um .tres existente
##      (ex: 'src/entities/equipment/swords/weapon_sword_base.tres') e escolha 'Duplicate...'.
##    - Renomeie para o nome da nova arma (ex: 'weapon_espada_do_caos.tres').
##
## 2. AJUSTAR IDENTIDADE E DANO NO INSPECTOR:
##    - 'Weapon Name': Nome exibido da arma (ex: "Espada do Caos").
##    - 'Base Damage': Dano de cada golpe.
##    - 'Socket Profile': Perfil de posições na mão/costas (ex: "sword", "axe", "dagger").
##    - 'Visual Scene': Cena visual da arma na mão (duplique 'sword_visual.tscn' se tiver arte própria).
##
## 3. CONFIGURAR O EFEITO DE CORTE (GRUPO "Attack Slash Effect"):
##    - 'Slash Animation': Nome da animação (ex: "slash_sword" ou sua animação customizada).
##    - 'Slash Modulate': Cor do efeito (ex: Roxo para Caos, Vermelho para Fogo, Ciano para Gelo).
##    - 'Slash Scale': Tamanho do corte (ex: (1.25, 1.25) para corte 25% maior).
##    - 'Slash Offset': Ajuste fino de posição em pixels (X = frente/trás, Y = cima/baixo).
##
## 4. PRONTO! O Godot aplica tudo automaticamente no combate sem precisar de código novo!
## ============================================================================

enum WeaponCategory {
	MELEE,
	RANGED_BOW,
	RANGED_CROSSBOW,
	RANGED_SPELL
}

@export_group("Weapon Identity")
@export var weapon_category: WeaponCategory = WeaponCategory.MELEE
@export var weapon_name: String = "Broadsword":
	set(value):
		weapon_name = value
		equipment_name = value

@export_group("Socket & Anchoring Profile")
## Perfil de ancoragem frame a frame da arma na mão do personagem.
## Você pode arrastar um arquivo .tres customizado de 'res://src/entities/equipment/socket_profiles/'
## ou deixar vazio para usar o perfil selecionado no dropdown abaixo.
@export var custom_socket_profile: WeaponSocketProfile

## Perfil predefinido de ancoragem da arma (ex: sword, sword_2, dagger, hammer).
## Se custom_socket_profile estiver vazio, este perfil é carregado automaticamente.
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

@export_group("Damage & Feedback")
@export_range(1.0, 500.0, 1.0, "or_greater") var base_damage: float = 25.0
@export_range(0.0, 800.0, 10.0, "suffix:px/s") var knockback_force: float = 160.0
@export_range(0.0, 0.3, 0.01, "suffix:s") var hitstop_duration: float = 0.05

@export_group("Ranged Metrics (Bow & Crossbow)")
@export var projectile_scene: PackedScene
@export_range(200.0, 1600.0, 50.0, "suffix:px/s") var projectile_speed: float = 650.0
@export_range(0.05, 1.0, 0.02, "suffix:s") var charge_time: float = 0.22 # Draw time for bow
@export_range(0.05, 1.0, 0.02, "suffix:s") var reload_time: float = 0.32 # Reload time for crossbow
@export var attack_visual_offset: Vector2 = Vector2.ZERO
@export var attack_visual_rotation_degrees: float = 0.0

@export_group("Gamepad Vibration")
@export_range(0.0, 1.0, 0.05) var rumble_weak: float = 0.4
@export_range(0.0, 1.0, 0.05) var rumble_strong: float = 0.7
@export_range(0.01, 0.5, 0.01, "suffix:s") var rumble_duration: float = 0.08

@export_group("Attack Behavior & Charge FX")
## If true, holding the attack button accumulates charge until released to unleash a powered attack/spell.
## If false, holding the attack button continuously attacks/fires at the weapon's cadence.
@export var is_charge_attack: bool = false
@export_range(0.05, 3.0, 0.05, "suffix:s") var max_charge_time: float = 0.5
@export_range(1.0, 5.0, 0.1) var charge_damage_multiplier: float = 1.8
## Flag: activates visual tremor/vibration while holding and building charge.
@export var charge_has_tremor: bool = true
## Flag: activates visual energy glow and pulsation while holding and building charge.
@export var charge_has_energize: bool = false
## Tint color used for the energizing glow build-up.
@export var charge_energy_color: Color = Color(0.2, 0.9, 1.0, 1.0)

@export_group("Combo Configuration")
# Combo cadences (seconds per step)
@export var combo_durations: Array[float] = [0.18, 0.18, 0.28]
# Forward step impulse on each swing (px/s)
@export var forward_impulses: Array[float] = [80.0, 100.0, 140.0]

@export_group("Attack Cadence & Recovery")
## Cooldown after an attack before a new attack can be started (seconds)
@export_range(0.0, 1.0, 0.02, "suffix:s") var attack_cooldown: float = 0.14
## Cooldown specifically after completing the full combo finisher (seconds)
@export_range(0.0, 1.0, 0.02, "suffix:s") var combo_finisher_cooldown: float = 0.22

@export_group("Attack Slash Effect", "slash_")
## Ativa ou desativa a exibição do rastro/efeito de corte (slash) para esta arma.
@export var slash_enabled: bool = true

## Nome da animação de corte a ser tocada (ex: 'slash_sword', 'slash_axe', 'slash_dagger').
## Se você criar uma animação nova em 'slash_frames.tres', basta digitar o nome dela aqui.
@export var slash_animation: StringName = &"slash_sword"

## [Opcional] Recurso SpriteFrames customizado exclusivo desta arma.
## Deixe vazio para usar a biblioteca global padrão ('res://assets/effects/slashes/slash_frames.tres').
@export var slash_custom_frames: SpriteFrames = null

## Tonalidade / Cor de modulação do corte.
## Permite colorir o efeito sem precisar redesenhar o PNG!
## Exemplos: Branco (cor original), Roxo (Caos/Arcano), Vermelho (Fogo), Ciano (Gelo), Amarelo (Sagrado).
@export var slash_modulate: Color = Color.WHITE

## Fator de escala do efeito (multiplicador de tamanho).
## Ex: Vector2(1.0, 1.0) = tamanho original; Vector2(1.3, 1.3) = 30% maior para espadões colossais.
@export var slash_scale: Vector2 = Vector2.ONE

## Deslocamento fino de posição em pixels relativo ao pé do personagem (origem 0,0).
## X positivo = move para a frente; Y negativo = move para cima.
@export var slash_offset: Vector2 = Vector2.ZERO

## Ordem de desenho (Z-Index) do corte relativo ao personagem.
## Padrão 4 = desenha na frente do corpo do aventureiro e da arma.
@export var slash_z_index: int = 4
