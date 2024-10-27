extends Control

var area_array = []

func _ready():
	area_array = get_tree().get_nodes_in_group("map_node")

func _gui_input(event):
	if event.is_action_pressed("left_click"):
		# Get the global position of the mouse click
		var clicked_position = get_screen_position() + event.position

		# Handle mouse clicks based on click coordinates
		for area in area_array:
			var area_child = area.get_child(0)
			var signal_name = area.name + "_clicked"
			if is_point_in_collision_shape(clicked_position, area_child):
				get_viewport().set_input_as_handled()
				#if SignalBus.has_signal(signal_name):
					#SignalBus.emit_signal(signal_name)
				print(str(signal_name) + " emitted")
				#play_click_sound(LOW)
		

func is_point_in_collision_shape(point: Vector2, collision_shape: CollisionShape2D) -> bool:
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
