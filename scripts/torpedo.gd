class_name Projectile extends Area2D

@export var speed:int = 500
var room_barrier:int = 19750
var firingPoint
var shooter #Saves the shooter ID so that collision detection does not shoot self
var movement_vector := Vector2(0, -1)

@export var damage:int = 20
	
func _process(delta):
	if (self.global_position.x >= room_barrier or self.global_position.x < -room_barrier or 
		self.global_position.y >= room_barrier or self.global_position.y < -room_barrier):
			queue_free()
			
	if position.distance_to(firingPoint) >= 2500:
		queue_free()

func _ready():
	firingPoint = self.global_position
	
func _physics_process(delta):
	global_position += movement_vector.rotated(rotation) * speed * delta

