extends Control
class_name SettingsMenu

signal close_settings

@onready var close_button: Button = %closeMenuButton
@onready var keybind_column: VBoxContainer = %KeybindColumn


func _ready() -> void:
	keybind_column.keybind_changed.connect(_on_keybind_changed)
	SaveManager.settings_loaded.connect(_sync_settings)
	SaveManager.current_settings.apply_keybinds()
	_sync_settings(SaveManager.current_settings)


func _sync_settings(settings: SettingsResource) -> void:
	# Block value_changed signals during sync to avoid redundant saves
	%masterSlider.set_block_signals(true)
	%musicSlider.set_block_signals(true)
	%effectsSlider.set_block_signals(true)
	%menusSlider.set_block_signals(true)
	%vSyncSetting.set_block_signals(true)
	%ScaleSetting.set_block_signals(true)
	%WarningsToggle.set_block_signals(true)

	%masterSlider.value  = settings.master_volume
	%musicSlider.value   = settings.music_volume
	%effectsSlider.value = settings.effects_volume
	%menusSlider.value   = settings.menus_volume

	%vSyncSetting.selected = settings.vsync_setting

	var scale_map: Array[float] = [1.4, 1.2, 1.0, 0.8, 0.6]
	var scale_index: int = scale_map.find(settings.ui_scale)
	%ScaleSetting.selected = scale_index if scale_index != -1 else 2

	%WarningsToggle.button_pressed = settings.warnings_disabled

	%masterSlider.set_block_signals(false)
	%musicSlider.set_block_signals(false)
	%effectsSlider.set_block_signals(false)
	%menusSlider.set_block_signals(false)
	%vSyncSetting.set_block_signals(false)
	%ScaleSetting.set_block_signals(false)
	%WarningsToggle.set_block_signals(false)
	
	%KeybindColumn.sync_keybinds(settings)

func _input(event: InputEvent) -> void:
	if not visible: return
	if not event is InputEventKey: return
	if get_tree().get_current_scene().name == "MainMenu" and Input.is_action_just_pressed("escape"):
		close_settings.emit()


# ─── Audio ────────────────────────────────────────────────────────────────────

func _on_master_slider_value_changed(value: float) -> void:
	AudioManager.update_bus_volume(Utility.AUDIO_BUS.MASTER, value)
	SaveManager.current_settings.master_volume = value
	SaveManager.save_settings()

func _on_effects_volume_changed(value: float) -> void:
	AudioManager.update_bus_volume(Utility.AUDIO_BUS.EFFECTS, value)
	SaveManager.current_settings.effects_volume = value
	SaveManager.save_settings()

func _on_music_volume_changed(value: float) -> void:
	AudioManager.update_bus_volume(Utility.AUDIO_BUS.MUSIC, value)
	SaveManager.current_settings.music_volume = value
	SaveManager.save_settings()

func _on_menu_volume_changed(value: float) -> void:
	AudioManager.update_bus_volume(Utility.AUDIO_BUS.MENUS, value)
	SaveManager.current_settings.menus_volume = value
	SaveManager.save_settings()


# ─── Video ────────────────────────────────────────────────────────────────────

func _on_vsync_setting_changed(index: int) -> void:
	var new_setting: DisplayServer.VSyncMode
	if index == 0: new_setting = DisplayServer.VSyncMode.VSYNC_ENABLED
	elif index == 1: new_setting = DisplayServer.VSyncMode.VSYNC_ADAPTIVE
	elif index == 2: new_setting = DisplayServer.VSyncMode.VSYNC_DISABLED
	
	DisplayServer.window_set_vsync_mode(new_setting)
	SaveManager.current_settings.vsync_setting = new_setting as DisplayServer.VSyncMode
	SaveManager.save_settings()

func _on_scale_setting_item_selected(index: int) -> void:
	var scale_map: Array[float] = [1.4, 1.2, 1.0, 0.8, 0.6]
	var scale: float = scale_map[clamp(index, 0, scale_map.size() - 1)]
	SignalBus.HUDchanged.emit(scale)
	SaveManager.current_settings.ui_scale = scale
	SaveManager.save_settings()


# ─── Game ─────────────────────────────────────────────────────────────────────

func _on_check_button_toggled(toggled_on: bool) -> void:
	SignalBus.warningsDisabled.emit(toggled_on)
	SaveManager.current_settings.warnings_disabled = toggled_on
	SaveManager.save_settings()


# ─── Keybinds ─────────────────────────────────────────────────────────────────

func _on_keybind_changed(action: String, event: InputEvent) -> void:
	SaveManager.current_settings.save_keybind(action, event)
	SaveManager.save_settings()


# ─── Header Buttons ───────────────────────────────────────────────────────────

func close_settings_menu() -> void:
	close_settings.emit()

func _on_main_menu_button_pressed() -> void:
	AudioManager.play_UI_click_sound()
	if get_parent().name != "MainMenu":
		get_tree().change_scene_to_file("res://scenes/menus_ui/main_menu.tscn")
		Utility.current_menu = Utility.MENUSTATE.NONE
	else:
		close_settings.emit()

func _on_close_game_button_pressed() -> void:
	AudioManager.play_UI_click_sound()
	get_tree().quit()

func _on_reset_pressed() -> void:
	SignalBus.levelReset.emit()
	SaveManager.save_settings()
	get_tree().reload_current_scene()

func _on_save_game_pressed() -> void:
	SaveManager.save_galaxy(SaveManager.current_save_slot, LevelManager.galaxy_data)
