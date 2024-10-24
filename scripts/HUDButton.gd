extends Control


func _gui_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			# Get the global position of the mouse click
			var clicked_position = get_screen_position() + event.position

			# Handle mouse clicks based on click coordinates
			if is_point_in_collision_polygon(clicked_position, $Quadrant1.get_child(0)):
				get_viewport().set_input_as_handled()
				SignalBus.warp_button.emit()
				
			elif is_point_in_collision_polygon(clicked_position, $Quadrant2.get_child(0)):
				get_viewport().set_input_as_handled()
				SignalBus.beam_button.emit()
				
			elif is_point_in_collision_polygon(clicked_position, $Quadrant3.get_child(0)):
				get_viewport().set_input_as_handled()
				SignalBus.hail_button.emit()
				
			elif is_point_in_collision_polygon(clicked_position, $Quadrant4.get_child(0)):
				get_viewport().set_input_as_handled()
				SignalBus.dock_button.emit()
				
			elif is_point_in_collision_shape(clicked_position, $CenterButton.get_child(0)):
				get_viewport().set_input_as_handled()
				SignalBus.ship_upgrades_button.emit()

func is_point_in_collision_polygon(point: Vector2, collision_polygon: CollisionPolygon2D) -> bool:
	# Checks click coordinates against each button Area2D
	
	# Get the polygon points from the CollisionPolygon2D
	var polygon = collision_polygon.polygon

	# Transform polygon points to global coordinates, accounting for parent scale
	var global_polygon = []
	var parent_scale = collision_polygon.get_parent().scale  # Get the scale of the parent Area2D
	for p in polygon:
		global_polygon.append((collision_polygon.global_position + p.rotated(collision_polygon.rotation)) * parent_scale)

	# Check if the point is inside the polygon
	return Geometry2D.is_point_in_polygon(point, global_polygon)

func is_point_in_collision_shape(point: Vector2, collision_shape: CollisionShape2D) -> bool:
	# Checks click coordinates against center button Area2D
	var shape = collision_shape.shape as CircleShape2D
	var radius = shape.radius
	
	# Get the global transform of the collision shape
	var global_transform = collision_shape.get_global_transform()
	
	# Get the global center of the circle
	var global_center = global_transform.origin
	
	# Check if the distance between the point and the center is less than or equal to the radius
	return point.distance_to(global_center) <= radius
