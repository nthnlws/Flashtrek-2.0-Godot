extends TextureButton


func _on_pressed() -> void:
	if Utility.current_gamestate != Utility.GAMESTATE.WARPING:
		AudioManager.play_UI_click_sound()
		SignalBus.pause_menu_clicked.emit()
