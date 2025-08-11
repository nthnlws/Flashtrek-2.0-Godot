extends Control

@onready var mission_message: RichTextLabel = $mission_message
@onready var current_system_message: RichTextLabel = $current_system_message
@onready var Menus: CanvasLayer = $".."

@export var selection_marker: PackedScene
@export var systemMarker: PackedScene

var selected_system: String
var system_array = []

const HIGH:float = 4
const LOW:float = 0

func _ready() -> void:
	system_array = get_tree().get_nodes_in_group("map_node")
	
	SignalBus.finishMission.connect(clear_mission)
	SignalBus.galaxy_warp_finished.connect(selectCurrentSystem)
	SignalBus.missionAccepted.connect(_update_mission)
	SignalBus.playerDied.connect(selectCurrentSystem.bind("Solarus"))

	selectCurrentSystem(Navigation.currentSystem)

func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		# Get the global position of the mouse click
		var clicked_position: Vector2 = get_screen_position() + event.position

		# Handle mouse clicks based on click coordinates
		for area in system_array:
			var area_child = area.get_child(0)
			if is_point_in_collision_shape(clicked_position, area_child):
				get_viewport().set_input_as_handled()
				SignalBus.galaxy_map_clicked.emit(area.name)
				update_map_destination(area, area.name)
				SignalBus.UIclickSound.emit()
				return


func selectCurrentSystem(system) -> void:
	# Clear old marker
	for ind in get_tree().get_nodes_in_group("current_indicator"):
		ind.queue_free()
		
	# Add new indicator icon to map
	var selected_system: int = -1
	for i in range(system_array.size()):
		var node = system_array[i]
		if node.name == system:
			selected_system = i
	
	var indicator: Node2D = systemMarker.instantiate()
	indicator.modulate = Color(0, 255, 0, 255)
	indicator.add_to_group("current_indicator")
	system_array[selected_system].add_child(indicator)
	
	# Set text message
	match system:
		"Kronos":
			var current_system_text: String = "Current system: " + Utility.klin_red + system + "[/color]"
			current_system_message.bbcode_text = current_system_text
		"Solarus":
			var current_system_text: String = "Current system: " + Utility.fed_blue + system + "[/color]"
			current_system_message.bbcode_text = current_system_text
		"Romulus":
			var current_system_text: String = "Current system: " + Utility.rom_green + system + "[/color]"
			current_system_message.bbcode_text = current_system_text
		_:
			var current_system_text: String = "Current system: [color=#FFCC66]" + system + "[/color]"
			current_system_message.bbcode_text = current_system_text
	
func update_map_destination(system:Area2D, system_name:String) -> void:
	# Delete old selection indicator
	for red in get_tree().get_nodes_in_group("indicator_mark"):
		red.queue_free()
	
	selected_system = system_name
	Navigation.targetSystem = system_name
	
	# Create new indicator
	var indicator: Node2D = selection_marker.instantiate()
	indicator.add_to_group("indicator_mark")
	system.add_child(indicator)
	
	var tween: Tween = create_tween()
	tween.tween_property(indicator, "scale", Vector2(1.45, 1.45), 1.0)
	tween.tween_property(indicator, "scale", Vector2(1.05, 1.05), 1.0)
	tween.set_loops()
	

func clear_mission() -> void:
	mission_message.bbcode_text = "Current Mission: None"
	
	
func _update_mission(current_mission: Dictionary) -> void:
	if current_mission.is_empty():
		clear_mission()
	else:
		var system_name:String = current_mission.system
		var planet_name:String = current_mission.planet
		var first_string: String = "Current mission: " + Utility.UI_blue + planet_name + "[/color] in "

		var destination_text: String = first_string + "[color=#FFCC66]" + system_name + "[/color]"
		mission_message.bbcode_text = destination_text


func is_point_in_collision_shape(point: Vector2, collision_shape: CollisionShape2D) -> bool:
	# Get the CircleShape2D from the CollisionShape2D
	var shape = collision_shape.shape as CircleShape2D
	var radius: float = shape.radius

	# Get the global transformation of the CollisionShape2D
	var global_transform = collision_shape.get_global_transform()

	# Get the global center of the circle by using the origin of the global transform
	var global_center: Vector2 = global_transform.origin

	# Apply the scale from the global transform to the radius
	var scaled_radius: float = radius * global_transform.get_scale().x

	# Check if the distance between the point and the center is less than or equal to the scaled radius
	return point.distance_to(global_center) <= scaled_radius


func _on_close_menu_button_pressed() -> void:
	SignalBus.UIclickSound.emit()
	Menus.toggle_menu(self, 0)
	for red in get_tree().get_nodes_in_group("indicator_mark"):
		red.queue_free()


func _on_warp_button_pressed() -> void:
	SignalBus.UIclickSound.emit()
	Navigation.trigger_warp()
	visible = false
