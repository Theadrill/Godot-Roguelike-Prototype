extends Node

## Diagnóstico Contínuo de Runtime e Detecção de Congelamentos / Travamentos.
## Grava eventos, métricas de memória, taxa de quadros e avisos de latência diretamente em arquivo no disco.

var log_file: FileAccess
var log_path: String = "res://runtime_diagnostic.log"
var heartbeat_timer: float = 0.0
var frame_counter: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Nunca pausa, continua monitorando até em telas de pause/menus
	_open_log_file()
	_log_system_environment()
	
	# Monitora conexões/desconexões de controles em tempo real
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

	# Instancia o painel de debug de métricas e persistência globalmente
	var debug_panel_scene := load("res://src/ui/debug/debug_metrics_panel.tscn") as PackedScene
	if debug_panel_scene:
		var panel = debug_panel_scene.instantiate()
		add_child(panel)

func _open_log_file() -> void:
	log_file = FileAccess.open(log_path, FileAccess.WRITE)
	if not log_file:
		# Fallback para user:// se res:// for somente-leitura
		log_path = "user://runtime_diagnostic.log"
		log_file = FileAccess.open(log_path, FileAccess.WRITE)
	
	if log_file:
		_write_raw("================================================================================")
		_write_raw("=== SEVERED DAWN - RUNTIME DIAGNOSTIC LOG STARTED AT " + Time.get_datetime_string_from_system() + " ===")
		_write_raw("================================================================================")

func _log_system_environment() -> void:
	log_info("ENV", "Godot Version: " + Engine.get_version_info().string)
	log_info("ENV", "OS: " + OS.get_name() + " | Distribution: " + OS.get_distribution_name())
	log_info("ENV", "Rendering Method: " + str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown")))
	log_info("ENV", "Adapter: " + RenderingServer.get_video_adapter_name() + " (" + RenderingServer.get_video_adapter_vendor() + ")")
	log_info("ENV", "Audio Output Device: " + AudioServer.get_output_device())
	
	var joypads: Array[int] = Input.get_connected_joypads()
	log_info("JOYPAD", "Connected joypads count: " + str(joypads.size()))
	for id in joypads:
		log_info("JOYPAD", "Pad #" + str(id) + ": " + Input.get_joy_name(id) + " (GUID: " + Input.get_joy_guid(id) + ")")

func _process(delta: float) -> void:
	frame_counter += 1
	heartbeat_timer += delta

	# Detecção de Spike / Hitch / Micro-congelamento entre frames (ignora frames 1 e 2 de carregamento da cena)
	if frame_counter > 2 and delta > 0.10: # Queda para menos de 10 FPS no frame
		var delta_ms: float = delta * 1000.0
		if delta > 0.40:
			log_warning("FREEZE", "LONG HANG DETECTED! Delta: %.1f ms (%.2fs)! Frame: %d | Active Scene: %s" % [delta_ms, delta, frame_counter, _get_active_scene_name()])
		else:
			log_warning("HITCH", "Frame spike detected: %.1f ms | Frame: %d" % [delta_ms, frame_counter])

	# Heartbeat periódico a cada 1.0 segundo
	if heartbeat_timer >= 1.0:
		heartbeat_timer = 0.0
		var fps: int = Engine.get_frames_per_second()
		var mem_mb: float = float(OS.get_static_memory_usage()) / (1024.0 * 1024.0)
		log_info("HEARTBEAT", "FPS: %d | Mem: %.1f MB | Frame: %d | Scene: %s" % [fps, mem_mb, frame_counter, _get_active_scene_name()])

func _get_active_scene_name() -> String:
	var tree := get_tree()
	if tree and tree.current_scene:
		return tree.current_scene.name
	return "None"

func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		log_info("JOYPAD", "Device connected #%d: %s (GUID: %s)" % [device_id, Input.get_joy_name(device_id), Input.get_joy_guid(device_id)])
	else:
		log_warning("JOYPAD", "Device disconnected #%d" % device_id)

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_IN:
			log_info("APP", "Window gained focus")
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			log_info("APP", "Window lost focus")
		NOTIFICATION_WM_CLOSE_REQUEST:
			log_info("APP", "Window close requested by user")
			_close_log_file()
		NOTIFICATION_PREDELETE:
			_close_log_file()

func _write_raw(text: String) -> void:
	if log_file:
		log_file.store_line(text)
		log_file.flush() # Força gravação imediata no disco para evitar perda em travamentos

func _format_line(level: String, category: String, message: String) -> String:
	var timestamp: String = Time.get_time_string_from_system()
	return "[%s][%s][%s] %s" % [timestamp, level, category, message]

func log_info(category: String, message: String) -> void:
	var line: String = _format_line("INFO", category, message)
	print(line)
	_write_raw(line)

func log_warning(category: String, message: String) -> void:
	var line: String = _format_line("WARN", category, message)
	push_warning(line)
	_write_raw(line)

func log_error(category: String, message: String) -> void:
	var line: String = _format_line("ERROR", category, message)
	push_error(line)
	_write_raw(line)

func log_event(category: String, message: String) -> void:
	log_info(category, message)

func _close_log_file() -> void:
	if log_file:
		_write_raw("=== SEVERED DAWN - RUNTIME DIAGNOSTIC LOG ENDED AT " + Time.get_datetime_string_from_system() + " ===")
		log_file.flush()
		log_file.close()
		log_file = null
