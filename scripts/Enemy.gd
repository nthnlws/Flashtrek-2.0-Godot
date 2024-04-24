class_name Enemy extends CharacterBody2D

signal exploded(pos, size, points)
signal player_collision(Area: Area2D)

@export var speed:int= 50

@onready var trans_length:float= 0.8

var startPosition
var endPosition

func _ready():
	#var shieldScene = preload("res://scenes/enemyShield.tscn")
	#var newShield = shieldScene.instantiate()
	#add_child(newShield)
	
	startPosition = position
	endPosition = startPosition + Vector2(100, 500)
	
func _physics_process(delta):
	if self.visible == false: return
	
	updateVelocity()
	move_and_slide()

	var direction = velocity.normalized() # Determine the direction of movement
	var angle = direction.angle() # Calculate the angle of rotation
	angle += deg_to_rad(90) # Adjust the angle by adding 90 degrees
	rotation = angle

func updateVelocity():
	var moveDirection = endPosition - position
	velocity = moveDirection.normalized()*speed

func explode():
	queue_free()
	self.visible = false

func _on_enemy_area_entered(area):
	if area.is_in_group("torpedo"):
		area.queue_free()
		explode()

func _on_agro_box_area_entered(area):
	if area.is_in_group("player"):
		return # Replace with function body.
