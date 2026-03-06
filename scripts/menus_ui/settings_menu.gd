extends Control
class_name SettingsMenu

@onready var closeButton: Button = %closeMenuButton

signal close_settings

func _input(event: InputEvent) -> void:
	if not visible: return
	if Input.is_action_just_pressed("escape"):
			close_settings_menu()


func _on_master_slider_value_changed(value: float) -> void:
	AudioManager.update_bus_volume(Utility.AUDIO_BUS.MASTER, value)
	SaveManager.current_settings.master_volume = value

func _on_effects_volume_changed(value: float) -> void:
	AudioManager.update_bus_volume(Utility.AUDIO_BUS.EFFECTS, value)
	SaveManager.current_settings.effects_volume = value

func _on_music_volume_changed(value: float) -> void:
	AudioManager.update_bus_volume(Utility.AUDIO_BUS.MUSIC, value)
	SaveManager.current_settings.music_volume = value

func _on_menu_volume_changed(value: float) -> void:
	AudioManager.update_bus_volume(Utility.AUDIO_BUS.MENUS, value)
	SaveManager.current_settings.menus_volume = value


# Header buttons
func close_settings_menu() -> void:
	close_settings.emit()


func _on_main_menu_button_pressed() -> void:
	AudioManager.play_UI_click_sound()
	if get_parent().name != "MainMenu":
		get_tree().change_scene_to_file("res://scenes/menus_ui/main_menu.tscn")
	else:
		close_settings.emit()


func _on_close_game_button_pressed() -> void:
	AudioManager.play_UI_click_sound()
	get_tree().quit()

# World Column
func _on_reset_pressed() -> void:
	SignalBus.levelReset.emit()
	SaveManager.save_settings()
	
	get_tree().reload_current_scene()


func _on_vsync_setting_changed(index: int) -> void:
	# Selected index matches DisplayServer.VSyncMode enum values
	DisplayServer.window_set_vsync_mode(index)


func _on_scale_setting_item_selected(index: int) -> void:
	match index:
		0: # 100% HUD Scale
			SignalBus.HUDchanged.emit(1.0)
		1: # 90% HUD Scale
			SignalBus.HUDchanged.emit(0.9)
		2: # 80% HUD Scale
			SignalBus.HUDchanged.emit(0.8)
		3: # 70% HUD Scale
			SignalBus.HUDchanged.emit(0.7)
		4: # 60% HUD Scale
			SignalBus.HUDchanged.emit(0.6)
		5: # 50% HUD Scale
			SignalBus.HUDchanged.emit(0.5)


func _on_save_game_pressed() -> void:
	SaveManager.save_galaxy(SaveManager.current_save_slot, LevelManager.galaxy_data)
