class_name ProtectComponent
extends BaseComponent

var component_data: ProtectComponentData

# Dictionary to map the Physical Node back to its Resource Data
var spawned_ships: Dictionary[MissionCharacter, ShipState]


func initialize(data: BaseComponentData) -> void:
	component_data = data as ProtectComponentData
	
	if component_data.is_finished or component_data.is_failed:
		return
		
	_spawn_ships()
	SignalBus.missionCharacterDied.connect(_on_mission_ship_died)


func _spawn_ships() -> void:
	var root_level: Node = LevelManager.rootLevel
	
	for ship_data: ShipState in component_data.protected_ships_data:
		var new_ship: MissionCharacter = root_level.spawn_mission_ship(ship_data)
		
		# Link the physical instance to the data instance
		spawned_ships[new_ship] = ship_data


func _on_mission_ship_died(ship: MissionCharacter) -> void:
	if spawned_ships.has(ship):
		# Get data for destroyed ship
		var destroyed_ship_data: ShipState = spawned_ships[ship]
		spawned_ships.erase(ship)
		
		# Update ProtectComponentData
		component_data.report_ship_destroyed(destroyed_ship_data)


## Handles cleanup of physical ships when the player leaves the system 
## (or when the manager destroys this component upon failure).
func _exit_tree() -> void:
	SignalBus.missionCharacterDied.disconnect(_on_mission_ship_died)
	
	for ship: MissionCharacter in spawned_ships.keys():
		if is_instance_valid(ship):
			ship.queue_free()
			
	spawned_ships.clear()
