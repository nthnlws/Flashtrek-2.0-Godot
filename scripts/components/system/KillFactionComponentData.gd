class_name KillFactionComponentData
extends SystemComponentData

@export var faction: Utility.FACTION
@export var target_ships_data: Array[ShipState]

func _init() -> void:
	component_id = &"kill_faction"


## Called by SystemData.add_component() when the mission is created.
func setup_from_mission(mission: MissionData, context: SystemData) -> void:
	faction = mission.enemy_faction

	var num_to_kill: int = mission.enemy_target_count
	if num_to_kill <= 0:
		num_to_kill = randi_range(1, 4)

	var ship_type: Utility.SHIP_TYPES = Utility.get_faction_ship_type(faction)
	var spawn_radius: int = randi_range(5000, 15000)
	var spawn_origin: Vector2 = Utility.get_random_point_on_circle(spawn_radius)

	for i in range(num_to_kill):
		var random_offset: Vector2 = Utility.get_random_point_on_circle(250)
		var spawn_pos: Vector2 = spawn_origin + random_offset

		var missionShipInfo: BaseShipInfo = Utility.get_ship_stats(ship_type)
		var scaled_mission_stats: ShipState = ShipState.get_NPC_scaled_stats(context.system_difficulty_mult, missionShipInfo, ShipState.CATEGORY.FACTION)
		scaled_mission_stats.save_position = spawn_pos
		target_ships_data.append(scaled_mission_stats)
