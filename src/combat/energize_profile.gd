@tool
class_name EnergizeProfile
extends Resource

## Perfil visual de Energização durante o carregamento de armas (Charge Attack).
## Define brilho, pulso, ganho de escala e partículas pixel-art durante a carga e ao soltar o golpe.

@export var profile_name: String = "Glow & Bigger"

@export_group("Glow & Scale")
## Cor do brilho aplicado na arma durante o carregamento.
@export var glow_color: Color = Color(0.2, 0.9, 1.0, 1.0)
## Intensidade do brilho aditivo no modulate da arma ao atingir 100% de carga.
@export_range(0.0, 4.0, 0.05) var glow_intensity: float = 1.5
## Velocidade do pulso de brilho quando o carregamento atinge 100% (0.0 = sem pulso).
@export_range(0.0, 30.0, 0.5) var pulse_speed: float = 15.0
## Ganho percentual de escala da arma aos 100% de carga (ex: 0.12 = +12%, 0.0 = não cresce).
@export_range(0.0, 0.5, 0.01) var scale_boost: float = 0.12

@export_group("Particle FX")
## Cena de partículas (ex: CPUParticles2D) instanciada na arma enquanto o jogador segura o botão.
@export var particle_scene: PackedScene = null
## Cena de partículas (one-shot) disparada no momento em que o jogador solta o ataque carregado.
@export var release_particle_scene: PackedScene = null

@export_group("Slash Color Filter")
## Se 'true', aplica a cor deste EnergizeProfile como filtro de luminância no Slash ao soltar o golpe.
@export var tint_slash: bool = true
## Intensidade máxima do filtro de cor aplicado sobre o Slash em carga completa (0.0 a 1.0).
@export_range(0.0, 1.0, 0.05) var slash_tint_strength: float = 0.9

func compute_modulate(charge_progress: float) -> Color:
	var clamped: float = clampf(charge_progress, 0.0, 1.0)
	var pulse: float = 0.0
	if clamped >= 1.0 and pulse_speed > 0.0:
		pulse = sin(float(Time.get_ticks_msec()) * 0.001 * pulse_speed) * 0.2
	var intensity: float = (clamped * glow_intensity) + pulse
	return Color(
		1.0 + (glow_color.r * intensity * 0.7),
		1.0 + (glow_color.g * intensity * 0.7),
		1.0 + (glow_color.b * intensity * 0.7),
		1.0
	)

func compute_scale(base_scale: Vector2, charge_progress: float) -> Vector2:
	var clamped: float = clampf(charge_progress, 0.0, 1.0)
	var mult: float = 1.0 + (clamped * scale_boost)
	return base_scale * mult
