extends Control

@onready var energy_button = $ColorRect/CheatsVBox/MarginContainer/HBoxContainer/EnergyButton


#signal energyCheat(enabled: bool)



func _ready():
	self.visible = false
	
	
func _input(event):
	if Input.is_action_just_pressed("escape"):
		if visible == false:
			visible = true
		elif visible == true:
			visible = false

# Cheats Column
func _on_energy_button_toggled(toggled_on):
	GameSettings.unlimitedEnergy = toggled_on

func _on_health_button_toggled(toggled_on):
	GameSettings.unlimitedHealth = toggled_on
	
func _on_shield_button_toggled(toggled_on):
	GameSettings.unlimitedShield = toggled_on

# Player Column
func _on_player_shield_button_toggled(toggled_on):
	GameSettings.playerShield = toggled_on

func _on_damage_enabled_toggled(toggled_on):
	GameSettings.laserOverride = toggled_on
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
	get_tree().reload_current_scene()

func _on_border_toggle_toggled(toggled_on):
	GameSettings.borderToggle = toggled_on
func _on_border_slider_value_changed(value):
	GameSettings.borderValue = value

func _on_vsync_select_item_selected(index):
	if index == 0: # Enabled (default)
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	elif index == 1: # Adaptive
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ADAPTIVE)
	elif index == 2: # Disabled
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

