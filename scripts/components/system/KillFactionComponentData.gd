class_name KillFactionComponentData
extends BaseComponentData

@export var faction: Utility.FACTION
@export var target_ships_data: Array[ShipState]

func _init() -> void:
	component_id = &"kill_faction"


## Called ONCE by the Mission Generator when the mission is created.
func setup_data(system_faction: Utility.FACTION, diff_mult: float, num_to_kill: int = 0) -> void:
	faction = system_faction
	
	if num_to_kill <= 0:
		num_to_kill = randi_range(1, 4)
		
	var ship_type: Utility.SHIP_TYPES = _get_faction_ship(faction)
	var spawn_radius: int = randi_range(5000, 15000)
	var spawn_origin: Vector2 = Utility.get_random_point_on_circle(spawn_radius)
	
	for i in range(num_to_kill):
		var random_offset: Vector2 = Utility.get_random_point_on_circle(250)
		var spawn_pos: Vector2 = spawn_origin + random_offset
		
		var missionShipInfo: BaseShipInfo = Utility.get_ship_stats(ship_type)
		var scaled_mission_stats: ShipState = ShipState.get_NPC_scaled_stats(diff_mult, missionShipInfo, ShipState.CATEGORY.FACTION)
		scaled_mission_stats.save_position = spawn_pos
		target_ships_data.append(missionShipInfo)


## Called by the View Component when a target ship is destroyed.
func report_ship_destroyed(ship_data: ShipState) -> void:
	if is_finished:
		return
		
	target_ships_data.erase(ship_data)
	
	# If no targets remain, the component finishes itself.
	# The base complete() function will emit 'component_completed'.
	if target_ships_data.is_empty():
		complete()
		MissionManager.complete_mission()


func _get_faction_ship(f: Utility.FACTION) -> Utility.SHIP_TYPES:
	match f:
		Utility.FACTION.FEDERATION: return Utility.SHIP_TYPES.California_Class
		Utility.FACTION.ROMULAN:    return Utility.SHIP_TYPES.Dderidex_Class
		Utility.FACTION.KLINGON:    return Utility.SHIP_TYPES.Klingon_Bird_of_Prey
		_:                          return Utility.SHIP_TYPES.Klingon_Bird_of_Prey
