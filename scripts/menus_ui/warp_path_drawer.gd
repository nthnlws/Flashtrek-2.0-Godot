extends Control
class_name GalaxyPathDrawer

# Stores the nodes we need to connect
var current_path_nodes: Array[Area2D] = []

# Configuration
const PULSE_LENGTH: float = 350.0
const LINE_WIDTH: float = 4.0
const BASE_COLOR: Color = Color(0.2, 0.6, 1.0, 0.5)
const FLASH_COLOR: Color = Color(0.6, 0.9, 1.0, 1.0)
const OUT_OF_RANGE_BASE_COLOR: Color = Color(1.0, 0.25, 0.25, 0.5)
const OUT_OF_RANGE_FLASH_COLOR: Color = Color(1.0, 0.6, 0.6, 1.0)

## Player's warp range in jumps. Segments past it draw red. -1 = no limit.
var max_range: int = -1


func _process(_delta: float) -> void:
	# Only request a redraw if we actually have a path to draw
	if not current_path_nodes.is_empty():
		queue_redraw()


# Public function called by the parent GalaxyMap
func update_path(nodes: Array[Area2D], warp_range: int = -1) -> void:
	current_path_nodes = nodes
	max_range = warp_range
	# Force an immediate update so it doesn't wait for the next process frame
	queue_redraw()


func _draw() -> void:
	if current_path_nodes.size() < 2:
		return

	# --- Pulse Logic ---
	# Creates a value between 0.0 and 1.0 that oscillates over time
	var pulse: float = (sin(Time.get_ticks_msec() / PULSE_LENGTH) + 1.0) / 2.0
	var current_color: Color = BASE_COLOR.lerp(FLASH_COLOR, pulse)
	var out_of_range_color: Color = OUT_OF_RANGE_BASE_COLOR.lerp(OUT_OF_RANGE_FLASH_COLOR, pulse)

	# --- Transform Logic ---
	# We convert global positions to this node's local space.
	# This ensures the lines draw correctly regardless of where PathDrawer is positioned.
	var drawer_transform_inv: Transform2D = get_global_transform().affine_inverse()

	for i in range(current_path_nodes.size() - 1):
		var node_a: Area2D = current_path_nodes[i]
		var node_b: Area2D = current_path_nodes[i+1]

		# Safety check in case a system node was deleted or scene changed
		if is_instance_valid(node_a) and is_instance_valid(node_b):
			var start_pos: Vector2 = drawer_transform_inv * node_a.global_position
			var end_pos: Vector2 = drawer_transform_inv * node_b.global_position
			
			# Segment i is jump i + 1 of the path
			var in_range: bool = max_range < 0 or i < max_range
			draw_line(start_pos, end_pos, current_color if in_range else out_of_range_color, LINE_WIDTH, true)
