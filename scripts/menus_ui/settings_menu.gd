extends CanvasLayer

@onready var _bus := AudioServer.get_bus_index("Master")
@export var closeButton:Button

var file: FileAccess
signal close_button_pressed

func _ready() -> void:
	# Creates default save file on first load, otherwise restores settings to previous state
	if GameSettings.loadNumber == 0: 
		store_menu_state(0)
		#set_menu_to_savefile(0)
	elif GameSettings.loadNumber > 0: 
		set_menu_to_savefile(1)
		SignalBus.world_reset.emit()
		
	
	%gameVolume.value = db_to_linear(AudioServer.get_bus_volume_db(_bus))
	

# Cheats Column
func _on_energy_button_toggled(toggled_on: bool) -> void:
	GameSettings.unlimitedEnergy = toggled_on

func _on_health_button_toggled(toggled_on: bool) -> void:
	GameSettings.unlimitedHealth = toggled_on
	
func _on_shield_button_toggled(toggled_on: bool) -> void:
	GameSettings.unlimitedShield = toggled_on

func _on_no_collision_toggled(toggled_on: bool) -> void:
	GameSettings.noCollision = toggled_on
	SignalBus.collisionChanged.emit(toggled_on)


# Player Column
func _on_player_shield_button_toggled(toggled_on: bool) -> void:
	GameSettings.playerShield = toggled_on

func _on_laser_slider_value_changed(value: int) -> void:
	GameSettings.laserRange = value

func _on_laser_damage_enabled_toggled(toggled_on: bool):
	GameSettings.laserRangeOverride = toggled_on

func _on_damage_enabled_toggled(toggled_on: bool) -> void:
	GameSettings.laserDamageOverride = toggled_on

func _on_damage_slider_value_changed(value:float) -> void:
	GameSettings.laserDamage = value

func _on_speed_enabled_toggled(toggled_on: bool) -> void:
	GameSettings.speedOverride = toggled_on
func _on_speed_slider_value_changed(value: float):
	GameSettings.maxSpeed = value


# Enemy Column
func _on_enemy_shield_button_toggled(toggled_on: bool) -> void:
	GameSettings.enemyShield = toggled_on

func _on_move_button_toggled(toggled_on: bool) -> void:
	GameSettings.enemyMovement = toggled_on


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

func _on_volume_slider_value_changed(value: float):
	AudioServer.set_bus_volume_db(_bus, linear_to_db(value))
	GameSettings.gameVolume = value


func store_menu_state(resets: int):
	if resets == 0:
		file = FileAccess.open("user://defaultmenuoptions.json", FileAccess.WRITE)
	elif resets > 0:
		file = FileAccess.open("user://menuoptions.json", FileAccess.WRITE)
	
	var save_data: Dictionary = {}
	
	# Get the property list of GlobalSettings
	for variables in GameSettings.get_script().get_script_property_list():
		var var_name: String = variables.name
		# Add each property to save_data if it's not a built-in property
		if variables.type != 0:
			save_data[var_name] = GameSettings.get(var_name)
	
	var json = JSON.stringify(save_data)
	file.store_string(json)
	file.close()

func set_menu_to_savefile(resets: int):
	# Chooses file to read based on number of resets
	file = FileAccess.open("user://menuoptions.json", FileAccess.READ)
	
	var json: String = file.get_as_text()
	var save_data = JSON.parse_string(json)
	
	for child in $ColorRect.find_children("", "CheckButton", true, false):
		if child != null:
			var value = save_data.get(child.name)
			child.button_pressed = value
	for child in $ColorRect.find_children("", "HSlider", true, false):
		if child != null:
			var value = save_data.get(child.name)
			child.value = value
	
	file.close()


func _on_close_button_pressed() -> void:
	close_button_pressed.emit()
