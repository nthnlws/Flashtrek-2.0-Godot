class_name RescueComponent
extends SystemComponent

const DELIVERY_RADIUS: float = 1500.0
const WAVE_SPAWN_DISTANCE: float = 3000.0

var component_data: RescueComponentData

var disabled_ship: MissionCharacter
var attackers: Array[MissionCharacter] = []


func initialize_system_component(data: SystemComponentData) -> void:
	component_data = data as RescueComponentData
	if component_data.is_finished:
		return

	disabled_ship = LevelManager.rootLevel.spawn_mission_ship(component_data.disabled_ship, MissionCharacter.Role.DISABLED)
	SignalBus.missionCharacterDied.connect(_on_mission_ship_died)
	SignalBus.changePopMessage.emit("Distress beacon located - hold your tractor beam on the ship to tow it to the starbase")
	MissionManager.report_progress(component_data.mission_id)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(disabled_ship) or component_data.is_finished:
		return

	if _is_delivered():
		complete(component_data)
		return

	if component_data.waves_spawned >= component_data.max_waves:
		return
	component_data.time_to_next_wave -= delta
	if component_data.time_to_next_wave <= 0.0:
		component_data.time_to_next_wave = RescueComponentData.WAVE_INTERVAL
		_spawn_wave()


func _is_delivered() -> bool:
	if LevelManager.starbases.is_empty():
		return false
	return disabled_ship.global_position.distance_to(LevelManager.starbases.front().global_position) < DELIVERY_RADIUS


func _spawn_wave() -> void:
	component_data.waves_spawned += 1
	var origin: Vector2 = ShipMovementComponent.clamp_to_system(disabled_ship.global_position + Utility.get_random_point_on_circle(WAVE_SPAWN_DISTANCE))
	var ships: Array[ShipState] = SystemGenerator.generate_mission_ships(component_data.attacker_faction, component_data.difficulty, origin, component_data.wave_size)
	for ship_data: ShipState in ships:
		var attacker: MissionCharacter = LevelManager.rootLevel.spawn_mission_ship(ship_data, MissionCharacter.Role.ATTACKER)
		attacker.objective_node = disabled_ship
		attackers.append(attacker)

	SignalBus.component_injected.emit(component_data) # Refreshes minimap
	SignalBus.changePopMessage.emit("Raiders inbound on the disabled ship (wave %d/%d)" % [component_data.waves_spawned, component_data.max_waves])


func _on_mission_ship_died(ship: MissionCharacter) -> void:
	if ship == disabled_ship:
		fail(component_data, "The disabled ship was destroyed - mission failed")
	else:
		attackers.erase(ship)


func _exit_tree() -> void:
	if SignalBus.missionCharacterDied.is_connected(_on_mission_ship_died):
		SignalBus.missionCharacterDied.disconnect(_on_mission_ship_died)

	if is_instance_valid(disabled_ship):
		component_data.disabled_ship.save_position = disabled_ship.global_position

	var ships: Array[MissionCharacter] = attackers.duplicate()
	ships.append(disabled_ship)
	for ship: MissionCharacter in ships:
		if is_instance_valid(ship):
			LevelManager.missionShips.erase(ship)
			ship.queue_free()
	attackers.clear()
