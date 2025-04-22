extends Area2D


@export var MIN_DISTANCE_FROM_ORIGIN = 1000
@export var MAX_DISTANCE_FROM_ORIGIN = 1500

func _init() -> void:
	Utility.mainScene.spawn_options.append(self)
	
	
func _ready():
	global_position = get_random_position()

func get_random_position() -> Vector2:
	# Generate a random angle and distance within the specified range
	var angle = randf_range(0, TAU)  # TAU = 2 * PI, a full circle
	var distance = randf_range(MIN_DISTANCE_FROM_ORIGIN, MAX_DISTANCE_FROM_ORIGIN)
	
	# Calculate the position using polar coordinates
	return Vector2(cos(angle), sin(angle)) * distance
