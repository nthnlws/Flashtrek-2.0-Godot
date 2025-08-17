class_name TextButton
extends Label

signal button_hovered
signal button_pressed

@export var default_color: Color
@export var hover_color: Color
@export var pressed_color: Color

@export var enabled: bool = true
var hover: bool= false
var pressed: bool= false


func _ready() -> void:
	modulate = default_color


func _on_mouse_entered() -> void:
	hover = true
	_update_color()
	button_hovered.emit()


func _on_mouse_exited() -> void:
	hover = false
	_update_color()


func _on_mouse_clicked() -> void:
	press()


func _on_mouse_released() -> void:
	pressed = false
	_update_color()
	get_viewport().set_input_as_handled()


func press() -> void:
	if pressed:
		return
	pressed = true
	_update_color()
	button_pressed.emit()


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
