# SystemData.gd
extends Resource
class_name SystemData

var planet_names: Array[String]
const planet_name_file: String = "res://assets/data/planet_names.txt"

# System info
@export var system_name: String
@export var faction: Utility.FACTION = Utility.FACTION.NEUTRAL
@export var system_index: int = 0
@export var system_size: int = 20000

# System contents
@export var planet_data: Array[PlanetData]
@export var sun_data: SunData
@export var enemy_list: Array[FactionShipData]
@export var mission_ship_list: Array[MissionShipData] = []
@export var defeated_enemies: Array[FactionShipData] = []
@export var neutral_list: Array[NeutralShipData]
@export var defeated_neutrals: Array[NeutralShipData] = []
@export var mission_containers: Array[ContainerData] = []

# System logic
@export var enemies_defeated: bool = false
@export var neutrals_defeated: bool = false
@export var system_difficulty_mult: float = 1.0

# Galaxy map info
@export var global_map_position: Vector2
@export var neighbor_ids: Array[int] = []
var warp_neighbors: Array[SystemData]

# Components
enum SystemComponentType { KILL_FACTION, ESCORT, CONTAINER, }
@export var component_map: Dictionary[SystemComponentType, PackedScene] = {
	SystemComponentType.KILL_FACTION: preload("uid://dd0uqe0hng5gy"),
	#SystemComponentType.ESCORT: preload("res://scenes/components/planet_communication_component.tscn"),
	SystemComponentType.CONTAINER: preload("uid://cgljy0cnyeb7f")
}
@export var active_components: Dictionary[SystemComponentType, MissionData]

func add_component(component_type: SystemComponentType, mission_data: MissionData = MissionData.new()) -> void:
	#print("added component: %s to system: %s" % [SystemComponentType.keys()[component_type], system_name])
	if component_type in active_components:
		# Component already added to data
		return
	
	active_components.set(component_type, mission_data)

func get_components() -> Dictionary[SystemComponentType, MissionData]:
	return active_components

func get_containers() -> Array[ContainerData]:
	return mission_containers

func add_container(container_data:ContainerData) -> void:
	mission_containers.append(container_data)

func remove_container(to_remove: ContainerData) -> void:
	if mission_containers.has(to_remove):
		mission_containers.erase(to_remove)
	else: printerr("ContainerData does not exist in SystemData, cannot remove")


func _init() -> void:
	_reload_text_file()


func _reload_text_file() -> void:
	planet_names.clear()
	planet_names = load_text_file(planet_name_file)
	planet_names.shuffle()


func get_planet_data(planet_name: String) -> PlanetData:
	for planet: PlanetData in planet_data:
		if planet.name == planet_name:
			return planet
	
	return null # If PlanetData not found


static func generate_system_data(sys_index: int, new_system_name: String) -> SystemData:
	var new_system_data: SystemData = SystemData.new()
	var sys_faction = get_system_faction(sys_index)
	
	new_system_data.system_name = new_system_name
	new_system_data.system_index = sys_index
	new_system_data.faction = sys_faction
	new_system_data.system_difficulty_mult = Scaling.get_system_difficulty(sys_index, sys_faction)
	
	# Planetary body setup
	var new_planet_count: int = randi_range(3, 6)
	new_system_data.sun_data = generate_sun_data(new_planet_count)
	var spawn_positions: Array = get_planet_spawn_positions(new_planet_count)
	for valid_position: Vector2 in spawn_positions:
		var planet_name: String = new_system_data.planet_names.pop_front()
		new_system_data.planet_data.append(generate_planet_data(valid_position, planet_name, sys_faction))

	# NPC Ship Data
	var index: int = 0
	for planet: PlanetData in new_system_data.planet_data:
		var new_enemy: FactionShipData = FactionShipData.generate_enemy_ship_data(_generate_faction_spawn_position(planet), new_system_data.faction, new_system_data.system_difficulty_mult, index)
		new_system_data.enemy_list.append(new_enemy)
		var new_neutral: NeutralShipData = NeutralShipData.generate_neutral_ship_data(_generate_neutral_spawn_position(planet), new_system_data.faction, new_system_data.system_difficulty_mult, index)
		new_system_data.neutral_list.append(new_neutral)
		index += 1
	
	return new_system_data


static func _generate_neutral_spawn_position(host_planet: PlanetData) -> Vector2:
	# Set spawn distance between 20-80% from starbase to planet
	var random_fraction: float = clamp(randf(), 0.20, 0.80)
	var spawn_pos: Vector2 = Vector2.ZERO.lerp(host_planet.world_position, random_fraction)
	
	return spawn_pos


static func _generate_faction_spawn_position(host_planet: PlanetData) -> Vector2:
	var max_spawn_distance: int = 1500
	var min_spawn_distance: int = 500
	var random_angle: float = randf_range(0, TAU)
	var spawn_distance: float = randf_range(min_spawn_distance, max_spawn_distance)
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
	
	var random_frame: int = randi() % 220 # 220 = sprite sheet size
	new_planet_data.name = planet_name
	
	new_planet_data.name = planet_name
	new_planet_data.frame = random_frame
	new_planet_data.world_position = valid_spawn
	new_planet_data.faction = faction
	new_planet_data.add_component(PlanetData.PlanetComponentType.COMMUNICATION)
	
	return new_planet_data # PlanetData


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


func load_text_file(file_path: String) -> Array[String]:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open planet names file at %s" % file_path)
		return []

	var names: Array[String] = []
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line != "":
			names.append(line)
	file.close()
	return names


func remove_faction_ship_data(ship_index: int) -> void:
	var to_remove: FactionShipData
	for ship: FactionShipData in enemy_list:
		if ship.ship_index == ship_index:
			to_remove = ship
	enemy_list.erase(to_remove)
	defeated_enemies.append(to_remove)


func remove_neutral_ship_data(ship_index: int) -> void:
	var to_remove: NeutralShipData
	for ship: NeutralShipData in neutral_list:
		if ship.ship_index == ship_index:
			to_remove = ship
	neutral_list.erase(to_remove)
	defeated_neutrals.append(to_remove)


static func get_entry_point(angle_rad: float) -> Vector2:
	var coords: Vector2 = Vector2.ZERO
	angle_rad = (angle_rad) - PI # Flips angle 180 degrees
	var border_coords: int = 20000
	var square_min: Vector2 = Vector2.ZERO - Vector2(border_coords, border_coords)
	var square_max: Vector2 = Vector2.ZERO + Vector2(border_coords, border_coords)

	var best_intersection: Vector2 = Vector2.INF
	var best_t: float = INF

	var cos_angle: float = cos(angle_rad)
	var sin_angle: float = sin(angle_rad)

	# Check right side
	var t: float = (square_max.x - coords.x) / cos_angle if cos_angle != 0 else INF
	if t > 0:
		var y: float = coords.y + t * sin_angle
		if y >= square_min.y and y <= square_max.y and t < best_t:
			best_t = t
			best_intersection = Vector2(square_max.x, y)

	# Check left side
	t = (square_min.x - coords.x) / cos_angle if cos_angle != 0 else INF
	if t > 0:
		var y: float = coords.y + t * sin_angle
		if y >= square_min.y and y <= square_max.y and t < best_t:
			best_t = t
			best_intersection = Vector2(square_min.x, y)

	# Check top side
	t = (square_max.y - coords.y) / sin_angle if sin_angle != 0 else INF
	if t > 0:
		var x: float = coords.x + t * cos_angle
		if x >= square_min.x and x <= square_max.x and t < best_t:
			best_t = t
			best_intersection = Vector2(x, square_max.y)

	# Check bottom side
	t = (square_min.y - coords.y) / sin_angle if sin_angle != 0 else INF
	if t > 0:
		var x: float = coords.x + t * cos_angle
		if x >= square_min.x and x <= square_max.x and t < best_t:
			best_t = t
			best_intersection = Vector2(x, square_min.y)
	
	return best_intersection.move_toward(Vector2.ZERO, 2000)
