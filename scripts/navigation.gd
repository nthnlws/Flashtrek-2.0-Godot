extends Node

var currentSystem: String = "Solarus"
var current_system_faction: Utility.FACTION = Utility.FACTION.FEDERATION

var all_systems_data: Dictionary = {}
var systems: Array
var planet_names = load_planet_names("res://assets/data/planet_names.txt")

var entry_coords: Vector2

const SYSTEM_RANGES = {
	"Federation": {"range": {"min": 1, "max": 16}},
	"Klingon": {"range": {"min": 17, "max": 24}},
	"Romulan": {"range": {"min": 25, "max": 31}},
}

var fed_min = SYSTEM_RANGES["Federation"]["range"]["min"]
var fed_max = SYSTEM_RANGES["Federation"]["range"]["max"]
var kling_min = SYSTEM_RANGES["Klingon"]["range"]["min"]
var kling_max = SYSTEM_RANGES["Klingon"]["range"]["max"]
var rom_min = SYSTEM_RANGES["Romulan"]["range"]["min"]

# Vars for galaxy map navigation
var targetSystem: String = "" # Currently selected system on galaxy map


func set_current_system(system):
	print("setting system to " + system)
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
		_:
			system = int(system)
			if system <= fed_max:
				return Utility.FACTION.FEDERATION
			elif system >= kling_min and system <= kling_max:
				return Utility.FACTION.KLINGON
			elif system >= rom_min:
				return Utility.FACTION.ROMULAN
	return -1 # Error status
		
func load_planet_names(file_path: String) -> Array:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open planet names file at %s" % file_path)
		return []

	var names = []
	while not file.eof_reached():
		var line = file.get_line().strip_edges()
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
	var t = (square_max.x - coords.x) / cos_angle if cos_angle != 0 else INF
	if t > 0:
		var y = coords.y + t * sin_angle
		if y >= square_min.y and y <= square_max.y and t < best_t:
			best_t = t
			best_intersection = Vector2(square_max.x, y)

	# Check left side
	t = (square_min.x - coords.x) / cos_angle if cos_angle != 0 else INF
	if t > 0:
		var y = coords.y + t * sin_angle
		if y >= square_min.y and y <= square_max.y and t < best_t:
			best_t = t
			best_intersection = Vector2(square_min.x, y)

	# Check top side
	t = (square_max.y - coords.y) / sin_angle if sin_angle != 0 else INF
	if t > 0:
		var x = coords.x + t * cos_angle
		if x >= square_min.x and x <= square_max.x and t < best_t:
			best_t = t
			best_intersection = Vector2(x, square_max.y)

	# Check bottom side
	t = (square_min.y - coords.y) / sin_angle if sin_angle != 0 else INF
	if t > 0:
		var x = coords.x + t * cos_angle
		if x >= square_min.x and x <= square_max.x and t < best_t:
			best_t = t
			best_intersection = Vector2(x, square_min.y)
	
	return best_intersection.move_toward(Vector2.ZERO, 2000)
