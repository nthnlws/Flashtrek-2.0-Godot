extends Control

@onready var scale_nodes

var sound_array:Array = [] # Contains all nodes in group "click_sound"
var sound_array_location:int = 0

const HIGH:float = 2.0
const LOW:float = 0.5


var button_array = []

func _ready():
	SignalBus.HUDchanged.connect(scale_HUD_button)
	
	#Connect Input signals from HUD buttons
	button_array = get_tree().get_nodes_in_group("HUD_button")
	#for node in button_array:
		#node.input_event.connect(node_click_handle.bind(node))

	sound_array = get_tree().get_nodes_in_group("click_sound")
	sound_array.shuffle()


#func node_click_handle(_viewport, event, _shape_idx, emitting_node):
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		#get_viewport().set_input_as_handled()
		#self.accept_event()
		#var signal_name = emitting_node.name + "_clicked"
		#if SignalBus.has_signal(signal_name):
			#SignalBus.emit_signal(signal_name)
			#print(signal_name)
		#else:
			#print("no signal found")
	
func _gui_input(event):
	if event.is_action_pressed("left_click"):
		# Get the global position of the mouse click
		var clicked_position = get_screen_position() + event.position

		# Handle mouse clicks based on click coordinates
		for button in button_array:
			var button_child = button.get_child(0)
			var signal_name = button.name + "_clicked"
			if button_child is CollisionPolygon2D:
				if is_point_in_collision_polygon(clicked_position, button_child):
					get_viewport().set_input_as_handled()
					if SignalBus.has_signal(signal_name):
						SignalBus.emit_signal(signal_name)
						print(str(signal_name) + " emitted")
					play_click_sound(LOW)
					
			elif button_child is CollisionShape2D:
				if is_point_in_collision_shape(clicked_position, button_child):
					get_viewport().set_input_as_handled()
					if SignalBus.has_signal(signal_name):
						SignalBus.emit_signal(signal_name)
						print(str(signal_name) + " emitted")
					play_click_sound(LOW)
					

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



func scale_HUD_button(new_scale):
	scale = Vector2(new_scale, new_scale)
	
	
func play_click_sound(volume): 
	var sound_array_length = sound_array.size() - 1
	var default_db = sound_array[sound_array_location].volume_db
	var effective_volume = default_db / volume
	
	match sound_array_location:
		sound_array_length: # When location in array = array size, shuffle array and reset location
			#sound_array[sound_array_location].volume_db = effective_volume
			sound_array[sound_array_location].play()
			#sound_array[sound_array_location].volume_db = default_db
			sound_array.shuffle()
			sound_array_location = 0
		_: # Runs for all array values besides last
			#sound_array[sound_array_location].volume_db = effective_volume
			sound_array[sound_array_location].play()
			#sound_array[sound_array_location].volume_db = default_db
			sound_array_location += 1
