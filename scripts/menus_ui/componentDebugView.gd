extends Panel
class_name ComponentDebugPanel

const COMPONENT_ROW = preload("uid://csirae4a2j33d")
@onready var v_box_container: VBoxContainer = $MarginContainer/VBoxContainer

func _ready() -> void:
	SignalBus.system_changed.connect(sync_components)
	sync_components(LevelManager.current_system_data)

# Debug test for animation
func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.is_action_pressed("F9"):
			self.visible = !self.visible


func sync_components(system_data: SystemData) -> void:
	# 1. Clear existing debug rows
	var old_children: Array[Node] = get_tree().get_nodes_in_group("component_debug_row")
	for old_row: Node in old_children:
		old_row.queue_free()
	
	# 2. System Components
	var active_system_components: Dictionary = system_data.get_components()
	for type: SystemData.SystemComponentType in active_system_components.keys():
		var component_scene: PackedScene = system_data.component_map.get(type)
		if component_scene:
			var scene_name: String = _get_clean_component_name(component_scene)
			
			var new_line: ComponentLabelRow = COMPONENT_ROW.instantiate() as ComponentLabelRow
			new_line.set_component(scene_name, ComponentLabelRow.Icon.Node)
			v_box_container.add_child(new_line)
	
	# 3. Planet Components
	for planet: PlanetData in system_data.planet_data:
		var current_planet_components: Dictionary = planet.get_components()
		
		for comp_type: PlanetData.PlanetComponentType in current_planet_components.keys():
			var component_scene: PackedScene = planet.component_map.get(comp_type)
			
			if component_scene:
				var component_name: String = _get_clean_component_name(component_scene)
				var new_line: ComponentLabelRow = COMPONENT_ROW.instantiate() as ComponentLabelRow
				var display_text: String = "%s: %s" % [planet.name, component_name]
				
				new_line.set_component(display_text, ComponentLabelRow.Icon.Node2D)
				v_box_container.add_child(new_line)
	
	update_panel_dimensions()


func update_panel_dimensions() -> void:
	var component_rows: Array[Node] = get_tree().get_nodes_in_group("component_debug_row")
	var max_width: float = 0
	var height = (component_rows.size() * 20 ) + 20
	for node:Node in component_rows:
		var text_width: float = node.get_child(1).size.x
		if text_width > max_width: max_width = text_width
	
	self.custom_minimum_size = Vector2(max_width + 42, height)

func _get_clean_component_name(scene: PackedScene) -> String:
	var temp_node: Node = scene.instantiate()
	var clean_name: String = temp_node.name.trim_suffix("Component")
	temp_node.free()
	return clean_name
