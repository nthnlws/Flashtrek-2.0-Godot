extends Node3D

var MOVE_SPEED = 150.0 
@export var movementType: String = "Straight"
var boost_multiplier = 15
var distanceToCamera:float
var distance_multiplier:float

@onready var camera = %CharacterBody3D


func _process(delta):
	#Speed multiplier for when the ship is further away
	distanceToCamera = self.global_transform.origin.distance_to(camera.global_transform.origin)
	if distanceToCamera > 3000:
		distance_multiplier = ((distanceToCamera - 3000) / 3000 * 0.20) + 1
	else: distance_multiplier = 1.00

	print("Mult: " + str(distance_multiplier))
	print("Distance: " + str(distanceToCamera))
	
	
func _physics_process(delta):
	var current_speed = MOVE_SPEED
	if OS.get_name() == "Windows":
		if Input.is_action_pressed("warp"):
			current_speed *= boost_multiplier
	if OS.get_name() == "Android":
		if Input.is_action_pressed("left_click"):
			current_speed *= boost_multiplier
	
		
	if movementType == "Straight":
		translate(Vector3(current_speed * delta, 0, 0))
	elif movementType == "Path":
		$"..".progress += current_speed * delta * distance_multiplier
