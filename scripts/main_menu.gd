extends Control

@onready var anim = $AnimationPlayer

func _input(event):
	if Input.is_action_just_pressed("escape"):
		if %Credits.visible == true:
			toggle_credits()
		if %Settings.visible == true:
			toggle_settings()
		
		
func _ready() -> void:
	%MainMenuBackground.play()
	
func play_click_sound():
	var random_index = "%02d" % randi_range(1, 3)
	var sound_path = "Click%s" % random_index
	$TitleScreen.get_node(sound_path).play()
	
func _on_main_menu_background_finished():
	%MainMenuBackground.play()
	
func _on_sp_button_pressed():
	play_click_sound()
	anim.play("fade_out_long")
	await anim.animation_finished
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_mp_button_pressed():
	play_click_sound()
	pass # Replace with function body.


func _on_settings_button_pressed():
	play_click_sound()
	toggle_settings()

func _on_settings_closed():
	play_click_sound()
	toggle_settings()

func toggle_settings():
	if %Settings.visible == false:
		anim.play("fade_out_short")
		%TitleScreen.visible = false
		%Settings.visible = true
	elif %Settings.visible == true:
		anim.play("fade_in_short")
		%TitleScreen.visible = true
		%Settings.visible = false
		
		
func _on_cheats_menu_pressed():
	play_click_sound()
	pass # Replace with function body.


func _on_credits_button_pressed():
	play_click_sound()
	toggle_credits()
	
func _on_credits_closed() -> void:
	toggle_credits()

func toggle_credits():
	if %Credits.visible == false:
		#SignalBus.credits_clicked.emit()
		anim.play("fade_out_short")
		%TitleScreen.visible = false
		%Credits.visible = true
	elif %Credits.visible == true:
		anim.play("fade_in_short")
		%TitleScreen.visible = true
		%Credits.visible = false



func _on_exit_button_pressed():
	play_click_sound()
	get_tree().quit()


func _on_ready() -> void:
	anim.play("fade_in_long")



