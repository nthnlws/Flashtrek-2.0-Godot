extends Node

signal enemyDied(enemy)

signal level_loaded(current_level)
signal levelReset
signal missionAccepted(current_mission)

signal playerHealthChanged(hp_current)
signal playerShieldChanged(sp_current)
signal playerEnergyChanged(energy_current)

#World navigation
signal galaxy_map_clicked(system_clicked)
signal entering_galaxy_warp
signal galaxy_warp_finished

#HUD
signal Quad1_clicked
signal Quad2_clicked
signal Quad3_clicked
signal Quad4_clicked
signal Center_clicked
signal HUDchanged(scale)

signal joystickMoved(playerDirection)

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
