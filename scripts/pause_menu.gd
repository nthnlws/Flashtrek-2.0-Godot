extends Control

@onready var _bus := AudioServer.get_bus_index("Master")
@onready var anim: AnimationPlayer = $"../../transition_overlays/AnimationPlayer"
@onready var color_rect: ColorRect = $"../../transition_overlays/ColorRect"


signal teleport

var xCoord
var yCoord
var file


func _ready():
	SignalBus.pauseMenu = self
	
	SignalBus.menu_clicked.connect(toggle_menu) #Connect HUD menu button to toggle
	
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
	
	
func _input(event):
	if Input.is_action_just_pressed("escape"):
		toggle_menu()


func toggle_menu():
	if visible == false:
		mouse_filter = Control.MOUSE_FILTER_STOP
		GameSettings.menuStatus = true
		visible = true
	elif visible == true:
		mouse_filter = Control.MOUSE_FILTER_PASS
		GameSettings.menuStatus = false
		visible = false

#Header buttons
func _on_close_menu_button_pressed():
	toggle_menu()
	
func _on_main_menu_button_pressed():
	color_rect.z_index = 2
	z_index = 0
	anim.play("fade_out")
	await anim.animation_finished
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	
func _on_close_game_button_pressed():
	get_tree().quit()

# Cheats Column
func _on_energy_button_toggled(toggled_on):
	GameSettings.unlimitedEnergy = toggled_on

func _on_health_button_toggled(toggled_on):
	GameSettings.unlimitedHealth = toggled_on
	
func _on_shield_button_toggled(toggled_on):
	GameSettings.unlimitedShield = toggled_on

func _on_no_collision_toggled(toggled_on):
	GameSettings.noCollision = toggled_on
	SignalBus.collisionChanged.emit(toggled_on)


func _on_x_coord_input_focus_entered():
	%xCoordInput.select_all()
func _on_x_coord_input_text_changed(new_text):
	xCoord = new_text.strip_edges().to_float()
func _on_x_coord_input_text_submitted(new_text):
	xCoord = new_text.strip_edges().to_float()
	updateVector()
	toggle_menu()

func _on_y_coord_input_text_changed(new_text):
	yCoord = new_text.strip_edges().to_float()
func _on_y_coord_input_text_submitted(new_text):
	yCoord = new_text.strip_edges().to_float()
	updateVector()
	toggle_menu()
func _on_y_coord_input_focus_entered():
	%yCoordInput.select_all()
	
	


# Player Column
func _on_player_shield_button_toggled(toggled_on):
	GameSettings.playerShield = toggled_on

func _on_laser_slider_value_changed(value):
	GameSettings.laserRange = value
func _on_laser_damage_enabled_toggled(toggled_on):
	GameSettings.laserRangeOverride = toggled_on

func _on_damage_enabled_toggled(toggled_on):
	GameSettings.laserDamageOverride = toggled_on
func _on_damage_slider_value_changed(value):
	GameSettings.laserDamage = value
	
func _on_speed_enabled_toggled(toggled_on):
	GameSettings.speedOverride = toggled_on
func _on_speed_slider_value_changed(value):
	GameSettings.maxSpeed = value


# Enemy Column
func _on_enemy_shield_button_toggled(toggled_on):
	GameSettings.enemyShield = toggled_on

func _on_move_button_toggled(toggled_on):
	GameSettings.enemyMovement = toggled_on

# World Column
func _on_reset_pressed():
	GameSettings.loadNumber += 1
	store_menu_state(1)
	get_tree().reload_current_scene()
	
	#var level_node_path = "res://scenes/Level.tscn"  # Path to the Level scene
	#var level_node = get_node("/root/Game/Level")  # Reference to the existing Level node

	GameSettings.menuStatus = false

func _on_border_toggle_toggled(toggled_on):
	GameSettings.borderToggle = toggled_on
	GameSettings.gameSize = %gameSize.value
	SignalBus.border_size_moved.emit()
	
	
func _on_border_slider_value_changed(value):
	GameSettings.gameSize = value
	if GameSettings.borderToggle == true:
		SignalBus.border_size_moved.emit()

func _on_vsync_select_item_selected(index):
	if index == 0: # Enabled (default)
		GameSettings.vSyncSetting = 0
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	elif index == 1: # Adaptive
		GameSettings.vSyncSetting = 1
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
	elif index == 2: # Disabled
		GameSettings.vSyncSetting = 2
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _on_volume_slider_value_changed(value):
	AudioServer.set_bus_volume_db(_bus, linear_to_db(value))
	GameSettings.gameVolume = value

# Called functions
func updateVector():
	GameSettings.teleportCoords = Vector2(xCoord, yCoord)
	teleport.emit()

func store_menu_state(resets):
	if resets == 0:
		file = FileAccess.open("user://defaultmenuoptions.json", FileAccess.WRITE)
	elif resets > 0:
		file = FileAccess.open("user://menuoptions.json", FileAccess.WRITE)
	
	var save_data = {}
	
	# Get the property list of GlobalSettings
	for variables in GameSettings.get_script().get_script_property_list():
		var name = variables.name
		# Add each property to save_data if it's not a built-in property
		if variables.type != 0:
			save_data[name] = GameSettings.get(name)
	
	var json = JSON.stringify(save_data)
	file.store_string(json)
	file.close()

func set_menu_to_savefile(resets):
	# Chooses file to read based on number of resets
	if resets == 0:
		file = FileAccess.open("user://defaultmenuoptions.json", FileAccess.READ)
	elif resets > 0:
		file = FileAccess.open("user://menuoptions.json", FileAccess.READ)
		
	var json = file.get_as_text()
	var save_data = JSON.parse_string(json)
	
	for child in $ColorRect.find_children("", "CheckButton", true, false):
		var value = save_data.get(child.name)
		child.button_pressed = value
	for child in $ColorRect.find_children("", "HSlider", true, false):
		var value = save_data.get(child.name)
		child.value = value
	
	file.close()








