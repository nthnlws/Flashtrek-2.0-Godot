class_name Projectile extends Area2D

@export var speed:int = 500
var firingPoint: Vector2
var shooter: String #Saves the shooter ID so that collision detection does not shoot self
var movement_vector := Vector2(0, -1)

@export var damage:int = 15
	
func _process(delta):
	if (self.global_position.x >= GameSettings.gameSize or self.global_position.x < -GameSettings.gameSize or 
		self.global_position.y >= GameSettings.gameSize or self.global_position.y < -GameSettings.gameSize):
			queue_free()
			
	if position.distance_to(firingPoint) >= 2500:
		queue_free()

func _ready():
	firingPoint = self.global_position
	
func _physics_process(delta):
	global_position += movement_vector.rotated(rotation) * speed * delta
