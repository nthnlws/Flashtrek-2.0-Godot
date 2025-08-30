extends TextureButton


func _on_pressed() -> void:
	if Navigation.in_galaxy_warp == false:
		SignalBus.UIclickSound.emit()
		SignalBus.pause_menu_clicked.emit()
