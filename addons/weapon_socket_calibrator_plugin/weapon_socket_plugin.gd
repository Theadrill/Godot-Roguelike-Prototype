@tool
extends EditorPlugin

var _inspector_plugin: EditorInspectorPlugin

func _enter_tree() -> void:
	_inspector_plugin = preload("res://addons/weapon_socket_calibrator_plugin/weapon_socket_inspector_plugin.gd").new()
	add_inspector_plugin(_inspector_plugin)

func _exit_tree() -> void:
	if _inspector_plugin:
		remove_inspector_plugin(_inspector_plugin)
		_inspector_plugin = null
