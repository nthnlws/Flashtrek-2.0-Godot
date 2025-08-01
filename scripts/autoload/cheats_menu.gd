extends Node


func _ready() -> void:
	Console.pause_enabled = true
	
	Console.add_command( # Upgrade loot
		"upgrade", # Command name
		spawn_loot_command, # Function call
		["type", "number"], # Argument params
		1, # Required params
		"Spawns a damage upgrade on the player", # Description
		)
	var upgrade_params: Array = UpgradePickup.MODULE_TYPES.keys().map(func(s:String): return s.to_lower())
	Console.add_command_autocomplete_list("upgrade", PackedStringArray(upgrade_params))
	
	Console.add_command( # Teleport player
		"teleport", # Command name
		teleport_command, # Function call
		["x_coord", "y_coord"], # Argument params
		2, # Required params
		"Teleports player to input coords", # Description
		)


func spawn_loot_command(type_str: String, number:String = "1") -> void:
	type_str = type_str.to_upper()
	var type:int = UpgradePickup.MODULE_TYPES[type_str]
	var position: Vector2 = LevelData.player.global_position
	SignalBus.spawnLoot.emit(type, position, int(number))


func teleport_command(x_coord:String, y_coord: String) -> void:
	var position:Vector2 = Vector2(int(x_coord), int(y_coord))
	SignalBus.teleport_player.emit(position)
