extends Control

var sound_array:Array = [] # Contains all nodes in group "click_sound"
var sound_array_location:int = 0

@onready var anim = %AnimationPlayer

func _input(event):
	if Input.is_action_just_pressed("escape"):
		if %Credits.visible == true:
			toggle_credits()
		if %Settings.visible == true:
			toggle_settings()
		#if %Cheats.visible:
			#toggle_cheats()
		
		
func _ready() -> void:
	%MainMenuMusic.play(0.5)
	anim.play("fade_in_long")
	#Creates and shuffles array of all click audio nodes
	sound_array = get_tree().get_nodes_in_group("click_sound")
	sound_array.shuffle()
	
	await get_tree().create_timer(2.0).timeout
	%MainMenuBackground.play()
	
	
func play_click_sound(): #Shuffles the array of all click sounds on 
	var sound_array_length = sound_array.size() - 1
	match sound_array_location:
		sound_array_length: # When location in array = array length, shuffle array and reset location
			sound_array[sound_array_location].play()
			sound_array.shuffle()
			sound_array_location = 0
		_: # Runs for all array values besides last
			sound_array[sound_array_location].play()
			sound_array_location += 1
	
	
func _on_main_menu_background_finished():
	%MainMenuBackground.play()

func _on_main_menu_music_finished() -> void:
	%MainMenuMusic.play(0.5)

	
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
		%TitleScreen.visible = false
		%Settings.visible = true
	elif %Settings.visible == true:
		anim.play("fade_in_short")
		%TitleScreen.visible = true
		%Settings.visible = false
		
		
func _on_cheats_menu_pressed():
	play_click_sound()


func _on_credits_button_pressed():
	play_click_sound()
	toggle_credits()
	
func _on_credits_closed() -> void:
	toggle_credits()

func toggle_credits():
	if %Credits.visible == false:
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
