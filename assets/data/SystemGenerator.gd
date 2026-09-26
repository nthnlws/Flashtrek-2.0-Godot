# SystemGenerator.gd
## Static procedural generation for SystemData/PlanetData/SunData. Kept
## separate from SystemData itself so the data Resource only holds and
## queries runtime state - it doesn't also know how to build a galaxy.
## Extracted from SystemData.gd, which previously mixed "the data for one
## system" with "the generator for all systems."
class_name SystemGenerator
extends RefCounted

const MAX_SPAWN_DISTANCE: int = 1500
const MIN_SPAWN_DISTANCE: int = 500


static func generate_system_data(sys_index: int, new_system_name: String) -> SystemData:
	var new_system_data: SystemData = SystemData.new()
	var sys_faction: Utility.FACTION = get_system_faction(sys_index)

	new_system_data.system_name = new_system_name
	new_system_data.system_index = sys_index
	new_system_data.faction = sys_faction
	new_system_data.system_difficulty_mult = Scaling.get_system_difficulty(sys_index, sys_faction)
	new_system_data.ensure_planet_names_loaded()

	# Planetary body setup
	var new_planet_count: int = randi_range(3, 6)
	new_system_data.sun_data = generate_sun_data(new_planet_count)
	var spawn_positions: Array = get_planet_spawn_positions(new_planet_count)
	for valid_position: Vector2 in spawn_positions:
		var planet_name: String = new_system_data.planet_names.pop_front()
		new_system_data.planet_data.append(generate_planet_data(valid_position, planet_name, sys_faction))

	# NPC Ship Data
	for planet: PlanetData in new_system_data.planet_data:
		# Generate Faction ship spawn data
		var faction_spawn_pos: Vector2 = _generate_faction_spawn_position(planet)
		var baseFactionInfo: BaseShipInfo = Utility.get_ship_stats(Utility.get_faction_ship_type(sys_faction))
		var scaled_faction_stats: ShipState = ShipState.get_NPC_scaled_stats(new_system_data.system_difficulty_mult, baseFactionInfo, ShipState.CATEGORY.FACTION)
		scaled_faction_stats.save_position = faction_spawn_pos
		new_system_data.enemy_list.append(scaled_faction_stats)

		# Generate Neutral ship spawn data
		var neutral_spawn_pos: Vector2 = _generate_neutral_spawn_position(planet)
		var baseNeutralInfo: BaseShipInfo = Utility.get_ship_stats(Utility.get_neutral_ship_type())
		var scaled_neutral_stats: ShipState = ShipState.get_NPC_scaled_stats(new_system_data.system_difficulty_mult, baseNeutralInfo, ShipState.CATEGORY.NEUTRAL)
		scaled_neutral_stats.save_position = neutral_spawn_pos
		new_system_data.neutral_list.append(scaled_neutral_stats)

	return new_system_data


static func _generate_neutral_spawn_position(host_planet: PlanetData) -> Vector2:
	# Set spawn distance between 20-80% from starbase to planet
	var random_fraction: float = clamp(randf(), 0.20, 0.80)
	var spawn_pos: Vector2 = Vector2.ZERO.lerp(host_planet.world_position, random_fraction)
	return spawn_pos


static func _generate_faction_spawn_position(host_planet: PlanetData) -> Vector2:
	var random_angle: float = randf_range(0, TAU)
	var spawn_distance: float = randf_range(MIN_SPAWN_DISTANCE, MAX_SPAWN_DISTANCE)
	var spawn_position: Vector2 = Vector2.from_angle(random_angle) * spawn_distance

	return host_planet.world_position + spawn_position


static func get_planet_spawn_positions(PLANET_COUNT: int) -> Array:
	#var min_dist_between: float = clamp(20000.0 / PLANET_COUNT, 6000.0, 20000.0)
	var max_dist_origin: float = 15000.0 + ((PLANET_COUNT - 3.0) * 750.0)
	var min_dist_origin: float = clamp(7500.0 + ((PLANET_COUNT - 3.0) * 750.0), 7500.0, 10000.0)

	var all_possible_points: PackedVector2Array = PoissonDiscSampling.generate_points_for_circle(
		Vector2.ZERO,
		max_dist_origin,
		min_dist_origin,
		30
	)

	# Filter the points to be within the spawn ring
	var valid_spawn_points: Array[Vector2]
	for point in all_possible_points:
		# Check if the point is outside the inner "no-spawn" zone
		if point.distance_to(Vector2.ZERO) >= min_dist_origin:
			valid_spawn_points.append(point)

	# Shuffle the list to get a random selection
	valid_spawn_points.shuffle()
	# Get number of spawn points needed
	var final_planet_positions = valid_spawn_points.slice(0, PLANET_COUNT)
	return final_planet_positions


static func generate_planet_data(valid_spawn: Vector2, planet_name: String, faction: Utility.FACTION) -> PlanetData:
	var new_planet_data: PlanetData = PlanetData.new()

	var random_frame: int = randi() % 220
	new_planet_data.name = planet_name
	new_planet_data.frame = random_frame
	new_planet_data.world_position = valid_spawn
	new_planet_data.faction = faction

	# --- ADDING COMPONENTS DURING GENERATION ---

	# Add communication component to every planet
	var comms_data: CommunicationComponentData = CommunicationComponentData.new()
	comms_data.owning_planet = new_planet_data
	new_planet_data.components.append(comms_data)

	# Example: Randomly add a static debris field to SOME planets
	#if randf() > 0.7:
		#var debris_data = DebrisComponentData.new()
		#new_planet_data.components.append(debris_data)

	return new_planet_data


static func generate_sun_data(PLANET_COUNT: int) -> SunData:
	# Generate random angle and radius for spawn position
	var max_spawn_distance: float = clamp(7500.0 + ((PLANET_COUNT - 3.0) * 750.0), 7500.0, 10000.0) - 2000
	var min_spawn_distance: float = 4000
	var random_angle: float = randf_range(0, TAU)
	var spawn_distance: float = randf_range(min_spawn_distance, max_spawn_distance)

	var spawn_position: Vector2 = Vector2.from_angle(random_angle) * spawn_distance
	var sprite_index: int = randi_range(0, 5)

	var new_sun_data: SunData = SunData.new()
	new_sun_data.frame = sprite_index
	new_sun_data.world_position = spawn_position

	return new_sun_data # SunData


static func get_system_faction(sys_index: int) -> Utility.FACTION:
	if sys_index <= GalaxyData.NUM_FED_SYSTEMS:
		return Utility.FACTION.FEDERATION
	elif sys_index <= GalaxyData.NUM_FED_SYSTEMS + GalaxyData.NUM_KLING_SYSTEMS:
		return Utility.FACTION.KLINGON
	elif sys_index <= GalaxyData.NUM_FED_SYSTEMS + GalaxyData.NUM_KLING_SYSTEMS + GalaxyData.NUM_ROM_SYSTEMS:
		return Utility.FACTION.ROMULAN
	else:
		match sys_index:
			GalaxyData.SPECIAL_SYSTEMS.Solarus:
				return Utility.FACTION.FEDERATION
			GalaxyData.SPECIAL_SYSTEMS.Kronos:
				return Utility.FACTION.KLINGON
			GalaxyData.SPECIAL_SYSTEMS.Romulus:
				return Utility.FACTION.ROMULAN
			GalaxyData.SPECIAL_SYSTEMS.Risa:
				return Utility.FACTION.NEUTRAL
			_: return Utility.FACTION.NEUTRAL # No matching value
