extends Control
class_name GalaxyMap

@onready var mission_message: RichTextLabel = $mission_message
@onready var current_system_message: RichTextLabel = $currentSys_message
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
	MissionManager.mission_completed.connect(clear_mission_text.unbind(1))
	MissionManager.mission_started.connect(update_mission_text)
	SignalBus.galaxyDataUpdated.connect(update_system_names)
	SignalBus.system_changed.connect(update_current_system)


func _process(delta: float) -> void:
	if self.visible == false: return
	
	var mouse_pos: Vector2 = get_global_mouse_position()
	
	for area: Area2D in system_array:
		# Calculate distance from mouse
		var dist: float = mouse_pos.distance_to(area.global_position)
		var target_alpha: float = clampf(inverse_lerp(REVEAL_RADIUS, 0.0, dist), 0.0, 1.0)
		
		# Force show special systems
		if (int(area.name) == LevelManager.current_system_data.system_index # Current system
			or GalaxyData.SPECIAL_SYSTEMS.values().has(int(area.name))): # Special system
				if int(area.name) != GalaxyData.SPECIAL_SYSTEMS.Risa: # Risa exception
					target_alpha = 1.0
		if LevelManager.target_system_data: # Target system
			if int(area.name) == LevelManager.target_system_data.system_index:
				target_alpha = 1.0
			
		# Apply label fade
		var label: RichTextLabel = area.system_label
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
		for area: Area2D in system_array:
			var area_child = area.get_child(0)
			if is_point_in_collision_shape(clicked_position, area_child):
				get_viewport().set_input_as_handled()
				update_map_destination(area, area.system_data)
				AudioManager.play_UI_click_sound()
				return


func update_current_system(system_data: SystemData) -> void:
	#print('updating galaxy map current system to %s' % system_data.system_name)
	# Update warp path
	var current_id = system_data.system_index
	update_map_destination(_find_node_by_system_id(current_id), system_data) # Update path selection to current system
	var system_name = system_data.system_name
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


func update_map_destination(system: Area2D, target_data: SystemData) -> void:
	#print_debug("Selected %s system, faction: %s, index: %s" % [target_data.system_name, Utility.FACTION.keys()[target_data.faction], target_data.system_index])
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
	
	var tween: Tween = indicator.create_tween()
	tween.set_loops()
	
	# Add the steps (Sequential by default)
	tween.tween_property(indicator, "scale", Vector2(1.45, 1.45), 1.0)
	tween.tween_property(indicator, "scale", Vector2(1.05, 1.05), 1.0)
	
	LevelManager.target_system_data = target_data


func clear_mission_text() -> void:
	mission_message.bbcode_text = "Current Mission: None"


func update_mission_text(current_mission: MissionData) -> void:
	if current_mission == null:
		clear_mission_text()
	else:
		var system_name: String = current_mission.target_system.system_name
		var target: String = current_mission.target_planet_name
		if !(current_mission.type == MissionData.MISSION_TYPE.DELIVERY
			or current_mission.type == MissionData.MISSION_TYPE.ANALYZE):
				target = current_mission.title
		 
		var first_string: String = "Current mission: %s in " % Utility.color_string(Utility.UI_yellow, target)
		
		var destination_text: String = first_string + "[color=#FFCC66]" + system_name + "[/color]"
		# Color target system to match faction
		match current_mission.target_system.faction:
			Utility.FACTION.FEDERATION:
				destination_text = first_string + Utility.fed_blue + system_name + "[/color]"
			Utility.FACTION.ROMULAN:
				destination_text = first_string + Utility.rom_green + system_name + "[/color]"
			Utility.FACTION.KLINGON:
				destination_text = first_string + Utility.klin_red + system_name + "[/color]"
			_: pass
		mission_message.bbcode_text = destination_text


func is_point_in_collision_shape(point: Vector2, collision_shape: CollisionShape2D) -> bool:
	# Get the CircleShape2D from the CollisionShape2D
	var shape = collision_shape.shape as CircleShape2D
	var radius: float = shape.radius

	# Get the global transformation of the CollisionShape2D
	var global_transform: Transform2D = collision_shape.get_global_transform()

	# Get the global center of the circle by using the origin of the global transform
	var global_center: Vector2 = global_transform.origin

	# Apply the scale from the global transform to the radius
	var scaled_radius: float = radius * global_transform.get_scale().x

	# Check if the distance between the point and the center is less than or equal to the scaled radius
	return point.distance_to(global_center) <= scaled_radius


func _on_close_menu_button_pressed() -> void:
	AudioManager.play_UI_click_sound()
	Menus.toggle_menu(self , 0)
	for red in get_tree().get_nodes_in_group("indicator_mark"):
		red.queue_free()


func _on_warp_button_pressed() -> void:
	AudioManager.play_UI_click_sound()
	SignalBus.TopLeft_clicked.emit()
	visible = false


func update_system_names(galaxy_data: GalaxyData) -> void:
	for system: Area2D in system_array:
		var sys_data = galaxy_data.get_system(int(system.name))
		var system_string: String
		match sys_data.system_index: # Special system label coloring
			GalaxyData.SPECIAL_SYSTEMS.Solarus:
				system_string = Utility.fed_blue + sys_data.system_name.to_upper() + "[/color]"
			GalaxyData.SPECIAL_SYSTEMS.Romulus:
				system_string = Utility.rom_green + sys_data.system_name.to_upper() + "[/color]"
			GalaxyData.SPECIAL_SYSTEMS.Risa:
				system_string = Utility.fed_blue + sys_data.system_name.to_upper() + "[/color]"
			GalaxyData.SPECIAL_SYSTEMS.Kronos:
				system_string = Utility.klin_red + sys_data.system_name.to_upper() + "[/color]"
			_: system_string = sys_data.system_name # All other systems
		
		system.change_system_label(system_string)


# Helper to find the Area2D based on the System ID (int)
func _find_node_by_system_id(id: int) -> Area2D:
	var search_name: String = str(id)
	for area in system_array:
		if area.name == search_name:
			return area
			
	return null
