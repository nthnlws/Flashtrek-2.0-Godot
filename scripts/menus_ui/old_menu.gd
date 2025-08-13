extends Control

enum State {SHOW, HIDE}

@onready var anim: AnimationPlayer = %AnimationPlayer
@onready var sp_button: Button = %SPbutton
@onready var host: Button = %HostMP
@onready var join: Button = %JoinMP
@onready var settings_button: Button = %SettingsButton

var last_focus:Button = null # Used for resetting focus when returning to main menu

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("escape"):
		if %Credits.visible == true:
			_on_credits_closed()
		if %Settings.visible == true:
			_on_settings_closed()
		#if %Cheats.visible:
			#toggle_element(%Cheats)
			#toggle_element(%TitleScreen)


func _ready() -> void:
	%MainMenuMusic.play(0.5)
	anim.play("fade_in_long")
	
	await get_tree().create_timer(2.0).timeout
	%MainMenuBackground.play()


func connect_button_signals() -> void:
	# Menu sound for keyboard focus
	for button:Button in get_tree().get_nodes_in_group("UI_button"):
		button.connect("focus_entered", _handle_button_focus.bind(button))


func toggle_element(element_name, force_state: Variant = null) -> void:
	if force_state == State.HIDE:
		element_name.visible = false
	elif force_state == State.SHOW:
		element_name.visible = true
	else: #Reverses visible state
		element_name.visible = not element_name.visible

func _handle_button_focus(button:Button) -> void:
	last_focus = button
	SignalBus.UIselectSound.emit()


func _on_main_menu_background_finished() -> void:
	%MainMenuBackground.play()


func _on_main_menu_music_finished() -> void:
	%MainMenuMusic.play(0.5)


func _on_sp_button_pressed() -> void:
	SignalBus.UIclickSound.emit()
	anim.play("fade_out_long")
	%SPbutton.disabled = true
	await anim.animation_finished
	get_tree().change_scene_to_file("res://scenes/level_entities/game.tscn")
	DiscordManager.single_player_game()


func _on_join_mp_pressed() -> void:
	SignalBus.UIclickSound.emit()
	toggle_element(%Multiplayer_popup)


func _on_host_mp_pressed() -> void:
	SignalBus.UIclickSound.emit()


func _on_settings_button_pressed() -> void:
	SignalBus.UIclickSound.emit()
	$Settings/ColorRect/HeaderArea/XbuttonArea/closeMenuButton.grab_focus()
	toggle_element(%TitleScreen)
	toggle_element(%Settings, State.SHOW)
	toggle_element(%Multiplayer_popup, State.HIDE)


func _on_settings_closed() -> void:
	SignalBus.UIclickSound.emit()
	last_focus.grab_focus()
	anim.play("fade_in_short")
	toggle_element(%TitleScreen)
	toggle_element(%Settings)


func _on_cheats_menu_pressed() -> void:
	SignalBus.UIclickSound.emit()
	toggle_element(%Multiplayer_popup, State.HIDE)


func _on_credits_button_pressed() -> void:
	SignalBus.UIclickSound.emit()
	$Credits/XbuttonArea/closeMenuButton.grab_focus()
	toggle_element(%Credits)
	toggle_element(%TitleScreen)
	toggle_element(%Multiplayer_popup, State.HIDE)


func _on_credits_closed() -> void:
	SignalBus.UIclickSound.emit()
	last_focus.grab_focus()
	anim.play("fade_in_short")
	toggle_element(%Credits)
	toggle_element(%TitleScreen)





func _on_ready() -> void:
	anim.play("fade_in_long")


func _on_ship_name_changed(new_text: String) -> void:
	Utility.player_name = new_text


func _on_SP_button_ready() -> void:
	%SPbutton.call_deferred("grab_focus")
	call_deferred("connect_button_signals")


func _on_host_focus_entered() -> void:
	sp_button.focus_neighbor_bottom = host.get_path()
	settings_button.focus_neighbor_top = host.get_path()


func _on_join_focus_entered() -> void:
	sp_button.focus_neighbor_bottom = join.get_path()
	settings_button.focus_neighbor_top = join.get_path()
