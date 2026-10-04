# ComponentGenerator.gd
## Single place where every component's data is built. Data classes only hold
## state; all construction and spawn-chance logic lives here.
##
## Adding a component:
##   1. Write its build_* function below (any arguments it needs).
##   2. Add one adapter line to _get_builders() so id-based callers
##      (MissionManager, debug tools) can create it.
##   3. If it spawns ambiently, write a roll_* function and call it from
##      SystemGenerator.
class_name ComponentGenerator
extends RefCounted

# --- Scrap fields ---
const SCRAP_PILES: ResourceGroup = preload("res://assets/data/all_scrap_piles.tres")
const SCRAP_FIELD_RADIUS: float = 1500.0
const SCRAP_FIELD_CHANCE: float = 1.0 / 3.0
const SCRAP_FIELDS_PER_SYSTEM: int = 4
const SCRAP_MIN_RADIUS: float = 3000.0
const SCRAP_MAX_RADIUS_FRACTION: float = 0.8 # of system_size
const SCRAP_CLEARANCE_PLANET: float = 4000.0
const SCRAP_CLEARANCE_SUN: float = 3500.0
const SCRAP_CLEARANCE_STARBASE: float = 3000.0 # Starbase always spawns at the origin
const SCRAP_CLEARANCE_FIELD: float = 3500.0
const SCRAP_PLACEMENT_ATTEMPTS: int = 50

# --- Sensor sweep ---
const SWEEP_MIN_POINT_SPACING: float = 4000.0
const SWEEP_BASE_TIME: float = 60.0
const SWEEP_TIME_PER_POINT: float = 30.0

static var _builders: Dictionary[StringName, Callable] = {}


## Id-based entry point. `ctx` is a plain Dictionary that may hold
## "mission" (MissionData), "system" (SystemData) and "planet" (PlanetData).
## Each adapter checks for the keys it needs and fails loudly without them.
static func build(component_id: StringName, ctx: Dictionary) -> BaseComponentData:
	var builders: Dictionary[StringName, Callable] = _get_builders()
	if not builders.has(component_id):
		push_error("ComponentGenerator: no builder registered for '%s'" % component_id)
		return null
	return builders[component_id].call(ctx)


## One line per component: unpack the context and call its build function.
static func _get_builders() -> Dictionary[StringName, Callable]:
	if not _builders.is_empty():
		return _builders
	_builders = {
		# System-scoped
		&"bounty": func(ctx: Dictionary) -> BaseComponentData: return build_bounty(ctx.mission, ctx.system) if _requires(ctx, &"bounty", ["mission", "system"]) else null,
		&"container": func(ctx: Dictionary) -> BaseComponentData: return build_container(ctx.mission) if _requires(ctx, &"container", ["mission"]) else null,
		&"defense": func(ctx: Dictionary) -> BaseComponentData: return build_defense(ctx.mission, ctx.system) if _requires(ctx, &"defense", ["mission", "system"]) else null,
		&"kill_faction": func(ctx: Dictionary) -> BaseComponentData: return build_kill_faction(ctx.mission, ctx.system) if _requires(ctx, &"kill_faction", ["mission", "system"]) else null,
		&"protect_ship": func(ctx: Dictionary) -> BaseComponentData: return build_protect_ship(ctx.mission, ctx.system) if _requires(ctx, &"protect_ship", ["mission", "system"]) else null,
		&"rescue": func(ctx: Dictionary) -> BaseComponentData: return build_rescue(ctx.mission, ctx.system) if _requires(ctx, &"rescue", ["mission", "system"]) else null,
		&"salvage": func(ctx: Dictionary) -> BaseComponentData: return build_salvage(ctx.system) if _requires(ctx, &"salvage", ["system"]) else null,
		&"scrap": func(ctx: Dictionary) -> BaseComponentData: return build_scrap_field(ctx.system) if _requires(ctx, &"scrap", ["system"]) else null,
		&"sensor_sweep": func(ctx: Dictionary) -> BaseComponentData: return build_sensor_sweep(ctx.system) if _requires(ctx, &"sensor_sweep", ["system"]) else null,
		# Planet-scoped
		&"analyze": func(ctx: Dictionary) -> BaseComponentData: return build_analyze(ctx.planet) if _requires(ctx, &"analyze", ["planet"]) else null,
		&"communication": func(ctx: Dictionary) -> BaseComponentData: return build_communication(ctx.planet) if _requires(ctx, &"communication", ["planet"]) else null,
	}
	return _builders


## Loud failure when an id-based caller didn't supply what a builder needs.
static func _requires(ctx: Dictionary, component_id: StringName, keys: Array[String]) -> bool:
	for key: String in keys:
		if ctx.get(key) == null:
			push_error("ComponentGenerator: '%s' requires a non-null ctx.%s" % [component_id, key])
			return false
	return true


#region System components

static func build_bounty(mission: MissionData, system: SystemData) -> BountyComponentData:
	var data: BountyComponentData = BountyComponentData.new()
	data.faction = mission.enemy_faction
	data.bounty_name = mission.bounty_name
	var base_info: BaseShipInfo = Utility.get_ship_stats(Utility.get_faction_ship_type(data.faction))
	data.target = ShipState.get_NPC_scaled_stats(system.system_difficulty_mult * BountyComponentData.ELITE_DIFFICULTY_MULT, base_info, ShipState.CATEGORY.FACTION)
	data.target.ship_name = data.bounty_name
	data.relocate(system) # Places the target at a random point in `system`
	return data


#TODO: Make faction input variable array to allow for containers of
# multiple factions to spawn in same component
static func build_container(mission: MissionData) -> ContainerComponentData:
	var data: ContainerComponentData = ContainerComponentData.new()
	for i: int in range(randi_range(2, 4)): # Number of containers to spawn
		var pos: Vector2 = Utility.get_random_point_on_circle(randf_range(2000, 6000))
		data.remaining_pickups.append(ContainerData.create_container_data(mission.cargo, mission.faction_owner, UUID.generate_UUID(), pos))
	return data


static func build_defense(mission: MissionData, system: SystemData) -> DefenseComponentData:
	var data: DefenseComponentData = DefenseComponentData.new()
	data.defended_faction = system.faction
	data.attacker_faction = mission.enemy_faction
	if data.attacker_faction == data.defended_faction:
		data.attacker_faction = Utility.get_enemy_faction(data.defended_faction)
	data.difficulty = system.system_difficulty_mult
	data.total_waves = randi_range(3, 4)
	data.starbase_hp = data.starbase_max_hp
	return data


static func build_kill_faction(mission: MissionData, system: SystemData) -> KillFactionComponentData:
	var data: KillFactionComponentData = KillFactionComponentData.new()
	data.faction = mission.enemy_faction

	var num_to_kill: int = mission.enemy_target_count
	if num_to_kill <= 0:
		num_to_kill = randi_range(1, 4)

	var ship_info: BaseShipInfo = Utility.get_ship_stats(Utility.get_faction_ship_type(data.faction))
	var spawn_origin: Vector2 = Utility.get_random_point_on_circle(randi_range(5000, 15000))
	for i: int in range(num_to_kill):
		var ship: ShipState = ShipState.get_NPC_scaled_stats(system.system_difficulty_mult, ship_info, ShipState.CATEGORY.FACTION)
		ship.save_position = spawn_origin + Utility.get_random_point_on_circle(250)
		data.target_ships_data.append(ship)
	return data


static func build_protect_ship(mission: MissionData, system: SystemData) -> ProtectComponentData:
	var data: ProtectComponentData = ProtectComponentData.new()
	data.faction = mission.faction_owner
	data.attacker_faction = mission.enemy_faction
	if data.attacker_faction == data.faction:
		data.attacker_faction = Utility.get_enemy_faction(data.faction)
	data.difficulty = system.system_difficulty_mult
	data.ambush_size = randi_range(2, 3)

	data.start_position = _protect_entry_point(system.system_size)
	data.route = _protect_route(system, data.start_position)

	var ship_type: Utility.SHIP_TYPES = Utility.get_neutral_ship_type() if data.faction == Utility.FACTION.NEUTRAL else Utility.get_faction_ship_type(data.faction)
	var transport: ShipState = ShipState.get_NPC_scaled_stats(data.difficulty, Utility.get_ship_stats(ship_type), ShipState.CATEGORY.FACTION)
	transport.save_position = data.start_position
	data.protected_ships_data.append(transport)
	return data


## One of the four corners, inset from the system edge.
static func _protect_entry_point(system_size: float) -> Vector2:
	var offset: int = 5000
	var spawn_options: Array[Vector2] = [
		Vector2(system_size - offset, system_size - offset),
		Vector2(-system_size + offset, -system_size + offset),
		Vector2(-system_size + offset, system_size - offset),
		Vector2(system_size - offset, -system_size + offset),
	]
	return spawn_options.pick_random()


## 2-3 planets, nearest-first from the entry point, then the starbase.
static func _protect_route(system: SystemData, start_position: Vector2) -> Array[Vector2]:
	var remaining: Array[Vector2] = []
	for planet: PlanetData in system.planet_data:
		remaining.append(planet.world_position)
	remaining.shuffle()
	remaining.resize(mini(remaining.size(), randi_range(2, 3)))

	var ordered: Array[Vector2] = []
	var cursor: Vector2 = start_position
	while not remaining.is_empty():
		var nearest_index: int = 0
		for i: int in range(1, remaining.size()):
			if cursor.distance_to(remaining[i]) < cursor.distance_to(remaining[nearest_index]):
				nearest_index = i
		cursor = remaining.pop_at(nearest_index)
		ordered.append(cursor)

	ordered.append(Vector2.ZERO) # Starbase
	return ordered


static func build_rescue(mission: MissionData, system: SystemData) -> RescueComponentData:
	var data: RescueComponentData = RescueComponentData.new()
	data.attacker_faction = mission.enemy_faction
	data.difficulty = system.system_difficulty_mult
	data.wave_size = randi_range(2, 3)

	var faction: Utility.FACTION = mission.faction_owner
	var ship_type: Utility.SHIP_TYPES = Utility.get_neutral_ship_type() if faction == Utility.FACTION.NEUTRAL else Utility.get_faction_ship_type(faction)
	data.disabled_ship = ShipState.get_NPC_scaled_stats(data.difficulty, Utility.get_ship_stats(ship_type), ShipState.CATEGORY.FACTION)

	var hazard_center: Vector2 = system.sun_data.world_position if system.sun_data else Vector2.ZERO
	data.disabled_ship.save_position = hazard_center + Utility.get_random_point_on_circle(2500.0)
	return data


static func build_salvage(system: SystemData) -> SalvageComponentData:
	var data: SalvageComponentData = SalvageComponentData.new()
	data.field_center = Utility.get_random_point_on_circle(randf_range(6000.0, system.system_size * 0.6))
	_fill_scrap_piles(data.component_scrap_piles, data.pile_positions)

	for pile_index: int in range(data.component_scrap_piles.size()):
		var piece_indices: Array = range(data.component_scrap_piles[pile_index].positions.size())
		piece_indices.shuffle()
		for piece_index: int in piece_indices.slice(0, randi_range(1, 2)):
			data.remaining_salvage.append(Vector2i(pile_index, piece_index))
	data.total_salvage = data.remaining_salvage.size()
	return data


## `center` defaults to a free spot found with _find_scrap_center(). Returns
## null if no valid spot exists.
static func build_scrap_field(system: SystemData, center: Vector2 = Vector2.INF) -> ScrapComponentData:
	if not center.is_finite():
		center = _find_scrap_center(system, _existing_scrap_centers(system))
	if not center.is_finite():
		push_warning("ComponentGenerator: no free spot for a scrap field in %s" % system.system_name)
		return null

	var data: ScrapComponentData = ScrapComponentData.new()
	data.field_center = center
	_fill_scrap_piles(data.component_scrap_piles, data.pile_positions)
	return data


static func build_sensor_sweep(system: SystemData) -> SensorSweepComponentData:
	var data: SensorSweepComponentData = SensorSweepComponentData.new()
	var count: int = randi_range(3, 5)
	var attempts: int = 0
	while data.scan_points.size() < count and attempts < 200:
		attempts += 1
		var candidate: Vector2 = Utility.get_random_point_on_circle(randf_range(4000.0, system.system_size * 0.7))
		if data.scan_points.all(func(point: Vector2) -> bool: return point.distance_to(candidate) >= SWEEP_MIN_POINT_SPACING):
			data.scan_points.append(candidate)

	data.total_points = data.scan_points.size()
	data.time_remaining = SWEEP_BASE_TIME + SWEEP_TIME_PER_POINT * data.total_points
	return data


## Shared by scrap and salvage: 3-6 random piles with positions relative to
## the field center.
static func _fill_scrap_piles(piles: Array[ScrapPileConfig], positions: Array[Vector2]) -> void:
	var all_piles: Array[ScrapPileConfig] = []
	SCRAP_PILES.load_all_into(all_piles)
	for i: int in range(randi_range(3, 6)):
		piles.append(all_piles.pick_random())
		positions.append(Utility.get_random_point_on_circle(randf_range(0.0, SCRAP_FIELD_RADIUS)))

#endregion


#region Planet components

static func build_analyze(planet: PlanetData) -> AnalyzeComponentData:
	var data: AnalyzeComponentData = AnalyzeComponentData.new()
	data.owning_planet = planet
	data.mission_point = Utility.get_random_point_on_circle(1500)
	return data


static func build_communication(planet: PlanetData) -> CommunicationComponentData:
	var data: CommunicationComponentData = CommunicationComponentData.new()
	data.owning_planet = planet
	return data

#endregion


#region Ambient rolls (called during system generation)

## 1/3 chance of scrap; if it hits, SCRAP_FIELDS_PER_SYSTEM fields (fewer if
## the system is too crowded). Returns an empty array when the roll fails.
static func roll_scrap_fields(system: SystemData) -> Array[ScrapComponentData]:
	var fields: Array[ScrapComponentData] = []
	if randf() >= SCRAP_FIELD_CHANCE:
		return fields

	var taken: Array[Vector2] = _existing_scrap_centers(system)
	for i: int in range(SCRAP_FIELDS_PER_SYSTEM):
		var center: Vector2 = _find_scrap_center(system, taken)
		if not center.is_finite():
			break # System too crowded - keep whatever fit
		taken.append(center)
		fields.append(build_scrap_field(system, center))
	return fields


## Random point clear of planets, sun, starbase and `taken` field centers.
## Returns Vector2.INF after SCRAP_PLACEMENT_ATTEMPTS failures.
static func _find_scrap_center(system: SystemData, taken: Array[Vector2]) -> Vector2:
	var max_radius: float = system.system_size * SCRAP_MAX_RADIUS_FRACTION
	for attempt: int in range(SCRAP_PLACEMENT_ATTEMPTS):
		var candidate: Vector2 = Utility.get_random_point_on_circle(randf_range(SCRAP_MIN_RADIUS, max_radius))
		if _is_scrap_spot_clear(system, candidate, taken):
			return candidate
	return Vector2.INF


static func _is_scrap_spot_clear(system: SystemData, point: Vector2, taken: Array[Vector2]) -> bool:
	if point.distance_to(Vector2.ZERO) < SCRAP_CLEARANCE_STARBASE:
		return false
	if system.sun_data and point.distance_to(system.sun_data.world_position) < SCRAP_CLEARANCE_SUN:
		return false
	for planet: PlanetData in system.planet_data:
		if point.distance_to(planet.world_position) < SCRAP_CLEARANCE_PLANET:
			return false
	for center: Vector2 in taken:
		if point.distance_to(center) < SCRAP_CLEARANCE_FIELD:
			return false
	return true


## Centers of scrap and salvage fields already stored on `system`.
static func _existing_scrap_centers(system: SystemData) -> Array[Vector2]:
	var centers: Array[Vector2] = []
	for data: BaseComponentData in system.components:
		if data is ScrapComponentData:
			centers.append((data as ScrapComponentData).field_center)
		elif data is SalvageComponentData:
			centers.append((data as SalvageComponentData).field_center)
	return centers

#endregion
