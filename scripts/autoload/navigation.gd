extends Node

var galaxyMapData: Resource = preload("res://assets/data/galaxy_map_data.tres")

var in_galaxy_warp:bool = false
var currentSystem: String = "Solarus"
var targetSystem: String = "Solarus" # Currently selected system on galaxy map
var current_system_faction: Utility.FACTION = Utility.FACTION.FEDERATION

var systems: Array = []
var planet_names:Array[String] = load_planet_names()

var entry_coords: Vector2

const SYSTEM_RANGES = {
	"Federation": {"range": {"min": 1, "max": 16}},
	"Klingon": {"range": {"min": 17, "max": 24}},
	"Romulan": {"range": {"min": 25, "max": 31}},
}

var fed_min: int = SYSTEM_RANGES["Federation"]["range"]["min"]
var fed_max: int = SYSTEM_RANGES["Federation"]["range"]["max"]
var kling_min: int = SYSTEM_RANGES["Klingon"]["range"]["min"]
var kling_max: int = SYSTEM_RANGES["Klingon"]["range"]["max"]
var rom_min: int = SYSTEM_RANGES["Romulan"]["range"]["min"]


func _ready() -> void:
	SignalBus.TopLeft_clicked.connect(trigger_warp)
	SignalBus.entering_galaxy_warp.connect(set_current_system)
	SignalBus.levelReset.connect(load_planet_names)


func set_current_system(system:String = Navigation.targetSystem):
	currentSystem = system
	current_system_faction = get_faction_for_system(system)


func get_faction_for_system(system) -> int:
	match system:
		"Solarus":
			return Utility.FACTION.FEDERATION
		"Kronos":
			return Utility.FACTION.KLINGON
		"Romulus":
			return Utility.FACTION.ROMULAN
		"Neutral":
			return Utility.FACTION.NEUTRAL
		"Risa":
			return Utility.FACTION.NEUTRAL
		_:
			system = int(system)
			if system <= fed_max:
				return Utility.FACTION.FEDERATION
			elif system >= kling_min and system <= kling_max:
				return Utility.FACTION.KLINGON
			elif system >= rom_min:
				return Utility.FACTION.ROMULAN
	return -1 # Error status


func load_planet_names(file_path:String = "res://assets/data/planet_names.txt") -> Array[String]:
	planet_names.clear()
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


func get_entry_point(angle_rad: float) -> Vector2:
	var coords: Vector2 = Vector2.ZERO
	angle_rad = (angle_rad - PI/2) - PI # Flips angle 180 degrees (and accounts for player offset)
	var border_coords: int = 20000
	var square_min: Vector2 = Vector2.ZERO - Vector2(border_coords, border_coords)
	var square_max: Vector2 = Vector2.ZERO + Vector2(border_coords, border_coords)

	var best_intersection: Vector2 = Vector2.INF
	var best_t: float = INF

	var cos_angle: float = cos(angle_rad)
	var sin_angle: float = sin(angle_rad)

	# Check right side
	var t:float = (square_max.x - coords.x) / cos_angle if cos_angle != 0 else INF
	if t > 0:
		var y:float = coords.y + t * sin_angle
		if y >= square_min.y and y <= square_max.y and t < best_t:
			best_t = t
			best_intersection = Vector2(square_max.x, y)

	# Check left side
	t = (square_min.x - coords.x) / cos_angle if cos_angle != 0 else INF
	if t > 0:
		var y:float = coords.y + t * sin_angle
		if y >= square_min.y and y <= square_max.y and t < best_t:
			best_t = t
			best_intersection = Vector2(square_min.x, y)

	# Check top side
	t = (square_max.y - coords.y) / sin_angle if sin_angle != 0 else INF
	if t > 0:
		var x:float = coords.x + t * cos_angle
		if x >= square_min.x and x <= square_max.x and t < best_t:
			best_t = t
			best_intersection = Vector2(x, square_max.y)

	# Check bottom side
	t = (square_min.y - coords.y) / sin_angle if sin_angle != 0 else INF
	if t > 0:
		var x:float = coords.x + t * cos_angle
		if x >= square_min.x and x <= square_max.x and t < best_t:
			best_t = t
			best_intersection = Vector2(x, square_min.y)
	
	return best_intersection.move_toward(Vector2.ZERO, 2000)


func trigger_warp() -> void:
	if get_system_distance(currentSystem, targetSystem) > LevelData.player.warp_range:
		var error_message: String = "Max warp range of %s systems" % LevelData.player.warp_range
		SignalBus.changePopMessage.emit(error_message)
		return
	if !LevelData.player.velocity_check():
		var error_message: String = "Must be stationary and in impulse to warp"
		SignalBus.changePopMessage.emit(error_message)
		return
	else:
		SignalBus.triggerGalaxyWarp.emit(targetSystem)


func get_system_distance(origin: String, target: String) -> int:
	if origin == target:
		return 0

	var visited := {}
	var queue: Array = []
	queue.append({ "name": origin, "depth": 0 })
	visited[origin] = true

	while not queue.is_empty():
		var current: Dictionary = queue.pop_front()
		var current_name = current["name"]
		var depth: int = current["depth"]

		var current_system: SystemData = galaxyMapData.get_system(current_name)
		if current_system == null:
			continue

		for neighbor_name in current_system.neighbors:
			if neighbor_name == target:
				return depth + 1
			if not visited.has(neighbor_name):
				visited[neighbor_name] = true
				queue.append({ "name": neighbor_name, "depth": depth + 1 })
	
	push_error("No system path found between %s and %s" % ["origin", "target"])
	return -1  # Target not reachable


func get_reachable_systems(start_name: String, max_range: int) -> Array:
	var visited := {}
	var queue: Array = []
	var reachable: Array = []

	queue.append({ "name": start_name, "depth": 0 })
	visited[start_name] = true

	while not queue.is_empty():
		var current:Dictionary = queue.pop_front()
		var current_name = current["name"]
		var depth: int = current["depth"]

		if depth > 0:
			reachable.append(current_name)

		if depth >= max_range:
			continue

		var current_system:SystemData = galaxyMapData.get_system(current_name)
		if current_system == null:
			continue

		for neighbor_name in current_system.neighbors:
			if not visited.has(neighbor_name):
				visited[neighbor_name] = true
				queue.append({ "name": neighbor_name, "depth": depth + 1 })
	
	return reachable
