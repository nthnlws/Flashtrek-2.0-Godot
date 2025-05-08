# Main SignalBus
extends Node

signal enemyDied(enemy)

# Missions
signal missionAccepted(current_mission)
signal finishMission()
signal changePopMessage(text)
signal enteredPlanetComm(planet)
signal exitedPlanetComm(planet)

# Player
signal playerDied

#World navigation
signal galaxy_map_clicked(system_clicked)
signal triggerGalaxyWarp
signal entering_galaxy_warp
signal galaxy_warp_screen_fade
signal galaxy_warp_finished(target_system)
signal entering_new_system

#HUD
signal Quad1_clicked # Declared in HUD_Button script by string name
signal Quad2_clicked
signal Quad3_clicked
signal Quad4_clicked
signal Center_clicked
signal HUDchanged(scale)

signal joystickMoved(playerDirection)

signal playerHealthChanged(hp_current)
signal playerShieldChanged(sp_current)
signal playerEnergyChanged(energy_current)

# Menus
signal pause_menu_clicked

# World
signal border_size_moved
signal world_reset
signal collisionChanged
signal teleport_player(xCoord, yCoord)

signal enemy_shield_cheat_state(shield_state)
signal enemy_type_changed(ENEMY_TYPE)
