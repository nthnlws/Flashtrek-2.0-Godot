extends Area2D

@export var speed := 500.0

var movement_vector := Vector2(0, -1)

func _process(delta):
	if (self.global_position.x >= 19750 or self.global_position.x < -19750 or 
		self.global_position.y >= 19750 or self.global_position.y < -19750):
			self.free()
			print("laser")

func _physics_process(delta):
	global_position += movement_vector.rotated(rotation) * speed * delta

func _on_area_entered(area):
	if area is Asteroid:
		var asteroid = area
		asteroid.explode()
		queue_free()
