class_name WeaponTrail
extends Node2D

## Procedural Weapon Slash Trail (Abordagem 3)
## Gera um rastro de corte em formato de lâmina/meia-lua com Catmull-Rom spline,
## curva de espessura e blend mode aditivo luminoso.

@export var enabled: bool = true

var glow_line: Line2D
var core_line: Line2D

var is_active: bool = false
var elapsed: float = 0.0
var total_duration: float = 0.3
var full_arc_points: PackedVector2Array = []

const WEAPON_THEMES: Dictionary = {
	"sword": {
		"glow": Color(0.25, 0.75, 1.0, 0.9), # Ciano corte de aço
		"core": Color(1.0, 1.0, 1.0, 0.95),
		"width": 20.0,
		"core_width": 5.0,
		"tip_offset": Vector2(18.0, 0.0),
	},
	"axe": {
		"glow": Color(1.0, 0.45, 0.12, 0.9), # Laranja corte pesado / brasa
		"core": Color(1.0, 0.95, 0.8, 0.95),
		"width": 24.0,
		"core_width": 6.5,
		"tip_offset": Vector2(16.0, -10.0),
	},
	"hammer": {
		"glow": Color(1.0, 0.82, 0.2, 0.95), # Dourado impacto / onda de choque
		"core": Color(1.0, 1.0, 1.0, 0.95),
		"width": 26.0,
		"core_width": 7.0,
		"tip_offset": Vector2(18.0, 0.0),
	},
	"dagger": {
		"glow": Color(0.3, 0.95, 0.65, 0.85), # Esmeralda veloz
		"core": Color(1.0, 1.0, 1.0, 0.95),
		"width": 13.0,
		"core_width": 3.5,
		"tip_offset": Vector2(10.0, 0.0),
	},
	"staff": {
		"glow": Color(0.7, 0.35, 1.0, 0.9), # Púrpura arcano
		"core": Color(1.0, 0.9, 1.0, 0.95),
		"width": 22.0,
		"core_width": 5.5,
		"tip_offset": Vector2(16.0, 0.0),
	}
}

func _ready() -> void:
	z_index = 3
	_setup_lines()

func _setup_lines() -> void:
	# 1. Glow Line (Camada externa de brilho colorido aditivo)
	glow_line = Line2D.new()
	glow_line.name = "GlowLine"
	glow_line.joint_mode = Line2D.LINE_JOINT_ROUND
	glow_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	glow_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	glow_line.material = mat
	
	# Curva de espessura de corte (fina na cauda, barriguda no meio, afunilando na ponta)
	var width_curve := Curve.new()
	width_curve.add_point(Vector2(0.0, 0.0))    # Cauda (fina)
	width_curve.add_point(Vector2(0.4, 0.75))
	width_curve.add_point(Vector2(0.8, 1.0))    # Ápice do corte
	width_curve.add_point(Vector2(1.0, 0.35))   # Ponta junto à lâmina
	glow_line.width_curve = width_curve
	glow_line.width = 20.0
	add_child(glow_line)
	
	# 2. Core Line (Fio cortante branco no centro)
	core_line = Line2D.new()
	core_line.name = "CoreLine"
	core_line.joint_mode = Line2D.LINE_JOINT_ROUND
	core_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	core_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	core_line.material = mat
	
	var core_curve := Curve.new()
	core_curve.add_point(Vector2(0.0, 0.0))
	core_curve.add_point(Vector2(0.6, 0.9))
	core_curve.add_point(Vector2(1.0, 0.4))
	core_line.width_curve = core_curve
	core_line.width = 5.0
	core_line.default_color = Color(1.0, 1.0, 1.0, 0.95)
	add_child(core_line)

func start_trail(player: Player, anim_name: StringName, current_step: int, duration: float) -> void:
	if not enabled or not player or not player.weapon:
		return
		
	var w_type := player._detect_weapon_type_string(player.weapon)
	var theme: Dictionary = WEAPON_THEMES.get(w_type, WEAPON_THEMES["sword"])
	
	glow_line.width = theme["width"]
	core_line.width = theme["core_width"]
	
	# Gradiente de cor colorido para o brilho
	var glow_col: Color = theme["glow"]
	var grad := Gradient.new()
	grad.set_color(0, Color(glow_col.r, glow_col.g, glow_col.b, 0.0)) # Cauda transparente
	grad.add_point(0.4, Color(glow_col.r, glow_col.g, glow_col.b, glow_col.a * 0.5))
	grad.add_point(0.8, Color(glow_col.r, glow_col.g, glow_col.b, glow_col.a * 0.85))
	grad.set_color(1, Color(glow_col.r * 1.2, glow_col.g * 1.2, glow_col.b * 1.2, glow_col.a))
	glow_line.gradient = grad
	
	# Gradiente branco para o núcleo
	var core_grad := Gradient.new()
	core_grad.set_color(0, Color(1, 1, 1, 0.0))
	core_grad.add_point(0.5, Color(1, 1, 1, 0.6))
	core_grad.set_color(1, Color(1, 1, 1, 0.95))
	core_line.gradient = core_grad
	
	# Calcular os pontos do arco através do perfil dos sockets calibrados
	var profile: WeaponSocketProfile = player.weapon.get_socket_profile()
	var key_points: Array[Vector2] = []
	var tip_offset: Vector2 = theme.get("tip_offset", Vector2(18.0, 0.0))
	
	if profile:
		# Extrai os pontos dos frames da animação
		for frame_idx in range(5):
			var data := profile.get_frame_data(anim_name, frame_idx)
			var pos: Vector2 = data.get("pos", Vector2(6, -20))
			var rot_rad: float = deg_to_rad(data.get("rot", -35.0))
			var tip: Vector2 = pos + tip_offset.rotated(rot_rad)
			key_points.append(tip)
	else:
		# Fallback se não houver perfil
		key_points = [
			Vector2(-15, -25),
			Vector2(-5, -35),
			Vector2(20, -20),
			Vector2(25, -5),
			Vector2(18, 5)
		]
		
	# Gera spline contínua e suave com Catmull-Rom
	full_arc_points = _generate_catmull_rom_spline(key_points, 6)
	
	total_duration = maxf(0.05, duration)
	elapsed = 0.0
	is_active = true
	modulate.a = 1.0
	glow_line.clear_points()
	core_line.clear_points()
	visible = true

func stop_trail() -> void:
	is_active = false
	elapsed = 0.0
	if glow_line:
		glow_line.clear_points()
	if core_line:
		core_line.clear_points()
	visible = false

func _process(delta: float) -> void:
	if not is_active or full_arc_points.is_empty():
		return
		
	elapsed += delta
	var progress: float = clampf(elapsed / total_duration, 0.0, 1.0)
	
	# Janela do corte:
	# 0.05 a 0.70 -> O corte viaja e desenha o arco com aceleração
	# 0.70 a 1.00 -> O rastro se dissipa (fade out)
	var swing_start: float = 0.05
	var swing_end: float = 0.70
	
	if progress < swing_start:
		glow_line.clear_points()
		core_line.clear_points()
		return
		
	var swing_norm := clampf((progress - swing_start) / (swing_end - swing_start), 0.0, 1.0)
	# Curva de impacto rápido: ease_out cúbico
	var head_ratio := 1.0 - pow(1.0 - swing_norm, 3.0)
	# Cauda do corte cobre ~50% do arco
	var tail_ratio := maxf(0.0, head_ratio - 0.52)
	
	var total_pts := full_arc_points.size()
	var head_idx := clampi(int(head_ratio * (total_pts - 1)), 0, total_pts - 1)
	var tail_idx := clampi(int(tail_ratio * (total_pts - 1)), 0, head_idx)
	
	if head_idx > tail_idx:
		var slice_pts := full_arc_points.slice(tail_idx, head_idx + 1)
		glow_line.points = slice_pts
		core_line.points = slice_pts
	
	# Dissipação suave no final do movimento
	if progress >= swing_end:
		var fade_norm := (progress - swing_end) / (1.0 - swing_end)
		modulate.a = maxf(0.0, 1.0 - fade_norm)
		
	if progress >= 1.0:
		stop_trail()

## Gera interpolação suave Catmull-Rom entre os pontos de controle
func _generate_catmull_rom_spline(pts: Array[Vector2], subdivisions: int = 6) -> PackedVector2Array:
	var result := PackedVector2Array()
	if pts.size() < 2:
		for p in pts:
			result.append(p)
		return result
		
	# Extrapola pontos fantasmas nas pontas para fechar a curva
	var extended: Array[Vector2] = []
	extended.append(pts[0] + (pts[0] - pts[1]))
	extended.append_array(pts)
	extended.append(pts[-1] + (pts[-1] - pts[-2]))
	
	for i in range(1, extended.size() - 2):
		var p0: Vector2 = extended[i - 1]
		var p1: Vector2 = extended[i]
		var p2: Vector2 = extended[i + 1]
		var p3: Vector2 = extended[i + 2]
		
		for s in range(subdivisions):
			var t := float(s) / float(subdivisions)
			var pt := _catmull_rom(p0, p1, p2, p3, t)
			result.append(pt)
			
	result.append(pts[-1])
	return result

func _catmull_rom(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * (
		(2.0 * p1) +
		(-p0 + p2) * t +
		(2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 +
		(-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3
	)
