class_name DefenseComponent
extends SystemComponent

const FIRST_WAVE_DELAY: float = 6.0
const WAVE_BREAK: float = 8.0
const SPAWN_BORDER_MARGIN: float = 3000.0
const INTEGRITY_WARNINGS: Array[float] = [0.75, 0.5]

var component_data: DefenseComponentData

var starbase: Starbase
var hitbox: ObjectiveDamageReceiver
var attackers: Array[MissionCharacter] = []
var _wave_timer: float = FIRST_WAVE_DELAY
var _wave_active: bool = false


func initialize_system_component(data: SystemComponentData) -> void:
	component_data = data as DefenseComponentData
	if component_data.is_finished or LevelManager.starbases.is_empty():
		return

	starbase = LevelManager.starbases.front()
	var sprite_radius: float = starbase.sprite.get_rect().size.x * starbase.sprite.scale.x * 0.4
	hitbox = ObjectiveDamageReceiver.create(maxf(sprite_radius, 150.0), component_data.defended_faction)
	add_child(hitbox)
	hitbox.global_position = starbase.global_position
	hitbox.damaged.connect(_on_starbase_damaged)
	hitbox.add_to_group(MissionManager.MINIMAP_MARKER_GROUP)

	SignalBus.missionCharacterDied.connect(_on_mission_ship_died)
	SignalBus.changePopMessage.emit("Hostile fleet detected - defend the starbase (%d waves)" % component_data.total_waves)


func _physics_process(delta: float) -> void:
	if component_data == null or component_data.is_finished or not is_instance_valid(starbase):
		return
	if _wave_active:
		return
	_wave_timer -= delta
	if _wave_timer <= 0.0:
		_spawn_wave()


func _spawn_wave() -> void:
	_wave_active = true
	var limit: float = LevelManager.current_system_data.system_size - SPAWN_BORDER_MARGIN
	var origin: Vector2 = Vector2.from_angle(randf() * TAU) * limit
	var ships: Array[ShipState] = SystemGenerator.generate_mission_ships(component_data.attacker_faction, component_data.difficulty, origin, component_data.get_wave_size())
	for ship_data: ShipState in ships:
		var attacker: MissionCharacter = LevelManager.rootLevel.spawn_mission_ship(ship_data, MissionCharacter.Role.ATTACKER)
		attacker.objective_node = starbase
		attackers.append(attacker)

	SignalBus.component_injected.emit(component_data) # Refreshes minimap
	SignalBus.changePopMessage.emit("Wave %d/%d inbound - %d hostiles" % [component_data.waves_cleared + 1, component_data.total_waves, ships.size()])


func _on_mission_ship_died(ship: MissionCharacter) -> void:
	if not attackers.has(ship):
		return
	attackers.erase(ship)
	if not attackers.is_empty():
		return

	_wave_active = false
	component_data.waves_cleared += 1
	if component_data.waves_cleared >= component_data.total_waves:
		complete(component_data)
	else:
		_wave_timer = WAVE_BREAK
		SignalBus.changePopMessage.emit("Wave repelled - regroup, more hostiles incoming")
		MissionManager.report_progress(component_data.mission_id, component_data.total_waves - component_data.waves_cleared)


func _on_starbase_damaged(amount: float) -> void:
	if component_data.is_finished:
		return
	var previous: float = component_data.starbase_hp / component_data.starbase_max_hp
	component_data.starbase_hp = maxf(component_data.starbase_hp - amount, 0.0)
	var integrity: float = component_data.starbase_hp / component_data.starbase_max_hp

	if integrity <= component_data.fail_fraction:
		fail(component_data, "The starbase has been overrun - mission failed")
		return
	for warning: float in INTEGRITY_WARNINGS:
		if previous > warning and integrity <= warning:
			SignalBus.changePopMessage.emit("Starbase integrity at %d%%" % int(warning * 100.0))


func _exit_tree() -> void:
	if SignalBus.missionCharacterDied.is_connected(_on_mission_ship_died):
		SignalBus.missionCharacterDied.disconnect(_on_mission_ship_died)

	# The current wave restarts on return
	for ship: MissionCharacter in attackers:
		if is_instance_valid(ship):
			LevelManager.missionShips.erase(ship)
			ship.queue_free()
	attackers.clear()
