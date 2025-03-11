extends Node

var player
var currentSystem: String = "Solarus"
var current_system_faction: Utility.FACTION = 0

# Vars for galaxy map navigation
var leaveDataStored: bool = false # Check to see if player pos has already been check
var targetSystem: String = "" # Currently selected system on galaxy map
var playerEntryInfo: Dictionary


func get_square_line_intersection(coords: Vector2, angle_rad: float) -> Vector2:
	angle_rad = angle_rad - PI/2 # Player rotation offset
	var border_coords = 20000
	var square_min = Vector2.ZERO - Vector2(border_coords, border_coords)
	var square_max = Vector2.ZERO + Vector2(border_coords, border_coords)

	var best_intersection = Vector2.INF
	var best_t = INF

	var cos_angle = cos(angle_rad)
	var sin_angle = sin(angle_rad)

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

	return best_intersection
