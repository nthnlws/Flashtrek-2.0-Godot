class_name KillFactionComponent
extends SystemComponent

var number_to_kill: int
var faction: Utility.FACTION

var spawned_ships: Array[MissionCharacter] = []


func _ready() -> void:
	SignalBus.missionCharacterDied.connect(on_mission_ship_died)


func on_mission_ship_died(ship: MissionCharacter) -> void:
	if ship.is_in_group("mission_ships") and ship in spawned_ships: # If destroyed ship is part of this mission
		spawned_ships.erase(ship)
		if spawned_ships.is_empty(): # All mission ships destroyed
			MissionManager.complete_mission()
			cleanup_component()


func cleanup_component() -> void:
	for ship:MissionCharacter in spawned_ships:
		if is_instance_valid(ship):
			ship.queue_free()
	spawned_ships.clear()


func initialize_component(system_data: SystemData) -> void:
	# Set component-specific properties from system_data
	number_to_kill = randi_range(1, 4)
	faction = system_data.faction
	var root_level: Node = get_tree().get_root().get_node("Game/Level")
	var spawn_radius: int = randi_range(5000, 15000)

	var spawn_positions: Array[Vector2] = []
	var spawn_origin:Vector2 = Utility.get_random_point_on_circle(spawn_radius)
	for i:int in number_to_kill:
		var random_offset: Vector2 = Utility.get_random_point_on_circle(250)
		var new_spawn_pos: Vector2 = spawn_origin + random_offset
		spawn_positions.append(new_spawn_pos)


	if faction == Utility.FACTION.FEDERATION:
		for i:int in number_to_kill:
			var new_ship: MissionCharacter = root_level.spawn_mission_ship(Utility.SHIP_TYPES.California_Class, spawn_positions[i], true)
			spawned_ships.append(new_ship)
			var ship_data: MissionShipData = MissionShipData.generate_mission_ship_data(
				spawn_positions[i],
				faction,
				system_data.system_difficulty_mult,
				i,
				Utility.SHIP_TYPES.Klingon_Bird_of_Prey,
				true)
			system_data.mission_ship_list.append(ship_data)
	elif faction == Utility.FACTION.ROMULAN:
		for i:int in number_to_kill:
			var new_ship: MissionCharacter = root_level.spawn_mission_ship(Utility.SHIP_TYPES.Dderidex_Class, spawn_positions[i], true)
			spawned_ships.append(new_ship)
			var ship_data: MissionShipData = MissionShipData.generate_mission_ship_data(
				spawn_positions[i],
				faction,
				system_data.system_difficulty_mult,
				i,
				Utility.SHIP_TYPES.Klingon_Bird_of_Prey,
				true)
			system_data.mission_ship_list.append(ship_data)
	elif faction == Utility.FACTION.KLINGON:
		for i:int in number_to_kill:
			var new_ship: MissionCharacter = root_level.spawn_mission_ship(Utility.SHIP_TYPES.Klingon_Bird_of_Prey, spawn_positions[i], true)
			spawned_ships.append(new_ship)
			var ship_data: MissionShipData = MissionShipData.generate_mission_ship_data(
				spawn_positions[i],
				faction,
				system_data.system_difficulty_mult,
				i,
				Utility.SHIP_TYPES.Klingon_Bird_of_Prey,
				true)
			system_data.mission_ship_list.append(ship_data)
