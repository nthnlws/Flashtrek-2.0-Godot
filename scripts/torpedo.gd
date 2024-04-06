extends Area2D

@export var speed := 500.0
var room_barrier:int = 19750

var movement_vector := Vector2(0, -1)

func _init():
	monitoring = true
	monitorable = true
	
func _process(delta):
	if (self.global_position.x >= room_barrier or self.global_position.x < -room_barrier or 
		self.global_position.y >= room_barrier or self.global_position.y < -room_barrier):
			self.free()

func _physics_process(delta):
	global_position += movement_vector.rotated(rotation) * speed * delta

func _on_area_entered(area):
	if area is Asteroid:
		var asteroid = area
		asteroid.explode()
		queue_free()
