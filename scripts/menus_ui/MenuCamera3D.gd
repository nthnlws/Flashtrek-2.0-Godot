# This script provides basic movement and panning functionality for a Camera3D node in Godot 4.
# Attach this script to the Camera3D node to allow simple movement and angle adjustments using keyboard and mouse inputs.

extends Camera3D

@export var move_speed : float = 50.0
@export var look_sensitivity : float = 0.003
@export var boost_multiplier : float = 8.0

var rotation_enabled : bool = false

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta: float):
	# Handle camera movement
	var direction = Vector3.ZERO
	var current_speed = move_speed
	if Input.is_action_pressed("overdrive"):
		current_speed *= boost_multiplier

	if Input.is_action_pressed("move_forward"):
		direction -= basis.z
	if Input.is_action_pressed("move_backward"):
		direction += basis.z
	if Input.is_action_pressed("rotate_left"):
		direction -= basis.x
	if Input.is_action_pressed("rotate_right"):
		direction += basis.x

	if direction != Vector3.ZERO:
		direction = direction.normalized() * current_speed * delta
		translate(direction)

	# Handle rotation enabling (using right mouse button)
	if Input.is_action_just_pressed("shoot_laser"):
		rotation_enabled = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif Input.is_action_just_released("shoot_laser"):
		rotation_enabled = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Handle camera rotation
	if rotation_enabled:
		var mouse_movement = Input.get_last_mouse_velocity()
		var yaw = -mouse_movement.x * look_sensitivity * delta
		var pitch = -mouse_movement.y * look_sensitivity * delta

		rotate_y(yaw)
		rotate_object_local(Vector3(1, 0, 0), pitch)

# Input mappings need to be set in the Godot Input Map for the following actions:
# - "move_forward": typically "W" key
# - "move_backward": typically "S" key
# - "move_left": typically "A" key
# - "move_right": typically "D" key
# - "ui_focus": typically right mouse button, for enabling/disabling camera panning
# - "move_boost": typically "Shift" key, for faster movement
