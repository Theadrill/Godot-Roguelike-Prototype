class_name NpcBark
extends Node2D

## Exibe balão de texto diegético (Bark) suavemente animado flutuando acima da cabeça de um NPC
## Estilo consistente com o bark do Player ao tentar beber flask vazio.

@onready var label: Label = $Label
var _tween: Tween = null
var _original_position_y: float = -50.0

func _ready() -> void:
	if label:
		_original_position_y = label.position.y
		label.modulate.a = 0.0

func show_bark(text: String, duration: float = 4.5, text_color: Color = Color(1.0, 0.95, 0.85, 1.0)) -> void:
	if not label:
		label = get_node_or_null("Label") as Label
	if not label:
		return

	# Garante tempo suficiente para leitura humana confortável (mínimo 4.5s)
	var calc_duration: float = maxf(duration, clampf(float(text.length()) * 0.08, 4.5, 7.5))

	label.text = text
	label.modulate = text_color
	label.modulate.a = 1.0
	label.position.y = _original_position_y

	if _tween and _tween.is_valid():
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(true)
	_tween.tween_property(label, "position:y", _original_position_y - 12.0, calc_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(maxf(1.0, calc_duration - 0.8))
