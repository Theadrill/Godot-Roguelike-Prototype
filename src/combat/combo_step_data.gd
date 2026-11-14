@tool
class_name ComboStepData
extends Resource

## ============================================================================
## PASSO INDIVIDUAL DE COMBO (ComboStepData)
## ============================================================================
## Representa UM golpe específico dentro de um Conjunto de Ataques (AttackSetData).
##
## COMO FUNCIONA:
## - Cada elemento na lista 'steps' de um AttackSetData é um ComboStepData.
## - Aqui você define qual animação o CORPO do aventureiro faz neste golpe
##   (ex: 'attack1', 'attack2', 'attack3') e qual animação de SLASH (corte)
##   acompanha este movimento específico.
## - Os offsets e escalas definidos aqui são a BASE da coreografia do golpe.
##   Quando uma arma usa este Set, ela soma o 'slash_offset' próprio dela
##   (ex: +3 no X para armas mais longas) por cima do 'step_slash_offset' daqui!
## ============================================================================

@export_group("Identificação e Coreografia do Corpo")

## Nome organizacional deste passo para facilitar a leitura no Inspector
## (ex: "Golpe 1 - Corte Descendente", "Golpe 2 - Estocada").
@export var step_label: String = "Golpe 1"

## Nome exato da animação do corpo do personagem no CHÃO em 'player_frames.tres'
## (ex: 'attack1', 'attack2', 'attack3').
## O sistema de sockets das mãos e costas usa automaticamente este nome para
## posicionar a arma frame a frame!
@export var body_animation: StringName = &"attack1"

## Nome exato da animação do corpo do personagem no AR em 'player_frames.tres'
## (ex: 'air_attack1', 'air_attack2', 'air_attack3').
## Se a animação configurada ainda não existir no SpriteFrames (ex: enquanto air_attack2 e air_attack3
## estiverem em produção), o sistema faz fallback seguro automático para 'air_attack1' ou 'body_animation'!
@export var air_body_animation: StringName = &"air_attack1"

@export_group("Tempo, Física e Dano do Golpe")

## Duração total deste golpe em segundos (ex: 0.36s para espada, 0.24s para adaga, 0.52s para martelo).
## A velocidade da animação do corpo e do efeito de slash se ajustam automaticamente para durar este tempo.
@export_range(0.05, 3.0, 0.01, "suffix:s") var duration: float = 0.36

## Impulso físico horizontal (em pixels por segundo) que projeta o personagem para frente neste golpe.
@export_range(0.0, 600.0, 5.0, "suffix:px/s") var forward_impulse: float = 80.0

## Multiplicador de dano deste passo específico em relação ao 'base_damage' da arma.
## Exemplo: 1.0 no Golpe 1 (100% do dano), 1.25 no Golpe 2 (+25% de dano), 1.5 num golpe finalizador.
@export_range(0.1, 5.0, 0.05) var damage_multiplier: float = 1.0

## Janela máxima de oportunidade (em segundos) que o jogador tem APÓS concluir este golpe para apertar ataque
## e engatar o PRÓXIMO golpe da sequência antes que o combo resete de volta para o Golpe 1.
## Se deixado em 0.0, herda o 'combo_window' padrão do AttackSetData (1.35s).
## Exemplo: Golpe 1 -> 2 usa 1.35s (folgado); Golpe 2 -> 3 usa 0.675s (metade do tempo, exigindo compromisso imediato para o finalizador).
@export_range(0.0, 5.0, 0.025, "suffix:s") var next_step_window: float = 0.0

## Se 'true', bloqueia o cancelamento por Esquiva/Slide apenas durante os frames ativos do Slash (frames 2, 3 e 4),
## permitindo cancelar durante o giro inicial (frames 0 e 1) e durante a pausa final (frame 5).
@export var lock_dodge_after_windup: bool = false

@export_group("Efeito Visual de Corte (Slash Padrão do Golpe)")

## Nome da animação de corte em 'slash_frames.tres' que acompanha este golpe específico
## (ex: 'slash_sword', 'slash_sword_2', 'slash_hammer_1').
## Nota: A arma pode sobrescrever isso em 'slash_step_animations' caso tenha um corte exclusivo.
@export var slash_animation: StringName = &"slash_sword"

## [Opcional] Nome da animação de corte em 'slash_frames.tres' usada quando este golpe é executado no AR
## (ex: 'slash_air_sword_1'). Se deixado vazio, usa 'slash_animation' padrão do passo.
@export var air_slash_animation: StringName = &""

## Deslocamento base (em pixels) do efeito de corte para a pose deste golpe no chão.
## X positivo (+) move para a frente do ataque; Y negativo (-) move para cima; Y positivo (+) move para baixo.
## O 'slash_offset' configurado na Arma será SOMADO a este valor!
@export var step_slash_offset: Vector2 = Vector2.ZERO

## Deslocamento adicional (em pixels) aplicado ao efeito de corte quando este golpe é executado no AR
## (útil pois nos sprites de air_attack o corpo do aventureiro fica elevado na célula 83x62).
@export var step_air_slash_offset: Vector2 = Vector2.ZERO

## Escala base do efeito de corte para este passo (1.0, 1.0 = tamanho original).
## A 'slash_scale' configurada na Arma será MULTIPLICADA por este valor!
@export var step_slash_scale: Vector2 = Vector2.ONE

## Se ativado, espelha horizontalmente o sprite do slash neste passo do combo.
@export var step_slash_flip_h: bool = false

## Se ativado, espelha verticalmente o sprite do slash neste passo do combo.
## Dica: Muito útil para inverter um corte de cima para baixo transformando-o em um corte de baixo para cima!
@export var step_slash_flip_v: bool = false

@export_group("Hitbox Base do Golpe (Active Frames)")

## Frame inicial em que a Hitbox de dano LIGA (padrão Dead Cells / Blasphemous / Nine Sols).
## Nos frames anteriores a este (Windup), a espada está puxando para trás e NÃO causa dano.
## Ex: No 'attack1' a meia-lua do slash surge no Frame 2; no 'attack2' surge no Frame 3.
@export_range(0, 20, 1) var active_start_frame: int = 2

## Último frame em que a Hitbox de dano permanece LIGADA antes de desligar na recuperação (Recovery).
## Ex: No 'attack1' permanece ativa nos frames 2 e 3; no 'attack2' nos frames 3 e 4.
@export_range(0, 20, 1) var active_end_frame: int = 3

## [Opcional] Frame inicial em que a Hitbox liga quando o golpe é desferido no AR (-1 = herda 'active_start_frame').
## Útil quando a animação aérea possui menos frames que a terrestre (ex: air_attack1 tem 4 frames, ativa no frame 2).
@export_range(-1, 20, 1) var air_active_start_frame: int = -1

## [Opcional] Último frame em que a Hitbox permanece ligada quando o golpe é desferido no AR (-1 = herda 'active_end_frame').
@export_range(-1, 20, 1) var air_active_end_frame: int = -1

## Tamanho base (Largura x Altura em pixels) da caixa de colisão de dano deste golpe.
## Se a arma estiver com 'sync_hitbox_with_slash' ativo, esta caixa crescerá automaticamente junto com a escala do slash!
@export var hitbox_size: Vector2 = Vector2(32.0, 28.0)

## Posição base do centro da Hitbox relativa aos pés do personagem neste golpe.
## Se a arma tiver um 'slash_offset.x' (ex: +3 para armas mais longas), a posição X avançará automaticamente!
@export var hitbox_position: Vector2 = Vector2(20.0, -20.0)

@export_group("Ataque Aéreo em Fases / Mergulho (Air Plunge / Dive)")

## Se 'true', quando este golpe é executado no AR, ele opera em 4 sub-fases dinâmicas:
## 1) Preparação (Frame 0) -> 2) Loop de Queda enquanto não atinge ninguém nem o chão (Frames 1..3) ->
## 3) Golpe/Impacto ao atingir inimigo ou chão (Frames 4..5) -> 4) Finalização (Frame 6).
@export var is_air_plunge: bool = false

## Velocidade vertical de descida (em px/s) durante o Loop de Queda do mergulho aéreo.
@export_range(100.0, 1200.0, 10.0, "suffix:px/s") var plunge_fall_speed: float = 420.0

## Duração (em segundos) da fase inicial de Preparação no ar (Frame 0) antes de iniciar a descida.
@export_range(0.04, 0.5, 0.01, "suffix:s") var plunge_prep_duration: float = 0.12

## Velocidade (FPS) com que a animação alterna entre os frames do Loop de Queda enquanto o personagem cai.
@export_range(4.0, 30.0, 1.0, "suffix:fps") var plunge_loop_fps: float = 12.0

## Duração total (em segundos) dos frames do Golpe em si (Frames 4 e 5) após atingir um inimigo ou o chão.
@export_range(0.06, 1.0, 0.01, "suffix:s") var plunge_impact_duration: float = 0.20

## Duração (em segundos) do último frame de Finalização/Recovery (Frame 6) antes de encerrar o estado.
@export_range(0.05, 1.0, 0.01, "suffix:s") var plunge_recovery_duration: float = 0.14

## Primeiro frame do Loop de Queda (padrão 1 no air_attack3).
@export_range(0, 20, 1) var plunge_loop_start_frame: int = 1

## Último frame do Loop de Queda (padrão 3 no air_attack3; cicla entre start e end enquanto cai).
@export_range(0, 20, 1) var plunge_loop_end_frame: int = 3

## Primeiro frame do Golpe/Impacto ao tocar em alguém ou no chão (padrão 4 no air_attack3).
@export_range(0, 20, 1) var plunge_impact_start_frame: int = 4

## Último frame do Golpe/Impacto antes da Finalização (padrão 5 no air_attack3).
@export_range(0, 20, 1) var plunge_impact_end_frame: int = 5

## Frame de Finalização/Recovery (padrão 6 no air_attack3).
@export_range(0, 20, 1) var plunge_recovery_frame: int = 6
