extends TextureButton

func _ready() -> void:
	SignalBus.HUDchanged.connect(change_scale)


func _on_pressed() -> void:
	if Utility.current_gamestate != Utility.GAMESTATE.WARPING:
		AudioManager.play_UI_click_sound()
		SignalBus.pause_menu_clicked.emit()


func change_scale(new_scale: float) -> void:
	var use: Vector2 = Vector2(new_scale, new_scale)
	scale = use * Vector2(0.85, 0.85)
