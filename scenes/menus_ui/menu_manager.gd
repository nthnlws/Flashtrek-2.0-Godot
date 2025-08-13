extends Control


func _on_single_player_button_pressed() -> void:
	SignalBus.UIclickSound.emit()
	#%SPbutton.disabled = true
	DiscordManager.single_player_game()
	get_tree().change_scene_to_file("res://scenes/level_entities/game.tscn")
