extends TextureButton


func _on_pressed() -> void:
	if Utility.current_gamestate != Utility.GAMESTATE.WARPING:
		SignalBus.UIclickSound.emit()
		SignalBus.pause_menu_clicked.emit()
