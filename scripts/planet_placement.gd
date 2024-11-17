extends Node2D

@export var planet_scene = preload("res://scenes/planet.tscn")

@export var PLANET_COUNT = 1
const MIN_DISTANCE_FROM_ORIGIN = 10000
const MAX_DISTANCE_FROM_ORIGIN = 15000
var MIN_DISTANCE_BETWEEN_PLANETS:int = 10000/PLANET_COUNT * 3 # Decreases distance between planets as count increases


var planet_positions: Array = []
var quadrants: Array = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]  # NW, NE, SW, SE


func _ready():
	for i in range(PLANET_COUNT):
		var quadrant_index = i % quadrants.size()  # Cycle through quadrants
		var quadrant_vector = quadrants[quadrant_index]
		var position = get_valid_position_in_quadrant(quadrant_vector)
		var name = "Planet" + str(i)
		place_planet(position, name)

func get_valid_position_in_quadrant(quadrant_vector: Vector2) -> Vector2:
	var max_attempts = 100
	var attempt = 0
	
	while attempt < max_attempts:
		attempt += 1
		# Generate a random distance within the specified range
		var distance = randf_range(MIN_DISTANCE_FROM_ORIGIN, MAX_DISTANCE_FROM_ORIGIN)
		
		# Calculate the position using polar coordinates, adjusted for the quadrant
		var angle_offset = randf_range(0.5 * PI, PI)  # Confine to half a circle (90 degrees)
		var angle = atan2(quadrant_vector.y, quadrant_vector.x) + angle_offset
		var position = Vector2(cos(angle), sin(angle)) * distance
		
		# Check if the position is far enough from other planets
		var valid_position = true
		for existing_position in planet_positions:
			if position.distance_to(existing_position) < MIN_DISTANCE_BETWEEN_PLANETS:
				valid_position = false
				break
		
		# If valid, return the position
		if valid_position:
			planet_positions.append(position)
			return position
	push_warning("Failed to find a valid position after max attempts in quadrant")
	return Vector2(0, 0)  # Fallback value, can be adjusted

func place_planet(position: Vector2, name: String):
	var planet_instance = planet_scene.instantiate()
	add_child(planet_instance)
	planet_instance.position = position
	planet_instance.name = name
