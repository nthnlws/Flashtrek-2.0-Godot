class_name Projectile extends Area2D

@export var speed:int = 500
var room_barrier:int = 19750
var shooter #Saves the shooter ID so that collision detection does not shoot self
var movement_vector := Vector2(0, -1)

@export var damage:int = 10
	
func _process(delta):
	if (self.global_position.x >= room_barrier or self.global_position.x < -room_barrier or 
		self.global_position.y >= room_barrier or self.global_position.y < -room_barrier):
			self.free()

func _ready():
	pass
	
func _physics_process(delta):
	global_position += movement_vector.rotated(rotation) * speed * delta
