extends Area2D

@export var speed:float = 0.0
var room_barrier:int = 19750
var shooter
var movement_vector := Vector2(0, -1)

func _init():
	monitoring = false
	monitorable = true
	
func _process(delta):
	if (self.global_position.x >= room_barrier or self.global_position.x < -room_barrier or 
		self.global_position.y >= room_barrier or self.global_position.y < -room_barrier):
			self.free()

func _ready():
	#await get_tree().create_timer(1).timeout
	monitoring = true
	monitorable = true
	
func _physics_process(delta):
	global_position += movement_vector.rotated(rotation) * speed * delta

#var collided_with_player:bool = false
#func _on_area_exited():
		#collided_with_player = true
		
#func _on_area_entered(area):
	#if area.is_in_group("enemy") or area.has_method("explode"):
		#var asteroid = area
		#asteroid.explode()
		#queue_free()
	#
	#Torpedo collision with player
	#elif area.is_in_group("player"):
		#var player = area.get_parent()
		#player.die(area)
		#queue_free()
	#elif area.is_in_group("shield"):
		#var player = area.get_parent().get_parent()
		#player.die(area)
		#queue_free()
