@tool
extends Control

signal button_pressed
@onready var text_label: MenuTextButton = $TextureRect/TextLabel

@export var tab_text: String = "Single Player":
	set(value):
		tab_text = value
		if not is_inside_tree():
			await ready
		text_label.text = value


func _on_button_pressed() -> void:
	button_pressed.emit()


func _release_focus() -> void:
	text_label.pressed = false
	text_label.hover = false
	text_label._on_mouse_exited()
	
