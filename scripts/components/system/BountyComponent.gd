class_name BountyComponent
extends SystemComponent

var component_data: BountyComponentData
var bounty_ship: MissionCharacter


func initialize_system_component(data: SystemComponentData) -> void:
	component_data = data as BountyComponentData
	if component_data.is_finished:
		return

	bounty_ship = LevelManager.rootLevel.spawn_mission_ship(component_data.target, MissionCharacter.Role.HUNTER)
	SignalBus.missionCharacterDied.connect(_on_mission_ship_died)
	SignalBus.changePopMessage.emit("Sensors have a lock on %s's warp signature" % component_data.bounty_name)


func _on_mission_ship_died(ship: MissionCharacter) -> void:
	if ship == bounty_ship:
		complete(component_data)


func _exit_tree() -> void:
	if SignalBus.missionCharacterDied.is_connected(_on_mission_ship_died):
		SignalBus.missionCharacterDied.disconnect(_on_mission_ship_died)

	if is_instance_valid(bounty_ship):
		component_data.target.save_position = bounty_ship.global_position
		LevelManager.missionShips.erase(bounty_ship)
		bounty_ship.queue_free()
