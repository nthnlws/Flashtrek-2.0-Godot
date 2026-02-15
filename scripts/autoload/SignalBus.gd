# Main SignalBus
extends Node

func _init() -> void:
	@warning_ignore_start("UNUSED_SIGNAL")
	pass

signal factionShipDied(enemy:FactionCharacter)
signal neutralShipDied(enemy:NeutralCharacter)
signal missionCharacterDied(mission_ship)
signal spawnLoot(type:UpgradePickup.MODULE_TYPES, postition:Vector2)
signal updateGalaxyData(galaxy_data:GalaxyData)
signal galaxyDataUpdated(galaxy_data:GalaxyData)

# Missions
signal changePopMessage(text:String)
signal updateScore(score:int)

signal enteredPlanetComm(planet:Node2D)
signal exitedPlanetComm(planet:Node2D)

signal reputation_change_triggered(faction:Utility.FACTION, score:float)

# Player
signal playerDied
signal playerRespawned

signal playerHealthChanged(hp_current:float)
signal playerMaxHealthChanged(hp_max:float)
signal playerMaxShieldChanged(sp_max:float)
signal playerShieldChanged(sp_current:float)
signal playerEnergyChanged(energy_current:float)
signal playerMaxEnergyChanged(energy_max:float)

signal playerUpgradeApplied(pickup_type:UpgradePickup.MODULE_TYPES)
signal playerShieldOff
signal playerShieldOn

#World navigation
signal triggerGalaxyWarp
signal entering_galaxy_warp
signal galaxy_warp_screen_fade
signal galaxy_warp_finished(system_data:SystemData)
signal entering_new_system
signal system_changed(system_data:SystemData)

#HUD
signal Center_clicked # Declared in HUD_Button script by string name
signal TopLeft_clicked
signal TopRight_clicked
signal BottomLeft_clicked
signal BottomRight_clicked
signal HUDchanged(scale:float)

signal toggleQ2HUD(state:String) # States: "on", "off"
signal toggleQ3HUD(state:String) # States: "on", "off"
signal toggleQ4HUD(state:String) # States: "on", "off"

signal joystickMoved(playerDirection:Vector2)

# Menus
signal pause_menu_clicked

# World
signal border_size_moved
signal world_reset
signal collisionChanged
signal spawnShip(ship_type:Utility.SHIP_TYPES)

signal enemy_shield_cheat_state(shield_state)
signal enemy_type_changed(ENEMY_TYPE: Utility.SHIP_TYPES)
signal player_type_changed(PLAYER_TYPE: Utility.SHIP_TYPES)

# Level Creation
signal levelReset

# Audio
signal UIselectSound
signal UIclickSound
