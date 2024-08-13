extends Control

signal menu_clicked

func _ready():
	Global.settingsButton = self
	
func _on_area_2d_input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		menu_clicked.emit()
