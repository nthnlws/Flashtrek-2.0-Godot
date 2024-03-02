extends Node2D

const GRID_HEIGHT = 5
const GRID_WIDTH = 6
const ASTEROID_COUNT = GRID_HEIGHT * GRID_WIDTH

var asteroids = []
var asteroid_pos = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	for i in ASTEROID_COUNT:
		asteroids.append(create_asteroid(i))


func asteroid_position(index):
	return Vector2(
		(index % GRID_WIDTH + 2) * (Asteroid.RADIUS_LIMIT * 2),
		(index / GRID_HEIGHT + 1) * (Asteroid.RADIUS_LIMIT * 2)
	)


func create_asteroid(index):
	var asteroid = Asteroid.new()
	asteroid.set_position(asteroid_position(index))
	add_child(asteroid)

	return asteroid


func _on_spawn_asteroid_timeout():
	asteroids[asteroid_pos].queue_free()
	asteroids[asteroid_pos] = create_asteroid(asteroid_pos)
	asteroid_pos = (asteroid_pos + 1) % ASTEROID_COUNT

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
