class_name TextButton
extends Label

signal button_hovered
signal button_pressed

@export var default_color: Color
@export var hover_color: Color
@export var pressed_color: Color

@export var enabled: bool = true
var hover := false
var pressed := false

func _ready() -> void:
	modulate = default_color

func _on_mouse_entered() -> void:
	hover = true
	_update_color()
	button_hovered.emit()

func _on_mouse_exited() -> void:
	hover = false
	_update_color()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and hover:
		if event.is_action_pressed("left_click"):
			press()
			get_viewport().set_input_as_handled()
		# Release returns to hover state unless disabled
		elif pressed:
			pressed = false
			_update_color()

func press() -> void:
	if pressed:
		return
	pressed = true
	_update_color()
	button_pressed.emit()
	await get_tree().create_timer(0.3).timeout
	pressed = false
	_update_color()

func set_enabled(state: bool) -> void:
	enabled = state
	_update_color()

func _update_color() -> void:
	if pressed:
		modulate = pressed_color
	elif not enabled:
		modulate = default_color
	elif hover:
		modulate = hover_color
	else:
		modulate = default_color
