extends Node


func _ready() -> void:
	Console.pause_enabled = true
	
	_add_cheat_commands()


func _add_cheat_commands() -> void:
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
		"Kills random ship based on input type (Faction or Enemy)", # Description
		)
	var kill_params: Array = ["faction", "enemy"]
	Console.add_command_autocomplete_list("kill_command", PackedStringArray(kill_params))

	Console.add_command( # Upgrade loot
		"score", # Command name
		add_score, # Function call
		["faction", "number"], # Argument params
		2, # Required params
		"Sets player faction score to number", # Description
		)
	var factions: Array = ["federation", "romulan", "klingon", "neutral"]
	Console.add_command_autocomplete_list("add_score", PackedStringArray(factions))
	
	Console.add_command( # Upgrade loot
		"spawn", # Command name
		spawn_ship, # Function call
		["ship"], # Argument params
		1, # Required params
		"Spawns a faction ship (uses int for ship type)", # Description
		)


func spawn_ship(ship_type:String) -> void:
	var ship:int = int(ship_type)

	SignalBus.spawnShip.emit(ship)
	print("Spawned ship of type: %s" % Utility.SHIP_TYPES.keys()[ship])


func add_score(faction: String, number: String) -> void:
	var score:int = int(number)
	if faction.to_lower() == "fed" or faction.to_lower() == "federation":
		SignalBus.reputationChanged.emit(Utility.FACTION.FEDERATION, score)
	if faction.to_lower() == "kling" or faction.to_lower() == "klingon":
		SignalBus.reputationChanged.emit(Utility.FACTION.KLINGON, score)
	if faction.to_lower() == "rom" or faction.to_lower() == "romulan":
		SignalBus.reputationChanged.emit(Utility.FACTION.ROMULAN, score)
	if faction.to_lower() == "neut" or faction.to_lower() == "neutral":
		SignalBus.reputationChanged.emit(Utility.FACTION.NEUTRAL, score)
	else:
		print("Unknown faction '%s' for score command." % faction)

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
				var ship_to_explode:NeutralCharacter = LevelData.neutralShips.pop_front()
				ship_to_explode.explode()
		elif ship_type == "faction":
			while not LevelData.factionShips.is_empty():
				var ship_to_explode:NeutralCharacter = LevelData.factionShips.pop_front()
				ship_to_explode.explode()
	else:
		var num:int = int(number)
		if ship_type == "neutral" or ship_type == "neutrals":
			var neutral_ships:Array[NeutralCharacter] = LevelData.neutralShips
			for i:int in range(num):
				if neutral_ships.size() > 0:
					var ship:NeutralCharacter = neutral_ships[randi_range(0, neutral_ships.size() - 1)]
					ship.explode()
				else:
					print("No ships of type '%s' to kill" % ship_type)
		elif ship_type == "faction":
			var factionShips:Array[FactionCharacter] = LevelData.factionShips
			for i:int in range(num):
				if factionShips.size() > 0:
					var ship:FactionCharacter = factionShips[randi_range(0, factionShips.size() - 1)]
					ship.explode()
				else:
					print("No ships of type '%s' to kill" % ship_type)
