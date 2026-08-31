class_name ProtectComponentData
extends BaseComponentData

## Emitted when a protected ship is destroyed. Listen for this in your MissionManager.
signal mission_failed 

@export var faction: Utility.FACTION
@export var protected_ships_data: Array[ShipState]
@export var is_failed: bool = false

func _init() -> void:
	component_id = &"protect_ship"


## Called by the Mission Generator ONCE when the mission is accepted.
func setup_data(system_size: float, system_faction: Utility.FACTION, diff_mult: float, num_ships: int = 1) -> void:
	faction = Utility.get_enemy_faction(system_faction)
	var base_spawn_pos: Vector2 = _calculate_base_spawn(system_size)
	var ship_type: Utility.SHIP_TYPES = _get_faction_ship(faction)
	
	# Generate the specific ship data and store it locally in THIS component
	for i in range(num_ships):
		var random_offset: Vector2 = Utility.get_random_point_on_circle(250)
		var spawn_pos: Vector2 = base_spawn_pos + random_offset
		
		var missionShipInfo: BaseShipInfo = Utility.get_ship_stats(ship_type)
		var scaled_mission_stats: ShipState = ShipState.get_NPC_scaled_stats(diff_mult, missionShipInfo, ShipState.CATEGORY.FACTION)
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


func _get_faction_ship(f: Utility.FACTION) -> Utility.SHIP_TYPES:
	const FACTION_SHIP: Dictionary = {
		Utility.FACTION.FEDERATION: Utility.SHIP_TYPES.Cardenas_Class,
		Utility.FACTION.ROMULAN:    Utility.SHIP_TYPES.Lanora_Class,
		Utility.FACTION.KLINGON:    Utility.SHIP_TYPES.Klingon_Bird_of_Prey,
	}
	# Returns the ship type, defaulting to something safe if faction isn't in dict
	return FACTION_SHIP.get(f, Utility.SHIP_TYPES.Cardenas_Class)
