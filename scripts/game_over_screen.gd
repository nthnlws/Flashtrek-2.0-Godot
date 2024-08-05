extends Control

func _on_restart_button_pressed():
	get_tree().reload_current_scene()
	
#func _input(event):
	#if Input.is_action_just_pressed("escape"):
		#visible = !visible
