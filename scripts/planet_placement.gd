extends Node2D

@export var planet_scene = preload("res://scenes/planet.tscn")

@export var PLANET_COUNT = 10
var MIN_DISTANCE_FROM_ORIGIN = 7500
var MAX_DISTANCE_FROM_ORIGIN = 15000
var MIN_DISTANCE_BETWEEN_PLANETS: int

var planet_positions: Array = []


func _ready():
	MIN_DISTANCE_BETWEEN_PLANETS = clamp(20000 / PLANET_COUNT, 6000, 200006)
	# Increases spawning distance for higher spawn counts
	MAX_DISTANCE_FROM_ORIGIN = 15000 + ((PLANET_COUNT - 3) * 750)
	MIN_DISTANCE_FROM_ORIGIN = clamp(MIN_DISTANCE_FROM_ORIGIN + ((PLANET_COUNT - 3) * 750), 7500, 10000)
	
	for i in range(PLANET_COUNT):
		var position = get_valid_position()
		var name = "Planet" + str(i)
		place_planet(position, name)

func get_valid_position() -> Vector2:
	const max_attempts = 100
	var attempt = 0
	
	while attempt < max_attempts:
		attempt += 1
		# Generate a random angle and distance within the specified range
		var angle = randf_range(0, TAU) #TAU = 360 degrees
		var distance = randf_range(MIN_DISTANCE_FROM_ORIGIN, MAX_DISTANCE_FROM_ORIGIN)
		
		# Calculate the position using polar coordinates
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
	push_warning("Failed to find a valid position after max attempts")
	return Vector2(0, 0)  # Fallback value, can be adjusted

func place_planet(position: Vector2, name: String):
	var planet_instance = planet_scene.instantiate()
	add_child(planet_instance)
	planet_instance.position = position
