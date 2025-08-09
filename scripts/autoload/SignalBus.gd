# Main SignalBus
extends Node

signal enemyShipDied(enemy:EnemyCharacter)
signal spawnLoot(type:UpgradePickup.MODULE_TYPES, postition:Vector2)
signal neutralShipDied(enemy:NeutralCharacter)
signal updateLevelData(all_system_data:Dictionary)

# Missions
signal missionAccepted(current_mission:Dictionary)
signal finishMission
signal changePopMessage(text:String)
signal updateScore(score:int)

signal enteredPlanetComm(planet:Node2D)
signal exitedPlanetComm(planet:Node2D)

# Player
signal playerDied
signal playerRespawned

signal playerHealthChanged(hp_current:float)
signal playerMaxHealthChanged(hp_max:float)
signal playerMaxShieldChanged(sp_max:float)
signal playerShieldChanged(sp_current:float)
signal playerEnergyChanged(energy_current:float)
signal playerMaxEnergyChanged(energy_max:float)

signal playerShieldOff
signal playerShieldOn

#World navigation
signal galaxy_map_clicked(system_clicked:String)
signal triggerGalaxyWarp
signal entering_galaxy_warp
signal galaxy_warp_screen_fade
signal galaxy_warp_finished(target_system)
signal entering_new_system

#HUD
signal Center_clicked # Declared in HUD_Button script by string name
signal TopLeft_clicked
signal TopRight_clicked
signal BottomLeft_clicked
signal BottomRight_clicked
signal HUDchanged(scale:float)

signal toggleQ2HUD(state:String)
signal toggleQ3HUD(state:String)
signal toggleQ4HUD(state:String)

signal joystickMoved(playerDirection:Vector2)

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
