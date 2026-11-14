@tool
class_name AttackSetData
extends Resource

## ============================================================================
## CONJUNTO DE ATAQUES / MOVESET (AttackSetData)
## ============================================================================
## Define uma sequência reutilizável de golpes (ComboStepData) para armas corpo a corpo.
##
## COMO CRIAR UM NOVO SET:
## 1. No painel 'FileSystem' do Godot, vá em 'res://src/combat/sets/'.
## 2. Clique com o botão direito em um Set existente (ex: 'set_sword_standard.tres')
##    e selecione 'Duplicate...'. Renomeie (ex: 'set_hammer_brutal.tres').
## 3. Abra o novo arquivo no Inspector:
##    - Em 'Steps', adicione, remova ou reordene os golpes (ComboStepData).
##    - Em cada golpe, escolha qual animação o corpo faz ('body_animation', ex: 'attack1', 'attack2')
##      e qual animação de corte acompanha aquele golpe ('slash_animation').
## 4. Para usar este Set em uma arma:
##    - Abra o arquivo '.tres' da arma (ex: 'weapon_sword_base.tres').
##    - Arraste este Set para o campo 'Attack Set' da arma!
## ============================================================================

const DEFAULT_GUIDE_TEXT: String = (
	"COMO MODIFICAR ESTE SET DE ATAQUES:\n"
	+ "1. Na lista 'Steps' abaixo, cada item é um golpe da sequência (Golpe 1, Golpe 2, etc.).\n"
	+ "2. Clique em um item de 'Steps' para expandir e escolher:\n"
	+ "   - 'body_animation': pose do aventureiro (ex: attack1, attack2, attack3).\n"
	+ "   - 'slash_animation': animação de corte daquele golpe (ex: slash_sword).\n"
	+ "   - 'duration' e 'forward_impulse': velocidade e avanço físico do golpe.\n"
	+ "3. Para usar este Set em qualquer arma, basta arrastar este arquivo .tres para o campo 'Attack Set' dentro da arma!\n"
	+ "4. Se uma arma for mais comprida (ex: +3px), você NÃO precisa duplicar este Set: ajuste apenas o 'slash_offset' direto na arma!"
)

@export_group("Guia Rápido (Como Usar este Set)")

## Instruções rápidas de referência visíveis diretamente no Inspector do Godot.
@export_multiline var guia_de_uso: String = DEFAULT_GUIDE_TEXT

@export_group("Configuração da Sequência de Golpes")

## Nome identificador deste Conjunto de Ataques (ex: "Set Espada Padrão 1-2", "Set Martelo Pesado").
@export var set_name: String = "Standard Sword Set"

## Lista ordenada de golpes que compõem este Set.
## O tamanho desta lista define quantos passos o combo possui (2 golpes, 3 golpes, 4 golpes...).
## Cada elemento é um recurso 'ComboStepData' com sua própria animação de corpo, slash, tempo e impulso.
@export var steps: Array[ComboStepData] = []

@export_group("Regras de Encadeamento e Ritmo (Combo Flow)")

## Janela máxima de tempo (em segundos) que o jogador pode aguardar no chão após terminar um golpe
## antes que a sequência do combo resete de volta para o Golpe 1 (Passo 0).
## Padrão Dead Cells: 1.35s (permite esperar a animação acabar e continuar no próximo golpe com folga).
@export_range(0.1, 3.0, 0.05, "suffix:s") var combo_window: float = 1.35

## Se 'true', ao terminar o último golpe da lista 'steps', o próximo ataque cicla imediatamente
## de volta para o primeiro golpe (ex: 1 -> 2 -> 1 -> 2 sem travas).
## Se 'false', aplica o 'finisher_cooldown' após o último golpe antes de permitir reiniciar o combo.
@export var loop_combo: bool = true

## Tempo de recuperação (cooldown em segundos) aplicado APENAS após o último golpe da sequência
## quando 'loop_combo' estiver desativado (false).
@export_range(0.0, 2.0, 0.02, "suffix:s") var finisher_cooldown: float = 0.0

## Retorna a quantidade de golpes configurados neste Set (mínimo 1 para segurança).
func get_step_count() -> int:
	return maxi(1, steps.size())

## Retorna os dados do passo solicitado com proteção de limites (clamp).
func get_step(step_index: int) -> ComboStepData:
	if steps.is_empty():
		return null
	var idx: int = clampi(step_index, 0, steps.size() - 1)
	return steps[idx]
