extends Control

var scale_nodes

func _ready():
	SignalBus.HUDchanged.connect(scale_HUD_button)
	
	scale_nodes = [
	get_node("Quadrant1"),
	get_node("Quadrant2"),
	get_node("Quadrant3"),
	get_node("Quadrant4"),
	get_node("CenterButton")
	]

func _gui_input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			# Get the global position of the mouse click
			var clicked_position = get_screen_position() + event.position

			# Handle mouse clicks based on click coordinates
			if is_point_in_collision_polygon(clicked_position, $Quadrant1.get_child(0)):
				get_viewport().set_input_as_handled()
				SignalBus.warp_button.emit()
				#print("quandrant1 clicked")
				
			elif is_point_in_collision_polygon(clicked_position, $Quadrant2.get_child(0)):
				get_viewport().set_input_as_handled()
				SignalBus.beam_button.emit()
				#print("quandrant2 clicked")
				
			elif is_point_in_collision_polygon(clicked_position, $Quadrant3.get_child(0)):
				get_viewport().set_input_as_handled()
				SignalBus.hail_button.emit()
				#print("quandrant3 clicked")
				
			elif is_point_in_collision_polygon(clicked_position, $Quadrant4.get_child(0)):
				get_viewport().set_input_as_handled()
				SignalBus.dock_button.emit()
				#print("quandrant4 clicked")
				
			elif is_point_in_collision_shape(clicked_position, $CenterButton.get_child(0)):
				get_viewport().set_input_as_handled()
				SignalBus.ship_upgrades_button.emit()
				scale_HUD_button(50)
				#print("Center button clicked")

func is_point_in_collision_polygon(point: Vector2, collision_polygon: CollisionPolygon2D) -> bool:
	# Get the polygon points from the CollisionPolygon2D
	var polygon = collision_polygon.polygon

	# Get the global transformation of the CollisionPolygon2D node, which includes scale, rotation, and position
	var global_transform = collision_polygon.get_global_transform()

	# Transform the local polygon points to global coordinates
	var global_polygon = []
	for p in polygon:
		global_polygon.append(global_transform * p)

	# Check if the point is inside the polygon
	return Geometry2D.is_point_in_polygon(point, global_polygon)



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



func scale_HUD_button(scale):
	for button in scale_nodes:
		button.scale = Vector2(scale, scale)
		#button.scale.y = 0.5
	$Sprite2D.scale = Vector2(0.4, 0.4) * Vector2(scale, scale)
