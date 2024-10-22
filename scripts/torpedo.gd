class_name Projectile extends Area2D

@export var speed:int = 1000
var firingPoint: Vector2
var shooter: String #Saves the shooter ID so that collision detection does not shoot self
var movement_vector := Vector2(0, -1)

var lifetime:float = 7.5
var age: float = 0.0

@export var damage:int = 15
	
func _process(delta):
	age += delta
	if (self.global_position.x >= GameSettings.borderValue or self.global_position.x < -GameSettings.borderValue or 
		self.global_position.y >= GameSettings.borderValue or self.global_position.y < -GameSettings.borderValue):
			queue_free()
			
	if age > lifetime:
		queue_free()

func _ready():
	firingPoint = self.global_position
	
func _physics_process(delta):
	global_position += movement_vector.rotated(rotation) * speed * delta
