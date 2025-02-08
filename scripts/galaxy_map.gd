extends Control

@onready var mission_message = $mission_message
@onready var destination_message = $destination_message
@onready var Menus = $".."

@export var red_circle: PackedScene
var selected_system: String

var area_array = []

const HIGH:float = 4
const LOW:float = 0

var sound_array:Array = [] # Contains all nodes in group "click_sound"
var sound_array_location:int = 0


func _ready():
	# Adds close menu button if galaxy map is not root scene
	if get_tree().current_scene.name == "GalaxyMap":
		$MarginContainer/closeMenuButton.visible = false
		Utility.mainScene = self
	
	SignalBus.Quad1_clicked.connect(trigger_warp)
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
				update_map_destination(area, area.name)
				Utility.play_click_sound(0)
				return
				

func update_map_destination(system:Area2D, system_name:String):
	# Delete old selection indicator
	for red in get_tree().get_nodes_in_group("indicator_mark"):
		red.queue_free()
	
	selected_system = system_name
	Navigation.targetSystem = system_name
	
	# Create new indicator
	var indicator = red_circle.instantiate()
	indicator.add_to_group("indicator_mark")
	system.add_child(indicator)
	
	var tween = create_tween()
	tween.tween_property(indicator, "scale", Vector2(1.45, 1.45), 1.0)
	tween.tween_property(indicator, "scale", Vector2(1.05, 1.05), 1.0)
	tween.set_loops()
	
	# Set text color
	match system_name:
		"Kronos":
			var destination_text = "Current destination: " + Utility.klin_red + system.name + "[/color]"
			destination_message.bbcode_text = destination_text
		"Solarus":
			var destination_text = "Current destination: " + Utility.fed_blue + system.name + "[/color]"
			destination_message.bbcode_text = destination_text
		"Romulus":
			var destination_text = "Current destination: " + Utility.rom_green + system.name + "[/color]"
			destination_message.bbcode_text = destination_text
		_:
			var destination_text = "Current destination: [color=#FFCC66]" + system.name + "[/color]"
			destination_message.bbcode_text = destination_text
	
func _update_mission(current_mission: Dictionary):
	var system_name:String = current_mission.get("target_system", "Unknown")
	if current_mission.is_empty():
		mission_message.bbcode_text = "Current Mission: None"
	else:
		match system_name:
			"Kronos":
				var destination_text = "Current destination: " + Utility.klin_red + system_name + "[/color]"
				mission_message.bbcode_text = destination_text
			"Solarus":
				var destination_text = "Current destination: " + Utility.fed_blue + system_name + "[/color]"
				mission_message.bbcode_text = destination_text
			"Romulus":
				var destination_text = "Current destination: " + Utility.rom_green + system_name + "[/color]"
				mission_message.bbcode_text = destination_text
			_:
				var destination_text = "Current destination: [color=#FFCC66]" + system_name + "[/color]"
				mission_message.bbcode_text = destination_text
	
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
	Utility.play_click_sound(HIGH)
	Menus.toggle_menu(self, 0)
	for red in get_tree().get_nodes_in_group("indicator_mark"):
		red.queue_free()


func _on_warp_button_pressed():
	Utility.play_click_sound(HIGH)
	trigger_warp()
	
	
func trigger_warp():
	if selected_system:
		print("Warping to system " + str(Navigation.targetSystem))
		SignalBus.triggerGalaxyWarp.emit()
		self.visible = false
	#else: TODO: Trigger error message for no selected system
