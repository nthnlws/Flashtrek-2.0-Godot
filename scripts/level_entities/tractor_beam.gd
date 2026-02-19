extends Area2D
class_name TractorBeam

signal beam_activated(active: bool)
signal object_tractored(object: Node2D)
signal object_released(object: Node2D)
signal energy_drain(amount: float)
signal object_captured(container_data:ContainerData)

@export var debug_mode:bool = false

@onready var visuals: ColorRect = $CollisionShape2D/ColorRect
@onready var hitbox_polygon: CollisionPolygon2D = $CollisionShape2D

const DebugMarkerScene = preload("res://scenes/tools/debug_marker.tscn")
var debug_marker: Node2D = null

var beam_active: bool = false
var is_input_active: bool = false # Tracks if the right-click is held down
@export var tractor_speed: float = 250.0 # Speed in pixels/sec
var tractored_container: Area2D = null

var parent_node: Node2D # Store a reference to the parent (the player)

const DEFAULT_SIZE:int = 288
const MAX_BEAM_LENGTH:int = 1400
const MAX_ANGLE_DEVIATION_RAD = deg_to_rad(35)
@export var energy_drain_rate:float = 10.0


func _ready() -> void:
	# Store the parent for easy access to its position and rotation
	parent_node = get_parent() as Node2D
	if parent_node.has_signal("to_overdrive_transition"):
		parent_node.to_overdrive_transition.connect(_handle_parent_overdrive)
	if not is_instance_valid(parent_node):
		push_error("TractorBeam must be a child of a Node2D (like the Player).")
		return

	if debug_mode:
		debug_marker = DebugMarkerScene.instantiate()
		get_tree().current_scene.call_deferred("add_child", debug_marker)
		debug_marker.visible = false
		debug_marker.scale = Vector2(3, 3)
	
	_setup_tractor_beam_pulse_visuals()


func _physics_process(delta: float) -> void:
	if is_instance_valid(tractored_container) and beam_active:
		# The target is the beam's origin, which is the player's position
		var target_position: Vector2 = global_position
		
		# Use move_toward for smooth, consistent movement that stops at the target
		tractored_container.global_position = tractored_container.global_position.move_toward(
			target_position, 
			tractor_speed * delta
		)
		
		# Capture container if within 5 pixels
		if tractored_container.global_position.distance_to(target_position) < 5.0:
			object_captured.emit(tractored_container.container_data)
			SignalBus.containerPickedUp.emit(tractored_container)
			tractored_container.queue_free()
			tractored_container = null


func _process(delta: float) -> void:
	# If the player isn't holding the button, do nothing.
	if not is_input_active:
		if debug_mode and is_instance_valid(debug_marker):
			debug_marker.visible = false
		return

	# If we are holding the button, continuously check the aim.
	var target_position: Vector2 = get_global_mouse_position()
	var is_currently_valid: bool = is_aim_valid(parent_node.global_rotation, target_position)
	
	# --- State Transition Logic ---
	# If aim is valid and beam is off, turn it on.
	if is_currently_valid and not beam_active:
		beam_active = true
		hitbox_polygon.disabled = false
		visuals.visible = true
		beam_activated.emit(true)
	# If aim is invalid and beam is on, turn it off.
	elif not is_currently_valid and beam_active:
		beam_active = false
		hitbox_polygon.disabled = true
		visuals.visible = false
		beam_activated.emit(false)
		#object_released.emit(tractored_container)
		#tractored_container = null

	# If the beam is currently active, update its position and shape.
	if beam_active:
		update_tractor_beam(target_position)
		energy_drain.emit(energy_drain_rate)
	
	# The debug marker should always update its position and color while aiming.
	if debug_mode and is_instance_valid(debug_marker):
		debug_marker.visible = true
		debug_marker.global_position = target_position
		debug_marker.set_validity_color(is_currently_valid)


#region Public API
# Called when the tractor beam button is pressed.
func try_activate_beam() -> void:
	is_input_active = true

# Called when the tractor beam button is released.
func deactivate_beam() -> void:
	is_input_active = false
	
	# If the beam was active, ensure it's fully turned off now.
	if beam_active:
		beam_active = false
		visuals.visible = false
		beam_activated.emit(false)
		# object_released.emit(tractored_object)
#endregion


#region Internal Logic
func _handle_parent_overdrive() -> void:
	deactivate_beam()


func is_aim_valid(parent_rotation_rad: float, target_position: Vector2) -> bool:
	var origin_position = parent_node.global_position
	
	var length = origin_position.distance_to(target_position)
	var is_length_valid = length <= MAX_BEAM_LENGTH

	var desired_angle_rad = origin_position.angle_to_point(target_position)
	var angle_diff = angle_difference(parent_rotation_rad, desired_angle_rad)
	var is_angle_valid = abs(angle_diff) <= MAX_ANGLE_DEVIATION_RAD

	return is_length_valid and is_angle_valid


func update_tractor_beam(target_position: Vector2) -> void:
	var parent_position = parent_node.global_position
	var parent_rotation_rad = parent_node.global_rotation

	# Beam's position is always locked to parent's position
	global_position = parent_position

	# --- Length and Scale Calculation ---
	var new_length = target_position.distance_to(global_position)
	var new_scale = new_length * 1.1 / DEFAULT_SIZE
	scale.x = new_scale
	scale.y = min(1.0, new_length / 320.0)

	# --- Rotation Logic ---
	var desired_angle_rad = global_position.angle_to_point(target_position)
	var angle_diff = angle_difference(parent_rotation_rad, desired_angle_rad)
	var clamped_angle_diff = clamp(angle_diff, -MAX_ANGLE_DEVIATION_RAD, MAX_ANGLE_DEVIATION_RAD)
	var final_rotation_rad = parent_rotation_rad + clamped_angle_diff

	global_rotation = final_rotation_rad


func _setup_tractor_beam_pulse_visuals() -> void:
	var beam_shader = visuals.material
	var polygon_data: PackedVector2Array = hitbox_polygon.polygon

	# Calculate bounding box of the polygon to size the ColorRect
	var min_x = polygon_data[0].x
	var max_x = polygon_data[1].x
	var min_y = polygon_data[0].y
	var max_y = polygon_data[1].y

	for p in polygon_data:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	var bounding_box_size = Vector2(max_x - min_x, max_y - min_y)
	var bounding_box_position = Vector2(min_x, min_y)
	visuals.size = bounding_box_size

	# Set ColorRect's position and size to match the polygon's bounding box
	visuals.position = bounding_box_position
	visuals.size = bounding_box_size

	# Adjust polygon points to be relative to the ColorRect's new (0,0) (its top-left corner)
	var points_in_rect_space: PackedVector2Array
	for p in polygon_data:
		points_in_rect_space.append(p - bounding_box_position)

	# Calculate the center of the triangle in the ColorRect's local space
	var geometric_center = (points_in_rect_space[0] + points_in_rect_space[1] + points_in_rect_space[2]) / 3.0

	# Calculate the maximum distance from the center to any vertex for radial fade
	var max_dist = 0.0
	for p in points_in_rect_space:
		max_dist = max(max_dist, p.distance_to(geometric_center))

	# Pass individual polygon points and other uniforms to the shader
	beam_shader.set_shader_parameter("u_rect_size", bounding_box_size)
	beam_shader.set_shader_parameter("u_vertex_a", points_in_rect_space[0])
	beam_shader.set_shader_parameter("u_vertex_b", points_in_rect_space[1])
	beam_shader.set_shader_parameter("u_vertex_c", points_in_rect_space[2])


#endregion


func _on_area_entered(area: Area2D) -> void:
	# Do nothing if we're already tractoring something
	if tractored_container:
		return

	# Check if the area is a container we can tractor
	if area is ContainerPickup: # A more direct and safe way to check the class
		tractored_container = area
		
		object_tractored.emit(tractored_container.container_data) 
		#print("Tractor beam latched onto container: ", area.name)


func _on_area_exited(area: Area2D) -> void:
	# If the specific container we were tractoring has left, release our lock
	if area == tractored_container:
		object_released.emit(tractored_container.container_data)
		#print("Container left tractor beam range: ", area.name)
		tractored_container = null
