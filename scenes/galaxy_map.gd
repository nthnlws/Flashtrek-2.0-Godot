extends Control

var area_array = []

func _ready():
	area_array = get_tree().get_nodes_in_group("map_node")
	for node in area_array:
		node.input_event.connect(node_click_handle.bind(node))
		
	print(area_array)

func node_click_handle(_viewport, event, _shape_idx, emitting_node):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		get_viewport().set_input_as_handled()
		SignalBus.galaxy_map_clicked.emit(emitting_node)
		

func is_point_in_collision_shape(point: Vector2, collision_shape: CollisionShape2D) -> bool:
	print("called")
	# Get the CircleShape2D from the CollisionShape2D
	var shape = collision_shape.shape as CircleShape2D
	var radius = shape.radius

	# Get the global transformation of the CollisionShape2D
	var global_transform = collision_shape.get_global_transform()

	# Get the global center of the circle by using the origin of the global transform
	var global_center = global_transform.origin

	# Apply the scale from the global transform to the radius
	var scaled_radius = radius * global_transform.get_scale().x

	# Check if the distance between the point and the center is less than or equal to the scaled radius
	return point.distance_to(global_center) <= scaled_radius
