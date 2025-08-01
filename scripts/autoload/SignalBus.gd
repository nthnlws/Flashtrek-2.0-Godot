# Main SignalBus
extends Node

signal enemyShipDied(enemy:EnemyCharacter)
signal spawnLoot(type:UpgradePickup.MODULE_TYPES, postition:Vector2)
signal neutralShipDied(enemy:NeutralCharacter)
signal updateLevelData(all_system_data:Dictionary)

# Missions
signal missionAccepted(current_mission)
signal finishMission()
signal changePopMessage(text)
signal enteredPlanetComm(planet)
signal exitedPlanetComm(planet)
signal updateScore(score)

# Player
signal playerDied
signal playerRespawned

signal playerHealthChanged(hp_current)
signal playerMaxHealthChanged(hp_max)
signal playerMaxShieldChanged(sp_max)
signal playerShieldChanged(sp_current:float)
signal playerEnergyChanged(energy_current:float)
signal playerMaxEnergyChanged(energy_max:float)

signal playerShieldOff
signal playerShieldOn

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

# Menus
signal pause_menu_clicked

# World
signal border_size_moved
signal world_reset
signal collisionChanged
signal teleport_player(position:Vector2)

signal enemy_shield_cheat_state(shield_state)
signal enemy_type_changed(ENEMY_TYPE: Utility.SHIP_TYPES)
signal player_type_changed(PLAYER_TYPE: Utility.SHIP_TYPES)

# Level Creation
signal level_entity_added(node:Node2D, type:String)
signal levelReset

# Audio
signal UIselectSound
signal UIclickSound
