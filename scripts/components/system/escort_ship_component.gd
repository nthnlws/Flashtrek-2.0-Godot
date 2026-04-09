class_name ProtectShipComponent
extends SystemComponent

var number_to_protect: int = 1
var faction: Utility.FACTION

var spawned_ships: Array[MissionCharacter]


func _ready() -> void:
	SignalBus.missionCharacterDied.connect(on_mission_ship_died)


func on_mission_ship_died(ship: MissionCharacter) -> void:
	# If destroyed ship is part of this mission
	if ship.is_in_group("mission_ships") and ship in spawned_ships:
		spawned_ships.erase(ship)
		MissionManager.fail_mission()
		cleanup_component()


func cleanup_component() -> void:
	for ship:MissionCharacter in spawned_ships:
		if is_instance_valid(ship):
			ship.queue_free()
	spawned_ships.clear()
	system_data.remove_component(SystemData.SystemComponentType.ESCORT)


func _on_ready_logic() -> void:
	# Set component-specific properties from system_data
	#number_to_protect = randi_range(1, 2)
	faction = Utility.get_enemy_faction(system_data.faction)
	var root_level: Node = get_tree().get_root().get_node("Game/Level")
	
	var system_size = LevelManager.current_system_data.system_size
	var offset: int = 5000
	var spawn_options: Array[Vector2] = [ # Corner spawns
		Vector2(system_size - offset, system_size - offset),
		Vector2(-system_size + offset, -system_size + offset),
		Vector2(-system_size + offset, system_size - offset),
		Vector2(system_size - offset, -system_size + offset),
	]
	var base_spawn_pos: Vector2 = spawn_options.pick_random()
	var offset_spawn_pos: Array[Vector2]
	for i:int in number_to_protect:
		var random_offset: Vector2 = Utility.get_random_point_on_circle(250)
		var new_spawn_pos: Vector2 = base_spawn_pos + random_offset
		offset_spawn_pos.append(new_spawn_pos)
	
	const FACTION_SHIP: Dictionary[Utility.FACTION, Utility.SHIP_TYPES] = {
		Utility.FACTION.FEDERATION: Utility.SHIP_TYPES.Cardenas_Class,
		Utility.FACTION.ROMULAN:    Utility.SHIP_TYPES.Lanora_Class,
		Utility.FACTION.KLINGON:    Utility.SHIP_TYPES.Klingon_Bird_of_Prey,
	}
	var ship_type: Utility.SHIP_TYPES = FACTION_SHIP.get(faction)
	for i: int in number_to_protect:
		var new_ship: MissionCharacter = root_level.spawn_mission_ship(ship_type, offset_spawn_pos[i], true)
		spawned_ships.append(new_ship)
		var ship_data: MissionShipData = MissionShipData.generate_mission_ship_data(
			offset_spawn_pos[i],
			faction,
			system_data.system_difficulty_mult,
			i,
			ship_type,
			false, true)
		system_data.mission_ship_list.append(ship_data)
	
