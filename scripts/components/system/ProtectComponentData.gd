class_name ProtectComponentData
extends SystemComponentData

## Emitted when a protected ship is destroyed. Listen for this in your MissionManager.
signal mission_failed 

@export var faction: Utility.FACTION
@export var protected_ships_data: Array[ShipState]
@export var is_failed: bool = false

func _init() -> void:
	component_id = &"protect_ship"


## Called by SystemData.add_component() when the mission is accepted.
func setup_from_mission(mission: MissionData, context: SystemData) -> void:
	faction = Utility.get_enemy_faction(context.faction)
	var base_spawn_pos: Vector2 = _calculate_base_spawn(context.system_size)
	var ship_type: Utility.SHIP_TYPES = Utility.get_faction_ship_type(faction)

	# Generate random number of ships to protect
	var NUM_SHIPS_TO_PROTECT = 1
	for i in range(NUM_SHIPS_TO_PROTECT):
		var random_offset: Vector2 = Utility.get_random_point_on_circle(250)
		var spawn_pos: Vector2 = base_spawn_pos + random_offset

		var missionShipInfo: BaseShipInfo = Utility.get_ship_stats(ship_type)
		var scaled_mission_stats: ShipState = ShipState.get_NPC_scaled_stats(context.system_difficulty_mult, missionShipInfo, ShipState.CATEGORY.FACTION)
		scaled_mission_stats.save_position = spawn_pos
		protected_ships_data.append(scaled_mission_stats)


## Called by the View Component when the physical ship blows up.
func report_ship_destroyed(ship_data: ShipState) -> void:
	if is_finished or is_failed: 
		return
		
	# Remove the data so it doesn't respawn if the player leaves and returns
	protected_ships_data.erase(ship_data)
	
	# Any ship dying fails this mission type
	is_failed = true
	mission_failed.emit()
	MissionManager.fail_mission()

	# The mission is over either way (fail or succeed) - finalize the
	# component so the owning ComponentManager despawns its view Node.
	mark_completed()


# --- Internal Generation Helpers ---
func _calculate_base_spawn(system_size: float) -> Vector2:
	var offset: int = 5000
	var spawn_options: Array[Vector2] = [
		Vector2(system_size - offset, system_size - offset),
		Vector2(-system_size + offset, -system_size + offset),
		Vector2(-system_size + offset, system_size - offset),
		Vector2(system_size - offset, -system_size + offset),
	]
	return spawn_options.pick_random()
