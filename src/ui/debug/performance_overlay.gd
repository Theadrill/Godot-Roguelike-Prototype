class_name PerformanceOverlay
extends CanvasLayer

## Overlay leve de telemetria em tempo real (estilo RivaTuner) para builds de debug.
## Mede frametime real via relógio de parede (Time.get_ticks_usec), independente de hitstop/time_scale.
## Alternado pela tecla F2 (ação "toggle_performance_overlay") com custo zero quando oculto.

const GRAPH_SAMPLES: int = 60
const TEXT_UPDATE_INTERVAL: float = 0.20
const TARGET_FRAME_MS: float = 16.667
const WARN_FRAME_MS: float = 33.333

@onready var panel: PanelContainer = $Anchor/Panel
@onready var metrics_label: RichTextLabel = $Anchor/Panel/Margin/VBox/MetricsLabel
@onready var graph_control: Control = $Anchor/Panel/Margin/VBox/FrametimeGraph

var _last_tick_usec: int = 0
var _text_timer: float = 0.0
var _frametime_history: PackedFloat32Array = PackedFloat32Array()
var _history_index: int = 0
var _history_filled: bool = false


func _ready() -> void:
	layer = 126
	process_mode = Node.PROCESS_MODE_ALWAYS
	_frametime_history.resize(GRAPH_SAMPLES)
	_frametime_history.fill(TARGET_FRAME_MS)

	if graph_control:
		graph_control.draw.connect(_on_graph_draw)

	var start_enabled: bool = OS.is_debug_build()
	visible = start_enabled
	set_process(start_enabled)
	if start_enabled:
		_last_tick_usec = Time.get_ticks_usec()
		_text_timer = TEXT_UPDATE_INTERVAL
		_update_metrics_text(TARGET_FRAME_MS)
		if graph_control:
			graph_control.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_performance_overlay"):
		get_viewport().set_input_as_handled()
		toggle_overlay()


func toggle_overlay() -> void:
	visible = not visible
	set_process(visible)
	if visible:
		_last_tick_usec = Time.get_ticks_usec()
		_text_timer = TEXT_UPDATE_INTERVAL
		_update_metrics_text(TARGET_FRAME_MS)
		if graph_control:
			graph_control.queue_redraw()


func _process(_delta: float) -> void:
	var now_usec: int = Time.get_ticks_usec()
	var frame_ms: float = TARGET_FRAME_MS
	if _last_tick_usec > 0:
		frame_ms = float(now_usec - _last_tick_usec) * 0.001
	_last_tick_usec = now_usec

	_push_sample(frame_ms)

	_text_timer += frame_ms * 0.001
	if _text_timer >= TEXT_UPDATE_INTERVAL:
		_text_timer = 0.0
		_update_metrics_text(frame_ms)

	if graph_control:
		graph_control.queue_redraw()


func _push_sample(frame_ms: float) -> void:
	_frametime_history[_history_index] = frame_ms
	_history_index = (_history_index + 1) % GRAPH_SAMPLES
	if _history_index == 0:
		_history_filled = true


func _get_max_recent_frametime() -> float:
	var count: int = GRAPH_SAMPLES if _history_filled else maxi(_history_index, 1)
	var max_ms: float = 0.0
	for i in range(count):
		if _frametime_history[i] > max_ms:
			max_ms = _frametime_history[i]
	return max_ms


func _update_metrics_text(current_frame_ms: float) -> void:
	if not metrics_label:
		return

	var fps: int = int(Engine.get_frames_per_second())
	var max_ms: float = _get_max_recent_frametime()
	var cpu_ms: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var phy_ms: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var draw_calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var mem_mb: float = float(OS.get_static_memory_usage()) / (1024.0 * 1024.0)

	var fps_color: String = "#76ff03"
	if fps < 30:
		fps_color = "#ff5252"
	elif fps < 55:
		fps_color = "#ffd740"

	metrics_label.text = (
		"[color=%s][b]FPS %d[/b][/color]  [color=#b0bec5]FT %.1fms (MAX %.1f)[/color]\n"
		+ "[color=#90caf9]CPU %.2fms[/color]  [color=#80cbc4]PHY %.2fms[/color]\n"
		+ "[color=#ffcc80]DC %d[/color]  [color=#ce93d8]MEM %.1fMB[/color]"
	) % [fps_color, fps, current_frame_ms, max_ms, cpu_ms, phy_ms, draw_calls, mem_mb]


func _on_graph_draw() -> void:
	if not graph_control:
		return

	var size: Vector2 = graph_control.size
	if size.x <= 2.0 or size.y <= 2.0:
		return

	# Fundo do gráfico
	graph_control.draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.04, 0.06, 0.85))

	# Escala vertical de 0ms até max(36ms, pico recente)
	var ceiling_ms: float = maxf(36.0, _get_max_recent_frametime() * 1.1)

	# Linha de referência 16.6ms (60 FPS)
	var y_60: float = size.y - (TARGET_FRAME_MS / ceiling_ms) * size.y
	graph_control.draw_line(Vector2(0.0, y_60), Vector2(size.x, y_60), Color(0.3, 0.85, 0.4, 0.35), 1.0)

	# Linha de referência 33.3ms (30 FPS)
	var y_30: float = size.y - (WARN_FRAME_MS / ceiling_ms) * size.y
	graph_control.draw_line(Vector2(0.0, y_30), Vector2(size.x, y_30), Color(1.0, 0.4, 0.3, 0.35), 1.0)

	# Polilinha de histórico (do mais antigo ao mais recente)
	var points := PackedVector2Array()
	points.resize(GRAPH_SAMPLES)
	var step_x: float = size.x / float(GRAPH_SAMPLES - 1)
	for i in range(GRAPH_SAMPLES):
		var idx: int = (_history_index + i) % GRAPH_SAMPLES
		var ms: float = clampf(_frametime_history[idx], 0.0, ceiling_ms)
		var x: float = float(i) * step_x
		var y: float = size.y - (ms / ceiling_ms) * size.y
		points[i] = Vector2(x, y)

	graph_control.draw_polyline(points, Color(0.35, 0.9, 1.0, 0.95), 1.2)
