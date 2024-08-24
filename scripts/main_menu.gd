extends Control

@onready var anim = $AnimationPlayer


func _on_sp_button_pressed():
	anim.play("fade_out")
	await anim.animation_finished
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


func _on_ready() -> void:
	%MainMenuBackground.play()
	anim.play("fade_in")
