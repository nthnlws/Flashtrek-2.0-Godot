extends Node

signal level_loaded(current_level)
signal levelReset

signal playerHealthChanged(hp_current)
signal playerShieldChanged(sp_current)
signal playerEnergyChanged(energy_current)

#World navigation
signal galaxy_map_clicked(system_clicked)

#HUD
signal Q1hudButton_clicked
signal Q2hudButton_clicked
signal Q3hudButton_clicked
signal Q4hudButton_clicked
signal CenterHUDbutton_clicked
signal HUDchanged(scale)

#Menus
signal pause_menu_clicked
signal credits_clicked
signal cheats_clicked
signal settings_clicked

signal border_size_moved
signal world_reset
signal collisionChanged()

var player: Node = null
var HUD: Node = null
var pauseMenu: Node = null
var settingsButton: Node = null
var saveGame: Node = null
