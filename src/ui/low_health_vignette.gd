class_name LowHealthVignette
extends CanvasLayer

## Vinheta pixel-art (480x270 com Bayer Dithering) para alerta de vida baixa.
## Comeca sutil abaixo de `start_health_ratio` (40%) e atinge o maximo em `max_health_ratio` (15%),
## com pico reativo curto ao sofrer dano e dissipacao suave ao curar.

@export_group("Health Thresholds")
## Porcentagem de vida em que a vinheta comeca a aparecer bem suave (0.40 = 40%).
@export_range(0.05, 0.95, 0.01) var start_health_ratio: float = 0.40
## Porcentagem de vida em que a vinheta atinge sua intensidade maxima (0.15 = 15%).
@export_range(0.01, 0.80, 0.01) var max_health_ratio: float = 0.15

@export_group("Visual & Intensity")
@export var vignette_color: Color = Color(0.58, 0.04, 0.05, 1.0)
## Opacidade maxima da vinheta aos 15% de vida (mantida contida para nao atrapalhar a leitura).
@export_range(0.05, 1.0, 0.01) var max_alpha: float = 0.34
## Pico temporario adicionado ao sofrer dano abaixo de 40% de vida.
@export_range(0.0, 0.5, 0.01) var hit_spike_boost: float = 0.14
@export_range(0.2, 1.4, 0.02) var max_inner_radius: float = 0.88
@export_range(0.2, 1.4, 0.02) var min_inner_radius: float = 0.72
@export_range(0.5, 15.0, 0.25) var smooth_speed: float = 4.5

@export_group("Pulse")
@export var pulse_enabled: bool = true
@export_range(0.2, 8.0, 0.1) var pulse_min_speed: float = 1.6
@export_range(0.2, 10.0, 0.1) var pulse_max_speed: float = 3.2
## Multiplicador minimo da oscilacao do pulso (0.68 = oscila suavemente entre 68% e 100%).
@export_range(0.1, 1.0, 0.02) var pulse_min_factor: float = 0.68

@export_group("Death Takeover")
@export_range(0.2, 1.0, 0.02) var death_target_alpha: float = 0.92
@export_range(0.1, 1.5, 0.05) var default_outer_radius: float = 1.20

@onready var vignette_rect: ColorRect = $VignetteRect

var _target_player: Player = null
var _current_level: float = 0.0
var _hit_spike: float = 0.0
var _pulse_phase: float = 0.0
var _shader_mat: ShaderMaterial = null
var _is_death_takeover: bool = false
var _death_timer: float = 0.0
var _death_duration: float = 1.25
var _death_start_alpha: float = 0.0
var _death_start_inner: float = 0.88

func _ready() -> void:
	if vignette_rect:
		vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vignette_rect.visible = false
		_shader_mat = vignette_rect.material as ShaderMaterial
		if _shader_mat:
			_shader_mat.set_shader_parameter("vignette_color", vignette_color)
			_shader_mat.set_shader_parameter("alpha", 0.0)

	if get_parent() is Player:
		_target_player = get_parent() as Player

func set_target_player(player: Player) -> void:
	_target_player = player

func trigger_hit_spike() -> void:
	if not _target_player or _target_player.max_health <= 0.0:
		return
	var ratio: float = _target_player.current_health / _target_player.max_health
	if ratio < start_health_ratio and _target_player.current_health > 0.0:
		_hit_spike = hit_spike_boost

func play_death_takeover(duration: float = 1.25) -> void:
	if not _shader_mat or not vignette_rect:
		return
	_is_death_takeover = true
	_death_timer = 0.0
	_death_duration = maxf(0.2, duration)
	_death_start_alpha = clampf(_current_level * max_alpha + _hit_spike, 0.08, max_alpha + hit_spike_boost)
	_death_start_inner = lerpf(max_inner_radius, min_inner_radius, clampf(_current_level, 0.0, 1.0))
	vignette_rect.visible = true

func reset_death_takeover() -> void:
	_is_death_takeover = false
	_death_timer = 0.0
	_current_level = 0.0
	_hit_spike = 0.0
	_pulse_phase = 0.0
	if _shader_mat:
		_shader_mat.set_shader_parameter("alpha", 0.0)
		_shader_mat.set_shader_parameter("inner_radius", max_inner_radius)
		_shader_mat.set_shader_parameter("outer_radius", default_outer_radius)
	if vignette_rect:
		vignette_rect.visible = false

func _process(delta: float) -> void:
	if not _target_player or not _shader_mat or not vignette_rect:
		return

	if _is_death_takeover:
		_death_timer += delta
		var t: float = clampf(_death_timer / _death_duration, 0.0, 1.0)
		var eased: float = t * t * (3.0 - 2.0 * t)
		vignette_rect.visible = true
		_shader_mat.set_shader_parameter("alpha", lerpf(_death_start_alpha, death_target_alpha, eased))
		_shader_mat.set_shader_parameter("inner_radius", lerpf(_death_start_inner, -0.1, eased))
		_shader_mat.set_shader_parameter("outer_radius", lerpf(default_outer_radius, 0.15, eased))
		return

	var target_level: float = 0.0
	if _target_player.max_health > 0.0 and _target_player.current_health > 0.0:
		var ratio: float = _target_player.current_health / _target_player.max_health
		if ratio < start_health_ratio:
			var span: float = maxf(0.001, start_health_ratio - max_health_ratio)
			var linear_danger: float = clampf((start_health_ratio - ratio) / span, 0.0, 1.0)
			# Curva suave: comeca bem leve em 40% e intensifica progressivamente ate 15%
			target_level = pow(linear_danger, 1.25)

	_current_level = move_toward(_current_level, target_level, delta * smooth_speed)
	_hit_spike = move_toward(_hit_spike, 0.0, delta * 0.65)

	var total_alpha: float = clampf(_current_level * max_alpha + _hit_spike, 0.0, max_alpha + hit_spike_boost)
	if total_alpha <= 0.003 and target_level <= 0.0:
		if vignette_rect.visible:
			vignette_rect.visible = false
			_shader_mat.set_shader_parameter("alpha", 0.0)
		_pulse_phase = 0.0
		return

	var pulse_factor: float = 1.0
	if pulse_enabled and _current_level > 0.001:
		var pulse_speed: float = lerpf(pulse_min_speed, pulse_max_speed, _current_level)
		_pulse_phase = fmod(_pulse_phase + delta * pulse_speed, TAU)
		var wave: float = (sin(_pulse_phase) + 1.0) * 0.5
		pulse_factor = lerpf(pulse_min_factor, 1.0, wave)

	vignette_rect.visible = true
	var pulsed_alpha: float = clampf((_current_level * max_alpha * pulse_factor) + _hit_spike, 0.0, max_alpha + hit_spike_boost)
	var radius_t: float = clampf((_current_level * pulse_factor) + _hit_spike * 0.5, 0.0, 1.0)
	_shader_mat.set_shader_parameter("alpha", pulsed_alpha)
	_shader_mat.set_shader_parameter("inner_radius", lerpf(max_inner_radius, min_inner_radius, radius_t))
	_shader_mat.set_shader_parameter("outer_radius", default_outer_radius)
