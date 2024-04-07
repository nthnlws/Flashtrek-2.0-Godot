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

var collided_with_player = false
func _on_area_exited():
		collided_with_player = true
		
func _on_area_entered(area):
	if area is Asteroid:
		var asteroid = area
		asteroid.explode()
		queue_free()
	elif area.is_in_group("player"):
		if collided_with_player == false:
			collided_with_player = true
			await get_tree().create_timer(1).timeout
		elif collided_with_player == true:
			var player = area.get_parent()
			player.die(area)
			queue_free()
