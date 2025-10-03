extends Area2D
class_name TractorBeam

signal beam_activated(active: bool)
signal object_tractored(object: Node2D)
signal object_released(object: Node2D)
signal request_energy_drain(amount: float)

@export var debug_mode:bool = false

@onready var visuals: ColorRect = $CollisionShape2D/ColorRect
@onready var hitbox_polygon: CollisionPolygon2D = $CollisionShape2D
const DebugMarkerScene = preload("res://scenes/tools/debug_marker.tscn")
var debug_marker: Node2D = null

var beam_active:bool = false
var parent_scale:Vector2
const DEFAULT_SIZE:int = 288
const MAX_ANGLE_DEVIATION_RAD = deg_to_rad(35)

func _input(event: InputEvent) -> void:
	if debug_mode:
		if event.is_action_pressed("right_click"):
			activate_tractor_beam(global_position, global_rotation, get_global_mouse_position())
			debug_marker.visible = true
		if event.is_action_released("right_click"):
			deactivate_tractor_beam()
			debug_marker.visible = false


func _process(delta: float) -> void:
	if beam_active:
		if get_parent() is Player:
			global_position = get_parent().global_position
		if debug_mode:
			var target_position = get_global_mouse_position()
			update_tractor_beam(global_position, 0.0, target_position)
			debug_marker.global_position = target_position
			if is_aim_valid(0.0, get_global_mouse_position()):
				debug_marker.set_validity_color(true)
			else:
				debug_marker.set_validity_color(false)


func _ready() -> void:
	debug_marker = DebugMarkerScene.instantiate()
	get_tree().current_scene.call_deferred("add_child", debug_marker)
	debug_marker.visible = false
	
	_setup_tractor_beam_pulse_visuals()


func is_aim_valid(parent_rotation_rad: float, target_position: Vector2) -> bool:
	var desired_angle_rad = global_position.angle_to_point(target_position)
	# Shortest difference between desired angle and parent's angle.
	var angle_diff = angle_difference(parent_rotation_rad, desired_angle_rad)
	# Clamps relative difference to stay within allowed arc.
	return abs(angle_diff) <= MAX_ANGLE_DEVIATION_RAD


func update_tractor_beam(parent_position: Vector2, parent_rotation_rad: float, mouse_position:Vector2) -> void:
	var is_valid = is_aim_valid(parent_rotation_rad, mouse_position)
	if beam_active and is_valid:
		global_position = parent_position

		# --- Length and Scale Calculation ---
		var new_length = mouse_position.distance_to(global_position)
		var new_scale = new_length * 1.1 / DEFAULT_SIZE
		scale.x = new_scale
		if new_length < 320:
			scale.y = new_length / 320
		else:
			scale.y = 1.0

		# --- Rotation Logic ---
		var desired_angle_rad = global_position.angle_to_point(mouse_position)
		var angle_diff = angle_difference(parent_rotation_rad, desired_angle_rad)
		var clamped_angle_diff = clamp(angle_diff, -MAX_ANGLE_DEVIATION_RAD, MAX_ANGLE_DEVIATION_RAD)
		var final_rotation_rad = parent_rotation_rad + clamped_angle_diff

		# --- Apply Rotation and Update Debug Visuals ---
		global_rotation = final_rotation_rad
		
		if is_instance_valid(debug_marker) and debug_mode:
			debug_marker.global_position = mouse_position
			debug_marker.set_validity_color(is_valid)


func activate_tractor_beam(parent_position: Vector2, parent_rotation_rad: float, mouse_position:Vector2) -> void:
	if is_aim_valid(parent_rotation_rad, mouse_position):
		#print("aim valid, updating beam")
		update_tractor_beam(parent_position, parent_rotation_rad, mouse_position)
		visuals.visible = true
		beam_active = true
	#else: print("aim not valid")
func deactivate_tractor_beam() -> void:
	if visuals.visible == true:
		visuals.visible = false
	if beam_active == true:
		beam_active = false


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
