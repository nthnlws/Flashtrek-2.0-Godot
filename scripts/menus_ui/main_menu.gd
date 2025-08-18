extends Control
class_name MainMenu


func _on_single_player_button_pressed() -> void:
	SignalBus.UIclickSound.emit()
	#%SPbutton.disabled = true
	get_tree().change_scene_to_file("res://scenes/level_entities/game.tscn")


func _on_exit_button_pressed() -> void:
	SignalBus.UIclickSound.emit()
	get_tree().quit()


func _on_credit_button_clicked() -> void:
	SignalBus.UIclickSound.emit()
	$Credits.visible = true
	$Credits.closeButton.grab_focus()
	%CreditsButton._release_focus()

func _on_settings_button_pressed() -> void:
	SignalBus.UIclickSound.emit()
	$Settings.visible = true
	$Settings.closeButton.grab_focus()
	%SettingsButton._release_focus()

func _on_credits_closed() -> void:
	$Credits.visible = false
	%SinglePlayer.grab_focus()

func _on_settings_closed() -> void:
	$Settings.visible = false
	%SinglePlayer.grab_focus()
