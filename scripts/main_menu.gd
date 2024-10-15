extends Control

enum State {SHOW, HIDE}

const HIGH:float = 2.0
const LOW:float = 0.5

var sound_array:Array = [] # Contains all nodes in group "click_sound"
var sound_array_location:int = 0

@onready var anim = %AnimationPlayer

func _input(event):
	if Input.is_action_just_pressed("escape"):
		if %Credits.visible == true:
			toggle_element(%Credits)
			toggle_element(%TitleScreen)
		if %Settings.visible == true:
			anim.play("fade_in_short")
			toggle_element(%Settings)
			toggle_element(%TitleScreen)
		#if %Cheats.visible:
			#toggle_element(%Cheats)
			#toggle_element(%TitleScreen)
		
	if Input.is_action_just_pressed("rotate_left"):
		play_click_sound(LOW)
	if Input.is_action_just_pressed("rotate_right"):
		play_click_sound(HIGH)
	
func _ready() -> void:
	%MainMenuMusic.play(0.5)
	anim.play("fade_in_long")
	#Creates and shuffles array of all click audio nodes
	sound_array = get_tree().get_nodes_in_group("click_sound")
	sound_array.shuffle()
	
	await get_tree().create_timer(2.0).timeout
	%MainMenuBackground.play()
	

func toggle_element(element_name, force_state: Variant = null):
	if force_state == State.HIDE:
		element_name.visible = false
	elif force_state == State.SHOW:
		element_name.visible = true
	else: #Reverses visible state
		element_name.visible = not element_name.visible
		

# Shuffles the array of all click sounds each cycle through array of sounds
# Volume passed in to change volume of played sound
func play_click_sound(volume): 
	var sound_array_length = sound_array.size() - 1
	var default_db = sound_array[sound_array_location].volume_db
	var effective_volume = default_db / volume
	print(effective_volume)
	
	match sound_array_location:
		sound_array_length: # When location in array = array size, shuffle array and reset location
			#sound_array[sound_array_location].volume_db = effective_volume
			sound_array[sound_array_location].play()
			#sound_array[sound_array_location].volume_db = default_db
			sound_array.shuffle()
			sound_array_location = 0
		_: # Runs for all array values besides last
			#sound_array[sound_array_location].volume_db = effective_volume
			sound_array[sound_array_location].play()
			#sound_array[sound_array_location].volume_db = default_db
			sound_array_location += 1
	
	
func _on_main_menu_background_finished():
	%MainMenuBackground.play()

func _on_main_menu_music_finished() -> void:
	%MainMenuMusic.play(0.5)

	
func _on_sp_button_pressed():
	play_click_sound(HIGH)
	anim.play("fade_out_long")
	await anim.animation_finished
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_join_mp_pressed():
	play_click_sound(HIGH)
	toggle_element(%Multiplayer_popup)

func _on_host_mp_pressed():
	play_click_sound(HIGH)
	

func _on_settings_button_pressed():
	play_click_sound(HIGH)
	toggle_element(%TitleScreen)
	toggle_element(%Settings)
	toggle_element(%Multiplayer_popup, State.HIDE)

func _on_settings_closed():
	play_click_sound(LOW)
	toggle_element(%TitleScreen)
	toggle_element(%Settings)

func _on_cheats_menu_pressed():
	play_click_sound(HIGH)
	toggle_element(%Multiplayer_popup, State.HIDE)


func _on_credits_button_pressed():
	play_click_sound(HIGH)
	toggle_element(%Credits)
	toggle_element(%TitleScreen)
	toggle_element(%Multiplayer_popup, State.HIDE)
	
func _on_credits_closed() -> void:
	play_click_sound(LOW)
	anim.play("fade_in_short")
	toggle_element(%Credits)
	toggle_element(%TitleScreen)


func _on_exit_button_pressed():
	play_click_sound(HIGH)
	get_tree().quit()


func _on_ready() -> void:
	anim.play("fade_in_long")
