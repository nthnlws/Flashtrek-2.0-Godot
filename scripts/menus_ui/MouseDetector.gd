class_name MouseDetector extends Control

signal hover_on
signal hover_off

var has_mouse: bool = false:
	set(value):
		if has_mouse == value: return
		has_mouse = value
		if has_mouse:
			hover_on.emit()
		else:
			hover_off.emit()

func _process(delta: float) -> void :
	has_mouse = get_global_rect().has_point(get_global_mouse_position())
