@tool
class_name PickupEffectProfile
extends Resource

## Perfil visual reutilizável para o feedback de coleta de qualquer item (PickupItem).
## Segue o mesmo padrão modular do EnergizeProfile para armas.

@export var profile_name: String = "Default Pickup Spark"

@export_group("Glow & Pop")
## Cor do brilho aplicado ao item e às partículas no momento da exibição.
@export var glow_color: Color = Color(1.0, 0.92, 0.55, 1.0)
## Intensidade do flash de brilho aditivo no modulate do item (0.0 = sem brilho).
@export_range(0.0, 2.5, 0.05) var glow_intensity: float = 0.85
## Ganho percentual temporário de escala no pop do item (ex: 0.22 = +22%).
@export_range(0.0, 0.6, 0.02) var scale_pop: float = 0.22
## Duração do decaimento do brilho e do pop de escala.
@export_range(0.05, 0.6, 0.02, "suffix:s") var effect_duration: float = 0.20

@export_group("Particle FX")
## Cena de partículas one-shot (ex: CPUParticles2D) disparada no socket do item.
@export var burst_particle_scene: PackedScene = null
## Se true, aplica glow_color no modulate das partículas instanciadas.
@export var tint_particles: bool = true

@export_group("Gamepad Rumble")
## Intensidade do motor fraco do gamepad ao disparar o brilho de coleta.
@export_range(0.0, 1.0, 0.05) var rumble_weak: float = 0.25
## Intensidade do motor forte do gamepad ao disparar o brilho de coleta.
@export_range(0.0, 1.0, 0.05) var rumble_strong: float = 0.45
## Duração da vibração do gamepad ao disparar o brilho de coleta.
@export_range(0.0, 0.5, 0.01, "suffix:s") var rumble_duration: float = 0.12

func compute_peak_modulate() -> Color:
	return Color(
		1.0 + glow_color.r * glow_intensity,
		1.0 + glow_color.g * glow_intensity,
		1.0 + glow_color.b * glow_intensity,
		1.0
	)
