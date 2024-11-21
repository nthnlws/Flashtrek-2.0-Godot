extends CharacterBody3D

var move_speed = 100.0
var mouse_sensitivity = Vector2(0.2, 0.2)
var camera_rotation = Vector2.ZERO
var boost_multiplier : float = 4.0

@onready var camera = $Camera3D  # Replace with the correct path to your Camera node
@onready var ent_kelvin = %Ent_Kelvin


#func _ready():
	# Capture mouse for camera movement
	#Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta):
	var target_position = ent_kelvin.global_transform.origin + Vector3(50, 25, 0)
	camera.look_at(target_position, Vector3.UP)


#func _physics_process(delta):
	#var current_speed = move_speed
	#if Input.is_action_pressed("warp"):
		#current_speed *= boost_multiplier
#
	## Move directly up or down based on input
	#if Input.is_action_pressed("space"):
		#velocity.y = move_speed * boost_multiplier
	#elif Input.is_action_pressed("CTRL"):
		#velocity.y = -move_speed * boost_multiplier
	#else:
		#velocity.y = 0
		#
	## Calculate movement direction
	#var input_dir = Input.get_vector("rotate_left", "rotate_right", "move_backward", "move_forward")
	## Get the direction the camera is facing, flattened to remove any vertical component
	#var movement_direction = -camera.transform.basis.z
	#movement_direction.y = 0  # Flatten the direction to horizontal
	#movement_direction = movement_direction.normalized()
#
	## Apply movement based on player direction
	#var final_direction = (movement_direction * input_dir.y + camera.transform.basis.x * input_dir.x).normalized()
	#var movement_vector = final_direction * current_speed
#
	## Update velocity without modifying x, y, or z directly
	#velocity.x = movement_vector.x
	#velocity.z = movement_vector.z
#
	#move_and_slide()
