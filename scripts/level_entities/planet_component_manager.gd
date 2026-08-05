extends Node
class_name PlanetComponentManager

var current_planet_data: PlanetData

# Map the Data Resource's component_id to the View's PackedScene
@export var planet_component_map: Dictionary[StringName, PackedScene] = {
	&"analyze": preload("uid://cq5kxvmajgng5"),
	&"communication": preload("uid://rr6unh73nxxs"),
	# &"deliver": preload("res://scenes/components/...")
}

# Tracks active physical components by mapping the Data Resource to its Node instance
var active_components: Dictionary[BaseComponentData, Node] = {}


## Called when the Planet Node is loaded into the world.
func sync_components(planet_data: PlanetData) -> void:
	current_planet_data = planet_data
	
	_cleanup_active_components()
	
	for data: BaseComponentData in planet_data.components:
		# Skip spawning components that are already marked finished
		if data.is_finished:
			continue
			
		_spawn_component(data)


## Spawns a physical Node based on a Data Resource and passes the data in.
func _spawn_component(data: BaseComponentData) -> void:
	if not planet_component_map.has(data.component_id):
		printerr("Component Manager: No PackedScene mapped for component_id '%s'" % data.component_id)
		return
		
	# Instantiate the physical Node
	var component_scene: PackedScene = planet_component_map[data.component_id]
	var component_node: Node = component_scene.instantiate()
	
	add_child(component_node)
	
	# Pass the Data Resource into the physical Node
	if component_node.has_method("initialize"):
		component_node.initialize(data)
	else:
		printerr("Component Manager: Node '%s' missing initialize() method!" % component_node.name)
		
	# Track it
	active_components[data] = component_node
	
	# Listen for when the Data Resource declares itself finished.
	# .bind(data) allows us to pass the specific resource into the parameterless signal.
	if not data.component_completed.is_connected(_on_component_completed):
		data.component_completed.connect(_on_component_completed.bind(data))


## Called dynamically if a component is added to the planet while the player is already in the system.
func inject_runtime_component(data: BaseComponentData) -> void:
	if current_planet_data and not current_planet_data.components.has(data):
		current_planet_data.components.append(data)
	_spawn_component(data)


## Automatically called when a Data Resource finishes its objective
func _on_component_completed(data: BaseComponentData) -> void:
	# 1. Safely remove the physical View Node from the world
	if active_components.has(data):
		var node: Node = active_components[data]
		if is_instance_valid(node):
			node.queue_free()
		active_components.erase(data)
		
	# 2. Erase the completed Data from the persistent PlanetData so it doesn't spawn next visit
	if current_planet_data and current_planet_data.components.has(data):
		current_planet_data.components.erase(data)
		
	# 3. Disconnect the signal
	if data.component_completed.is_connected(_on_component_completed):
		data.component_completed.disconnect(_on_component_completed)


## Safely cleans up the world Nodes if the player leaves the system
func _cleanup_active_components() -> void:
	for data: BaseComponentData in active_components.keys():
		var node: Node = active_components[data]
		if is_instance_valid(node):
			node.queue_free()
			
		if data.component_completed.is_connected(_on_component_completed):
			data.component_completed.disconnect(_on_component_completed)
			
	active_components.clear()


## Helper to check if a specific component type is currently active on the planet
func has_component_type(target_id: StringName) -> bool:
	for data: BaseComponentData in active_components.keys():
		if data.component_id == target_id:
			return true
	return false

## Helper to get a specific component view by its ID
func get_component_by_type(target_id: StringName) -> Node:
	for data: BaseComponentData in active_components.keys():
		if data.component_id == target_id:
			return active_components[data]
	return null
