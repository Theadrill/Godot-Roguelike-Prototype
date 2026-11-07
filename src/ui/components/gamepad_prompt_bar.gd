class_name GamepadPromptBar
extends HBoxContainer

## Componente para rodapé de menus: exibe ícones de botões do Gamepad
## se houver controle conectado (ou se o último input veio do controle),
## e comandos textuais de teclado se estiver no teclado/mouse.

@export var confirm_text: String = "Confirmar"
@export var cancel_text: String = "Voltar / Fechar"
@export var nav_text: String = "Navegar"

@onready var icon_nav: TextureRect = $PromptNav/Icon
@onready var label_nav: Label = $PromptNav/Label

@onready var icon_confirm: TextureRect = $PromptConfirm/Icon
@onready var label_confirm: Label = $PromptConfirm/Label

@onready var icon_cancel: TextureRect = $PromptCancel/Icon
@onready var label_cancel: Label = $PromptCancel/Label

var is_gamepad_mode: bool = false

func _ready() -> void:
	# Verifica se já há gamepad conectado inicialmente
	is_gamepad_mode = Input.get_connected_joypads().size() > 0
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	refresh_prompts()

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if not is_gamepad_mode:
			is_gamepad_mode = true
			refresh_prompts()
	elif event is InputEventKey or event is InputEventMouseButton:
		if is_gamepad_mode:
			is_gamepad_mode = false
			refresh_prompts()

func _on_joy_connection_changed(_device: int, connected: bool) -> void:
	if not connected and Input.get_connected_joypads().is_empty():
		is_gamepad_mode = false
	elif connected:
		is_gamepad_mode = true
	refresh_prompts()

func refresh_prompts() -> void:
	if not is_inside_tree():
		return

	if is_gamepad_mode:
		if icon_nav:
			icon_nav.visible = true
		if label_nav:
			label_nav.text = nav_text

		if icon_confirm:
			icon_confirm.visible = true
		if label_confirm:
			label_confirm.text = confirm_text

		if icon_cancel:
			icon_cancel.visible = true
		if label_cancel:
			label_cancel.text = cancel_text
	else:
		if icon_nav:
			icon_nav.visible = false
		if label_nav:
			label_nav.text = "[SETAS] " + nav_text

		if icon_confirm:
			icon_confirm.visible = false
		if label_confirm:
			label_confirm.text = "[ENTER / ESPAÇO] " + confirm_text

		if icon_cancel:
			icon_cancel.visible = false
		if label_cancel:
			label_cancel.text = "[ESC] " + cancel_text
