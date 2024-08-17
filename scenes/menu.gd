extends Control

@onready var _bus := AudioServer.get_bus_index("Master")

signal teleport
signal world_reset
signal border_size_moved

var xCoord
var yCoord 

func _ready():
	store_menu_state()
	Global.pauseMenu = self
	
	self.visible = false
	%volumeSlider.value = db_to_linear(AudioServer.get_bus_volume_db(_bus))
	
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

func _on_close_button_pressed():
	toggle_menu()

# Cheats Column
func _on_energy_button_toggled(toggled_on):
	GameSettings.unlimitedEnergy = toggled_on

func _on_health_button_toggled(toggled_on):
	GameSettings.unlimitedHealth = toggled_on
	
func _on_shield_button_toggled(toggled_on):
	GameSettings.unlimitedShield = toggled_on
	
func _on_x_coord_input_text_changed(new_text):
	xCoord = new_text.strip_edges().to_float()
func _on_y_coord_input_text_changed(new_text):
	yCoord = new_text.strip_edges().to_float()
func _on_x_coord_input_text_submitted(new_text):
	xCoord = new_text.strip_edges().to_float()
	updateVector()
	toggle_menu()
func _on_y_coord_input_text_submitted(new_text):
	yCoord = new_text.strip_edges().to_float()
	updateVector()
	toggle_menu()


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
	world_reset.emit()
	var level_node_path = "res://scenes/Level.tscn"  # Path to the Level scene
	var level_node = get_node("/root/Game/Level")  # Reference to the existing Level node

	if level_node:
		store_menu_state()
		
		var parent_node = level_node.get_parent()  # Get the parent of the Level node
		var level_node_index = level_node.get_index()  # Get the index of the Level node in the parent's children

		 # Remove the current Level node
		level_node.queue_free()

		# Load the Level scene again
		var new_level_instance = preload("res://scenes/level.tscn").instantiate()

		parent_node.add_child(new_level_instance)
		
		# Optionally, restore the position in the scene tree
		parent_node.move_child(new_level_instance, level_node_index)
		
		# Restore any saved state if necessary (optional)
	GameSettings.menuStatus = false

func _on_border_toggle_toggled(toggled_on):
	GameSettings.borderToggle = toggled_on
	border_size_moved.emit() 
func _on_border_slider_value_changed(value):
	GameSettings.gameSize = value
	print(GameSettings.gameSize)
	if GameSettings.borderToggle == true:
		border_size_moved.emit()

func _on_vsync_select_item_selected(index):
	if index == 0: # Enabled (default)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	elif index == 1: # Adaptive
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
	elif index == 2: # Disabled
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

func _on_volume_slider_value_changed(value):
	AudioServer.set_bus_volume_db(_bus, linear_to_db(value))

# Called functions
func updateVector():
	GameSettings.teleportCoords = Vector2(xCoord, yCoord)
	teleport.emit()

func store_menu_state():
	pass
