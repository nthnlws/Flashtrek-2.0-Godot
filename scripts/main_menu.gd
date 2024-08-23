extends Control


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	


func _on_sp_button_pressed():
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_mp_button_pressed():
	pass # Replace with function body.


func _on_settings_button_pressed():
	pass # Replace with function body.


func _on_cheats_menu_pressed():
	pass # Replace with function body.


func _on_credits_button_pressed():
	pass # Replace with function body.


func _on_exit_button_pressed():
	get_tree().quit()
