extends Area2D
class_name BaseTractorBeam

signal beam_activated(active: bool)

@onready var visuals: ColorRect = $CollisionShape2D/ColorRect
@onready var hitbox_polygon: CollisionPolygon2D = $CollisionShape2D

var beam_active: bool = false
var parent_node: Node2D

const DEFAULT_SIZE: int = 288
const MAX_BEAM_LENGTH: int = 1400


func _ready() -> void:
	parent_node = get_parent() as Node2D
	if not is_instance_valid(parent_node):
		push_error("BaseTractorBeam must be a child of a Node2D.")
		return
	_setup_tractor_beam_pulse_visuals()


# --- Public API ---

func _set_beam_enabled(enabled: bool) -> void:
	if beam_active == enabled:
		return
	beam_active = enabled
	hitbox_polygon.disabled = not enabled
	visuals.visible = enabled
	beam_activated.emit(enabled)


# --- Core Geometry ---

func update_tractor_beam(target_position: Vector2) -> void:
	var parent_position: Vector2 = parent_node.global_position
	var parent_rotation_rad: float = parent_node.global_rotation

	global_position = parent_position

	# Length and scale
	var new_length: float = target_position.distance_to(global_position)
	var new_scale: float = new_length * 1.1 / DEFAULT_SIZE
	scale.x = new_scale
	scale.y = min(1.0, new_length / 320.0)

	# Rotation
	var desired_angle_rad: float = global_position.angle_to_point(target_position)
	var angle_diff: float = angle_difference(parent_rotation_rad, desired_angle_rad)
	var final_rotation_rad: float = parent_rotation_rad + angle_diff

	global_rotation = final_rotation_rad


# --- Visuals Setup ---

func _setup_tractor_beam_pulse_visuals() -> void:
	var beam_shader = visuals.material
	var polygon_data: PackedVector2Array = hitbox_polygon.polygon

	var min_x: float = polygon_data[0].x
	var max_x: float = polygon_data[1].x
	var min_y: float = polygon_data[0].y
	var max_y: float = polygon_data[1].y

	for p in polygon_data:
		min_x = min(min_x, p.x)
		max_x = max(max_x, p.x)
		min_y = min(min_y, p.y)
		max_y = max(max_y, p.y)

	var bounding_box_size: Vector2 = Vector2(max_x - min_x, max_y - min_y)
	var bounding_box_position: Vector2 = Vector2(min_x, min_y)
	visuals.size = bounding_box_size
	visuals.position = bounding_box_position

	var points_in_rect_space: PackedVector2Array
	for p in polygon_data:
		points_in_rect_space.append(p - bounding_box_position)

	var geometric_center: Vector2 = (
		points_in_rect_space[0] + points_in_rect_space[1] + points_in_rect_space[2]
	) / 3.0

	var max_dist: float = 0.0
	for p in points_in_rect_space:
		max_dist = max(max_dist, p.distance_to(geometric_center))

	beam_shader.set_shader_parameter("u_rect_size", bounding_box_size)
	beam_shader.set_shader_parameter("u_vertex_a", points_in_rect_space[0])
	beam_shader.set_shader_parameter("u_vertex_b", points_in_rect_space[1])
	beam_shader.set_shader_parameter("u_vertex_c", points_in_rect_space[2])
