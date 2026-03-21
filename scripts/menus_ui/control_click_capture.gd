extends Control
class_name ClickCatcher

signal pressed
signal released


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		accept_event()
		pressed.emit()
		
	if event.is_action_released("left_click"):
		accept_event()
		released.emit()
