class_name ProtectComponent
extends SystemComponent

## Escort: succeeds when the transport finishes its route, fails if it dies.
## Ambushes spawn at ProtectComponentData.ambush_thresholds.

const PROGRESS_CHECK_INTERVAL: float = 0.5
const AMBUSH_SPAWN_DISTANCE: float = 2500.0

var component_data: ProtectComponentData

var transport: MissionCharacter
var ambushers: Array[MissionCharacter] = []
var _progress_timer: float = 0.0


func initialize_system_component(data: SystemComponentData) -> void:
	component_data = data as ProtectComponentData

	if component_data.is_finished or component_data.protected_ships_data.is_empty():
		return

	_spawn_transport()
	SignalBus.missionCharacterDied.connect(_on_mission_ship_died)


func _spawn_transport() -> void:
	var ship_data: ShipState = component_data.protected_ships_data.front()
	transport = LevelManager.rootLevel.spawn_mission_ship(ship_data, MissionCharacter.Role.ESCORTED)
	transport.movement.route = component_data.route
	transport.movement.route_index = component_data.route_index
	transport.movement.waypoint_reached.connect(_on_waypoint_reached)
	transport.movement.route_finished.connect(_on_route_finished)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(transport) or component_data.is_finished:
		return
	_progress_timer -= delta
	if _progress_timer > 0.0:
		return
	_progress_timer = PROGRESS_CHECK_INTERVAL

	var thresholds: Array[float] = component_data.ambush_thresholds
	if component_data.ambushes_triggered < thresholds.size():
		var progress: float = component_data.get_progress(transport.global_position)
		if progress >= thresholds[component_data.ambushes_triggered]:
			_spawn_ambush()


func _spawn_ambush() -> void:
	component_data.ambushes_triggered += 1

	var ahead: Vector2 = Vector2.from_angle(transport.global_rotation)
	var origin: Vector2 = ShipMovementComponent.clamp_to_system(transport.global_position + ahead.rotated(randf_range(-0.5, 0.5)) * AMBUSH_SPAWN_DISTANCE)
	var ships: Array[ShipState] = SystemGenerator.generate_mission_ships(component_data.attacker_faction, component_data.difficulty, origin, component_data.ambush_size)

	for ship_data: ShipState in ships:
		var attacker: MissionCharacter = LevelManager.rootLevel.spawn_mission_ship(ship_data, MissionCharacter.Role.ATTACKER)
		attacker.objective_node = transport
		ambushers.append(attacker)

	SignalBus.component_injected.emit(component_data) # Refreshes minimap
	SignalBus.changePopMessage.emit("Ambush! %d hostiles closing on the transport" % ships.size())


func _on_waypoint_reached(index: int) -> void:
	component_data.route_index = index


func _on_route_finished() -> void:
	complete(component_data)


func _on_mission_ship_died(ship: MissionCharacter) -> void:
	if ship == transport:
		component_data.protected_ships_data.clear()
		fail(component_data, "Escorted transport destroyed - mission failed")
	else:
		ambushers.erase(ship)


func _exit_tree() -> void:
	if SignalBus.missionCharacterDied.is_connected(_on_mission_ship_died):
		SignalBus.missionCharacterDied.disconnect(_on_mission_ship_died)

	# Transport position persists; ambushers don't
	if is_instance_valid(transport) and not component_data.protected_ships_data.is_empty():
		component_data.protected_ships_data.front().save_position = transport.global_position

	var ships: Array[MissionCharacter] = ambushers.duplicate()
	ships.append(transport)
	for ship: MissionCharacter in ships:
		if is_instance_valid(ship):
			LevelManager.missionShips.erase(ship)
			ship.queue_free()
	ambushers.clear()
