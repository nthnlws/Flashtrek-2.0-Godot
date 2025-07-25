extends Control

enum State {SHOW, HIDE}

@onready var anim: AnimationPlayer = %AnimationPlayer

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("escape"):
		if %Credits.visible == true:
			_on_credits_closed()
		if %Settings.visible == true:
			_on_settings_closed()
		#if %Cheats.visible:
			#toggle_element(%Cheats)
			#toggle_element(%TitleScreen)
	if Input.is_action_just_pressed("rotate_left"):
		Utility.play_click_sound(0)
	if Input.is_action_just_pressed("rotate_right"):
		Utility.play_click_sound(4)


func _ready() -> void:
	%MainMenuMusic.play(0.5)
	anim.play("fade_in_long")
	
	await get_tree().create_timer(2.0).timeout
	%MainMenuBackground.play()


func toggle_element(element_name, force_state: Variant = null) -> void:
	if force_state == State.HIDE:
		element_name.visible = false
	elif force_state == State.SHOW:
		element_name.visible = true
	else: #Reverses visible state
		element_name.visible = not element_name.visible


func _on_main_menu_background_finished() -> void:
	%MainMenuBackground.play()


func _on_main_menu_music_finished() -> void:
	%MainMenuMusic.play(0.5)


func _on_sp_button_pressed() -> void:
	Utility.play_click_sound(4)
	anim.play("fade_out_long")
	%SPbutton.disabled = true
	await anim.animation_finished
	get_tree().change_scene_to_file("res://scenes/level_entities/game.tscn")
	DiscordManager.single_player_game()


func _on_join_mp_pressed() -> void:
	Utility.play_click_sound(4)
	toggle_element(%Multiplayer_popup)


func _on_host_mp_pressed() -> void:
	Utility.play_click_sound(4)


func _on_settings_button_pressed() -> void:
	Utility.play_click_sound(4)
	toggle_element(%TitleScreen)
	toggle_element(%Settings, State.SHOW)
	toggle_element(%Multiplayer_popup, State.HIDE)


func _on_settings_closed() -> void:
	Utility.play_click_sound(0)
	anim.play("fade_in_short")
	toggle_element(%TitleScreen)
	toggle_element(%Settings)


func _on_cheats_menu_pressed() -> void:
	Utility.play_click_sound(4)
	toggle_element(%Multiplayer_popup, State.HIDE)


func _on_credits_button_pressed() -> void:
	Utility.play_click_sound(4)
	toggle_element(%Credits)
	toggle_element(%TitleScreen)
	toggle_element(%Multiplayer_popup, State.HIDE)


func _on_credits_closed() -> void:
	Utility.play_click_sound(0)
	anim.play("fade_in_short")
	toggle_element(%Credits)
	toggle_element(%TitleScreen)


func _on_exit_button_pressed() -> void:
	Utility.play_click_sound(4)
	get_tree().quit()


func _on_ready() -> void:
	anim.play("fade_in_long")


func _on_ship_name_changed(new_text: String) -> void:
	Utility.player_name = new_text


func _on_username_focus_entered() -> void:
	print("mouse")
