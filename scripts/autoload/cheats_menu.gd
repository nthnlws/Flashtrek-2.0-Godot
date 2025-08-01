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
	var loot_params: Array = UpgradePickup.MODULE_TYPES.keys().map(func(s:String): return s.to_lower())
	Console.add_command_autocomplete_list("upgrade", PackedStringArray(loot_params))
	
	Console.add_command( # Teleport player
		"teleport", # Command name
		teleport_command, # Function call
		["x_coord", "y_coord"], # Argument params
		2, # Required params
		"Teleports player to input coords", # Description
		)
	Console.add_command( # Upgrade loot
		"kill", # Command name
		kill_command, # Function call
		["ship_type", "number"], # Argument params
		1, # Required params
		"Kills random ship based on input type (Neutral or Enemy)", # Description
		)
	var kill_params: Array[String] = ["neutral", "enemy"]
	Console.add_command_autocomplete_list("kill_command", PackedStringArray(kill_params))


func spawn_loot_command(type_str: String, number:String = "1") -> void:
	type_str = type_str.to_upper()
	var type:int = UpgradePickup.MODULE_TYPES[type_str]
	var position: Vector2 = LevelData.player.global_position
	SignalBus.spawnLoot.emit(type, position, int(number))


func teleport_command(x_coord:String, y_coord: String) -> void:
	var position:Vector2 = Vector2(int(x_coord), int(y_coord))
	SignalBus.teleport_player.emit(position)


func kill_command(ship_type:String, number:String = "1") -> void:
	if number == "all":
		if ship_type == "neutral" or ship_type == "neutrals":
			while not LevelData.neutralShips.is_empty():
				var ship_to_explode = LevelData.neutralShips.pop_front()
				ship_to_explode.explode()
		elif ship_type == "enemy" or ship_type == "enemies":
			while not LevelData.enemyShips.is_empty():
				var ship_to_explode = LevelData.enemyShips.pop_front()
				ship_to_explode.explode()
	else:
		var num = int(number)
		if ship_type == "neutral" or ship_type == "neutrals":
			var neutral_ships:Array[NeutralCharacter] = LevelData.neutralShips
			for i in range(num):
				if neutral_ships.size() > 0:
					var ship:NeutralCharacter = neutral_ships[randi_range(0, neutral_ships.size() - 1)]
					ship.explode()
				else:
					print("No ships of type '%s' to kill" % ship_type)
		elif ship_type == "enemy" or ship_type == "enemies":
			var enemy_ships:Array[EnemyCharacter] = LevelData.enemyShips
			for i in range(num):
				if enemy_ships.size() > 0:
					var ship:EnemyCharacter = enemy_ships[randi_range(0, enemy_ships.size() - 1)]
					ship.explode()
				else:
					print("No ships of type '%s' to kill" % ship_type)
