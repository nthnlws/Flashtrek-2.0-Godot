extends Control

@onready var mission_message = $mission_message
@onready var Menus = $".."

var area_array = []

const HIGH:float = 4
const LOW:float = 0

var sound_array:Array = [] # Contains all nodes in group "click_sound"
var sound_array_location:int = 0


func _ready():
	SignalBus.missionAccepted.connect(_update_mission)
	
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
				Utility.mainScene.play_click_sound(0)
				return
				

func _update_mission(current_mission: Dictionary):
	if current_mission.is_empty():
		mission_message.bbcode_text = "Current Mission: None"
	else:
		var mission_text = "Current Mission: [color=#FFCC66]" + current_mission.get("target_system", "Unknown") + "[/color]"
		mission_message.bbcode_text = mission_text
	
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



func _on_close_menu_button_pressed():
	Menus.toggle_menu(self, 0)
