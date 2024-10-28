extends Node

signal level_loaded(current_level)
signal levelReset

signal playerHealthChanged(hp_current)
signal playerShieldChanged(sp_current)
signal playerEnergyChanged(energy_current)

#World navigation
signal galaxy_map_clicked(system_clicked)

#HUD
signal Quadrant1_clicked
signal Quadrant2_clicked
signal Quadrant3_clicked
signal Quadrant4_clicked
signal CenterButton_clicked
signal HUDchanged(scale)

#Menus
signal pause_menu_clicked
signal credits_clicked
signal cheats_clicked
signal settings_clicked

signal border_size_moved
signal world_reset
signal collisionChanged
signal teleport_player(xCoord, yCoord)

signal enemy_shield_cheat_state(shield_state)
signal enemy_type_changed(ENEMY_TYPE)

var player: Node = null
var HUD: Node = null
var pauseMenu: Node = null
var settingsButton: Node = null
var saveGame: Node = null
