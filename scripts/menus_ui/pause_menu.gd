extends Control

@onready var _bus: int = AudioServer.get_bus_index("Master")
@onready var anim: AnimationPlayer = $"../../transition_overlay/AnimationPlayer"
@onready var color_rect: ColorRect = $"../../transition_overlay/FadeAnimation"
@onready var Menus: CanvasLayer = $".."

var xCoord: int = 0:
	get:
		return xCoord
	set(value):
		xCoord = clamp(value, -1000000, 1000000)

var yCoord: int = 0:
	get:
		return yCoord
	set(value):
		yCoord = clamp(value, -1000000, 1000000)

var file: FileAccess

func _ready() -> void:
	# Creates default save file on first load, otherwise restores settings to previous state
	if GameSettings.loadNumber == 0: 
		store_menu_state(0)
		set_menu_to_savefile(0)
	elif GameSettings.loadNumber > 0: 
		set_menu_to_savefile(1)
		SignalBus.world_reset.emit()
	
	%gameVolume.value = db_to_linear(AudioServer.get_bus_volume_db(_bus))
	
	#Sets all menu states to false/ignore
	mouse_filter = Control.MOUSE_FILTER_PASS
	GameSettings.menuStatus = false
	visible = false
	
	populate_type_button()


func populate_type_button() -> void:
	var EnemyTypeList: OptionButton = %EnemyTypeList
	var PlayerTypeList: OptionButton = %PlayerTypeList
	for ship in Utility.SHIP_TYPES.keys():
		EnemyTypeList.add_item(ship)
		PlayerTypeList.add_item(ship)


#Header buttons
func _on_close_menu_button_pressed() -> void:
	Utility.play_click_sound(4)
	Menus.toggle_menu(self, 0)


func _on_main_menu_button_pressed() -> void:
	Utility.play_click_sound(4)
	color_rect.z_index = 2
	z_index = 0
	#anim.play("fade_out")
	#await anim.animation_finished
	#BUG No Fade Animation
	SignalBus.levelReset.emit()
	get_tree().change_scene_to_file("res://scenes/3D_menu_scene.tscn")


func _on_close_game_button_pressed() -> void:
	Utility.play_click_sound(4)
	get_tree().quit()


# Cheats Column
func _on_energy_button_toggled(toggled_on:bool) -> void:
	GameSettings.unlimitedEnergy = toggled_on


func _on_health_button_toggled(toggled_on:bool) -> void:
	GameSettings.unlimitedHealth = toggled_on


func _on_shield_button_toggled(toggled_on:bool) -> void:
	GameSettings.unlimitedShield = toggled_on


func _on_no_collision_toggled(toggled_on:bool) -> void:
	GameSettings.noCollision = toggled_on
	SignalBus.collisionChanged.emit(toggled_on)


func _on_x_coord_input_focus_entered() -> void:
	%xCoordInput.select_all()


func _on_x_coord_input_text_changed(new_text: String) -> void:
	xCoord = new_text.strip_edges().to_float()


func _on_x_coord_input_text_submitted(new_text: String) -> void:
	xCoord = new_text.strip_edges().to_float()
	teleportPlayer()
	Menus.toggle_menu(self, 0)

func _on_y_coord_input_text_changed(new_text: String) -> void:
	yCoord = new_text.strip_edges().to_float()


func _on_y_coord_input_text_submitted(new_text: String) -> void:
	yCoord = new_text.strip_edges().to_float()
	teleportPlayer()
	Menus.toggle_menu(self, 0)


func _on_y_coord_input_focus_entered() -> void:
	%yCoordInput.select_all()


# Player Column
func _on_player_shield_button_toggled(toggled_on: bool) -> void:
	GameSettings.playerShield = toggled_on


func _on_laser_slider_value_changed(value: int) -> void:
	GameSettings.laserRange = value


func _on_laser_damage_enabled_toggled(toggled_on: bool) -> void:
	GameSettings.laserRangeOverride = toggled_on


func _on_damage_enabled_toggled(toggled_on: bool) -> void:
	GameSettings.laserDamageOverride = toggled_on


func _on_damage_slider_value_changed(value: int) -> void:
	GameSettings.laserDamage = value


func _on_speed_enabled_toggled(toggled_on: bool) -> void:
	GameSettings.speedOverride = toggled_on


func _on_speed_slider_value_changed(value: float) -> void:
	GameSettings.maxSpeed = value


# Enemy Column
func _on_enemy_shield_button_toggled(toggled_on: bool) -> void:
	SignalBus.enemy_shield_cheat_state.emit(1)


func _on_move_button_toggled(toggled_on: bool) -> void:
	GameSettings.enemyMovement = toggled_on


# World Column
func _on_reset_pressed() -> void:
	GameSettings.loadNumber += 1
	SignalBus.levelReset.emit()
	store_menu_state(1)
	
	get_tree().reload_current_scene()
	GameSettings.menuStatus = false


func _on_border_toggle_toggled(toggled_on: bool) -> void:
	GameSettings.borderToggle = toggled_on
	GameSettings.borderValue = %borderValue.value
	SignalBus.border_size_moved.emit()


func _on_border_slider_value_changed(value: int) -> void:
	GameSettings.borderValue = value
	if GameSettings.borderToggle == true:
		SignalBus.border_size_moved.emit()


func _on_vsync_select_item_selected(index: int) -> void:
	if index == 0: # Enabled (default)
		GameSettings.vSyncSetting = 0
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	elif index == 1: # Adaptive
		GameSettings.vSyncSetting = 1
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
	elif index == 2: # Disabled
		GameSettings.vSyncSetting = 2
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	print(DisplayServer.window_get_vsync_mode())


func _on_volume_slider_value_changed(value: float) -> void:
	var MAIN_BUS_ID: int = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(MAIN_BUS_ID, linear_to_db(value))
	GameSettings.gameVolume = value


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


func _on_enemy_type_changed(index:int) -> void:
	SignalBus.enemy_type_changed.emit(index)
	Menus.toggle_menu(self, 0)


func _on_player_type_changed(index:int) -> void:
	SignalBus.player_type_changed.emit(index)
	Menus.toggle_menu(self, 0)


# Called functions
func teleportPlayer() -> void:
	#GameSettings.teleportCoords = Vector2(xCoord, yCoord)
	SignalBus.teleport_player.emit(xCoord, yCoord)


func store_menu_state(resets: int) -> void:
	if resets == 0:
		file = FileAccess.open("user://defaultmenuoptions.json", FileAccess.WRITE)
	elif resets > 0:
		file = FileAccess.open("user://menuoptions.json", FileAccess.WRITE)
	
	var save_data: Dictionary = {}
	
	# Get the property list of GlobalSettings
	for variables in GameSettings.get_script().get_script_property_list():
		var name: String = variables.name
		# Add each property to save_data if it's not a built-in property
		if variables.type != 0:
			save_data[name] = GameSettings.get(name)
	
	var json: String = JSON.stringify(save_data)
	file.store_string(json)
	file.close()


func set_menu_to_savefile(resets: int) -> void:
	# Chooses file to read based on number of resets
	if resets == 0:
		file = FileAccess.open("user://defaultmenuoptions.json", FileAccess.READ)
	elif resets > 0:
		file = FileAccess.open("user://menuoptions.json", FileAccess.READ)
		
	var json: String = file.get_as_text()
	var save_data = JSON.parse_string(json)
	
	for child in $ColorRect.find_children("", "CheckButton", true, false):
		var value = save_data.get(child.name)
		child.button_pressed = value
	for child in $ColorRect.find_children("", "HSlider", true, false):
		var value = save_data.get(child.name)
		child.value = value
	
	file.close()


func _on_save_game_pressed() -> void:
	print("saved")
	Utility.store_level_data(Navigation.all_systems_data)
