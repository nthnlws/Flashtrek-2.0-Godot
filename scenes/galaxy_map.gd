extends Control

var area_array = []

const HIGH:float = 2.0
const LOW:float = 0.5

var sound_array:Array = [] # Contains all nodes in group "click_sound"
var sound_array_location:int = 0


func _ready():
	area_array = get_tree().get_nodes_in_group("map_node")
	
	sound_array = get_tree().get_nodes_in_group("click_sound")
	sound_array.shuffle()

func _gui_input(event):
	if event.is_action_pressed("left_click"):
		# Get the global position of the mouse click
		var clicked_position = get_screen_position() + event.position

		# Handle mouse clicks based on click coordinates
		for area in area_array:
			var area_child = area.get_child(0)
			if is_point_in_collision_shape(clicked_position, area_child):
				get_viewport().set_input_as_handled()
				SignalBus.galaxy_map_clicked.emit(area.name)
				play_click_sound(LOW)
				return
				

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
