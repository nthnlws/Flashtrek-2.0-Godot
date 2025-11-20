extends Node

var galaxyMapData: Resource = preload("res://assets/data/galaxy_map_data.tres")

var in_galaxy_warp:bool = false
var currentSystem: SystemData
var targetSystem: SystemData # Currently selected system on galaxy map
var current_system_faction: Utility.FACTION = Utility.FACTION.FEDERATION

var entry_coords: Vector2

const SYSTEM_RANGES:Dictionary = {
	"Federation": {"range": {"min": 1, "max": 16}},
	"Klingon": {"range": {"min": 17, "max": 24}},
	"Romulan": {"range": {"min": 25, "max": 31}},
}

var fed_min: int = SYSTEM_RANGES["Federation"]["range"]["min"]
var fed_max: int = SYSTEM_RANGES["Federation"]["range"]["max"]
var kling_min: int = SYSTEM_RANGES["Klingon"]["range"]["min"]
var kling_max: int = SYSTEM_RANGES["Klingon"]["range"]["max"]
var rom_min: int = SYSTEM_RANGES["Romulan"]["range"]["min"]


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
