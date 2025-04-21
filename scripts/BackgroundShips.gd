extends Node2D

# Ship scene to instantiate
@export var ship_scene: PackedScene
@export var speed: float = 300
@export var sec_per_spawn: int = 10

# Size of the viewport
var viewport_size: Vector2

func _ready() -> void:
	$SpawnTimer.wait_time = sec_per_spawn
	$SpawnTimer.autostart = true
	$SpawnTimer.start()
	viewport_size = get_viewport().get_visible_rect().size
	spawn_ship()
	
func _on_timer_timeout() -> void:
	spawn_ship()


func spawn_ship() -> void:
	var ship = ship_scene.instantiate()
	
	# Get the start position
	var start_position: Vector2 = get_start_position()
	
	# Get the end position based on the start position
	var end_position: Vector2 = get_end_position(start_position)
	var distance: float = start_position.distance_to(end_position) #Used for tween speed
	
	# Set the ship's position and rotation
	#ship.shield_on = false
	ship.position = start_position
	var direction = (end_position - start_position).normalized()
	ship.rotation = direction.angle() + deg_to_rad(90)
	
	add_child(ship)
	
	# Move the ship to the target position with Tween
	var tween: Object = create_tween()
	tween.tween_property(ship, "position", end_position, distance/speed)

func get_start_position() -> Vector2:
	# Determine the starting side (0: top, 1: bottom, 2: left, 3: right)
	var side = randi_range(0, 3)
	var start_position: Vector2

	match side:
		0: # Top
			start_position = Vector2(randi_range(0, viewport_size.x), -50)
		1: # Bottom
			start_position = Vector2(randi_range(0, viewport_size.x), viewport_size.y + 50)
		2: # Left
			start_position = Vector2(-50, randi_range(0, viewport_size.y))
		3: # Right
			start_position = Vector2(viewport_size.x + 50, randi_range(0, viewport_size.y))

	return start_position

func get_end_position(start_position: Vector2) -> Vector2:
	var end_position: Vector2
	
	# Determine the end position based on the starting side
	if start_position.y == -50: # Came from top
		end_position = Vector2(randi_range(0, viewport_size.x), viewport_size.y + 50)
	elif start_position.y == viewport_size.y + 50: # Came from bottom
		end_position = Vector2(randi_range(0, viewport_size.x), -50)
	elif start_position.x == -50: # Came from left
		end_position = Vector2(viewport_size.x + 50, randi_range(0, viewport_size.y))
	elif start_position.x == viewport_size.x + 50: # Came from right
		end_position = Vector2(-50, randi_range(0, viewport_size.y))

	return end_position


