extends Control
class_name GalaxyMap

@onready var mission_message: RichTextLabel = $mission_message
@onready var current_system_message: RichTextLabel = $current_system_message
@onready var Menus: CanvasLayer = $".."
@onready var system_array: Array = get_tree().get_nodes_in_group("map_node") as Array[Area2D]
@onready var path_drawer: GalaxyPathDrawer = $WarpPathDrawer

@export var selection_marker: PackedScene
@export var systemMarker: PackedScene

var selected_system: String
var current_path_nodes: Array[Area2D] = [] # Warp path nodes

# Configuration for the flashlight effect
const REVEAL_RADIUS: float = 180.0 # Pixel distance to start fading
const FADE_SPEED: float = 5.0


func _ready() -> void:
	SignalBus.finishMission.connect(clear_mission)
	SignalBus.galaxy_warp_finished.connect(selectCurrentSystem)
	SignalBus.missionAccepted.connect(_update_mission)
	SignalBus.playerDied.connect(selectCurrentSystem.bind("Solarus"))
	SignalBus.galaxyDataUpdated.connect(update_system_names)


func _process(delta: float) -> void:
	if self.visible == false: return
	
	var mouse_pos: Vector2 = get_global_mouse_position()
	
	for area: Area2D in system_array:
		# 1. Calculate distance logic
		var dist: float = mouse_pos.distance_to(area.global_position)
		var target_alpha: float = clampf(inverse_lerp(REVEAL_RADIUS, 0.0, dist), 0.0, 1.0)
		
		# 2. Always show current system and special systems
		if (int(area.name) == LevelManager.current_system_data.system_index
			or GalaxyData.SPECIAL_SYSTEMS.values().has(int(area.name))):
				if area.name != "104": # Risa exception
					target_alpha = 1.0
			
		# 3. Apply the fade to the Label specifically
		var label:RichTextLabel = area.system_label
		if label:
			# Smoothly interpolate the alpha
			label.modulate.a = lerp(label.modulate.a, target_alpha, FADE_SPEED * delta)
			
			var target_scale: Vector2 = Vector2.ONE * (1.2 if target_alpha > 0.8 else 1.0)
			label.scale = label.scale.lerp(target_scale, FADE_SPEED * delta)


func _gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("left_click"):
		# Get the global position of the mouse click
		var clicked_position: Vector2 = get_screen_position() + event.position

		# Handle mouse clicks based on click coordinates
		for area:Area2D in system_array:
			var area_child = area.get_child(0)
			if is_point_in_collision_shape(clicked_position, area_child):
				get_viewport().set_input_as_handled()
				update_map_destination(area, area.system_data)
				SignalBus.UIclickSound.emit()
				return


func selectCurrentSystem(system_name:String) -> void:
	# Clear old marker
	for ind in get_tree().get_nodes_in_group("current_indicator"):
		ind.queue_free()
		
	# Add new indicator icon to map
	# Find array position of correct node
	var selected_system: int = -1
	for i in range(system_array.size()):
		var node:Area2D = system_array[i]
		if node.name == system_name:
			selected_system = i
	
	var indicator: Node2D = systemMarker.instantiate()
	indicator.modulate = Color(0, 255, 0, 255)
	indicator.add_to_group("current_indicator")
	system_array[selected_system].add_child(indicator)
	
	# Set text message
	match system_name:
		"Kronos":
			var current_system_text: String = "Current system: " + Utility.klin_red + system_name + "[/color]"
			current_system_message.bbcode_text = current_system_text
		"Solarus":
			var current_system_text: String = "Current system: " + Utility.fed_blue + system_name + "[/color]"
			current_system_message.bbcode_text = current_system_text
		"Romulus":
			var current_system_text: String = "Current system: " + Utility.rom_green + system_name + "[/color]"
			current_system_message.bbcode_text = current_system_text
		_:
			var current_system_text: String = "Current system: [color=#FFCC66]" + system_name + "[/color]"
			current_system_message.bbcode_text = current_system_text


func update_map_destination(system:Area2D, target_data:SystemData) -> void:
	# Update warp path
	var current_id = LevelManager.current_system_data.system_index
	var target_id = target_data.system_index
	var path_ids: Array[int] = GalaxyData.get_shortest_path(current_id, target_id)
	
	current_path_nodes.clear()
	for id in path_ids:
		var node = _find_node_by_system_id(id)
		if node:
			current_path_nodes.append(node)
			
	path_drawer.update_path(current_path_nodes)
	
	# Delete old selection indicator
	for red in get_tree().get_nodes_in_group("indicator_mark"):
		red.queue_free()
	
	# Create new selection indicator
	var indicator: Node2D = selection_marker.instantiate()
	indicator.add_to_group("indicator_mark")
	system.add_child(indicator)
	
	var tween: Tween = create_tween()
	tween.tween_property(indicator, "scale", Vector2(1.45, 1.45), 1.0)
	tween.tween_property(indicator, "scale", Vector2(1.05, 1.05), 1.0)
	tween.set_loops()
	
	SignalBus.destinationChanged.emit(target_data)
	print('destination changed')


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
	var global_transform:Transform2D = collision_shape.get_global_transform()

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


func update_system_names(galaxy_data:GalaxyData) -> void:
	for system:Area2D in system_array:
		var sys_data = galaxy_data.get_system(int(system.name))
		var system_string:String
		match sys_data.system_index: # Special system label coloring
			GalaxyData.SPECIAL_SYSTEMS.Solarus:
				system_string = Utility.fed_blue + sys_data.system_name.to_upper()  + "[/color]"
			GalaxyData.SPECIAL_SYSTEMS.Romulus:
				system_string = Utility.rom_green + sys_data.system_name.to_upper()  + "[/color]"
			GalaxyData.SPECIAL_SYSTEMS.Risa:
				system_string = Utility.fed_blue + sys_data.system_name.to_upper() + "[/color]"
			GalaxyData.SPECIAL_SYSTEMS.Kronos:
				system_string = Utility.klin_red + sys_data.system_name.to_upper()  + "[/color]"
			_: system_string = sys_data.system_name # All other systems
		
		system.change_system_label(system_string)


# Helper to find the Area2D based on the System ID (int)
func _find_node_by_system_id(id: int) -> Area2D:
	var search_name: String = str(id)
	for area in system_array:
		if area.name == search_name:
			return area
			
	return null
