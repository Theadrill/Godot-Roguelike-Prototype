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

## Nome exato da animação do corpo do personagem em 'player_frames.tres'
## (ex: 'attack1', 'attack2', 'attack3').
## O sistema de sockets das mãos e costas usa automaticamente este nome para
## posicionar a arma frame a frame!
@export var body_animation: StringName = &"attack1"

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

@export_group("Efeito Visual de Corte (Slash Padrão do Golpe)")

## Nome da animação de corte em 'slash_frames.tres' que acompanha este golpe específico
## (ex: 'slash_sword', 'slash_sword_2', 'slash_hammer_1').
## Nota: A arma pode sobrescrever isso em 'slash_step_animations' caso tenha um corte exclusivo.
@export var slash_animation: StringName = &"slash_sword"

## Deslocamento base (em pixels) do efeito de corte para a pose deste golpe.
## X positivo (+) move para a frente do ataque; Y negativo (-) move para cima; Y positivo (+) move para baixo.
## O 'slash_offset' configurado na Arma será SOMADO a este valor!
@export var step_slash_offset: Vector2 = Vector2.ZERO

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

## Tamanho base (Largura x Altura em pixels) da caixa de colisão de dano deste golpe.
## Se a arma estiver com 'sync_hitbox_with_slash' ativo, esta caixa crescerá automaticamente junto com a escala do slash!
@export var hitbox_size: Vector2 = Vector2(32.0, 28.0)

## Posição base do centro da Hitbox relativa aos pés do personagem neste golpe.
## Se a arma tiver um 'slash_offset.x' (ex: +3 para armas mais longas), a posição X avançará automaticamente!
@export var hitbox_position: Vector2 = Vector2(20.0, -20.0)
