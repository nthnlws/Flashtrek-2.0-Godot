class_name KillFactionComponent
extends SystemComponent

var component_data: KillFactionComponentData

# Maps the Physical Node to the Data Resource so we know what to delete
var spawned_ships: Dictionary[MissionCharacter, ShipState]


func initialize_system_component(data: SystemComponentData) -> void:
	component_data = data as KillFactionComponentData

	if component_data.is_finished:
		return

	_spawn_ships()
	SignalBus.missionCharacterDied.connect(_on_mission_ship_died)


func _spawn_ships() -> void:
	var root_level: Node = LevelManager.rootLevel

	for ship_data:ShipState in component_data.target_ships_data:
		var new_ship: MissionCharacter = root_level.spawn_mission_ship(ship_data)
		spawned_ships[new_ship] = ship_data


func _on_mission_ship_died(ship: MissionCharacter) -> void:
	if spawned_ships.has(ship):
		# Get dead ship data
		var destroyed_ship_data: ShipState = spawned_ships[ship]

		# Remove from tracking dictionary
		spawned_ships.erase(ship)
		component_data.target_ships_data.erase(destroyed_ship_data)

	## Checks if spawned_ships array is empty, and finishes the component if so
	if spawned_ships.is_empty():
		complete(component_data)


func _exit_tree() -> void:
	# Disconnect to prevent errors if ships blow up while the level is unloading
	if SignalBus.missionCharacterDied.is_connected(_on_mission_ship_died):
		SignalBus.missionCharacterDied.disconnect(_on_mission_ship_died)

	# Cleanup any remaining ships if the player leaves the system before killing them all
	for ship: MissionCharacter in spawned_ships.keys():
		if is_instance_valid(ship):
			ship.queue_free()

	spawned_ships.clear()
