extends Node
class_name SystemComponentManager

var current_system_data: SystemData

# Map the Data Resource's component_id to the View's PackedScene
@export var system_component_map: Dictionary[StringName, PackedScene] = {
	&"kill_faction": preload("uid://dd0uqe0hng5gy"),
	&"protect_ship": preload("uid://bx0gpi1essltr"),
	&"container": preload("uid://cgljy0cnyeb7f")
}

# Tracks active physical components by mapping the Data Resource to its Node instance
var active_components: Dictionary[BaseComponentData, Node] = {}


func _ready() -> void:
	SignalBus.system_changed.connect(sync_components_to_new_system)


## Called globally when the player warps to a new star system
func sync_components_to_new_system(new_system: SystemData) -> void:
	# 1. Clean up the physical nodes from the old system
	_cleanup_active_components()
	
	current_system_data = new_system
	
	# 2. Spawn components based on the new system's persistent Data Resources
	for data: BaseComponentData in current_system_data.components:
		if data.is_finished:
			continue
			
		_spawn_component(data)


## Instantiates the View (Node) and passes the Data to it
func _spawn_component(data: BaseComponentData) -> void:
	if not system_component_map.has(data.component_id):
		printerr("System Component Manager: No PackedScene mapped for component_id '%s'" % data.component_id)
		return
		
	# Instantiate the physical Node
	var component_scene: PackedScene = system_component_map[data.component_id]
	var component_node: Node = component_scene.instantiate()
	
	add_child(component_node)
	
	# Pass the Data Resource into the physical Node
	if component_node.has_method("initialize"):
		component_node.initialize(data)
	else:
		printerr("System Component Manager: Node '%s' missing initialize() method!" % component_node.name)
		
	# Track the instance
	active_components[data] = component_node
	
	# Listen for when the Data Resource declares itself finished
	if not data.component_completed.is_connected(_on_component_completed):
		data.component_completed.connect(_on_component_completed.bind(data))


## Called if a component is dynamically added to the system while the player is currently inside it
func inject_runtime_component(data: BaseComponentData) -> void:
	if current_system_data and not current_system_data.components.has(data):
		current_system_data.components.append(data)
	_spawn_component(data)


## Automatically called when a Data Resource achieves its objective
func _on_component_completed(data: BaseComponentData) -> void:
	# 1. Remove the View Node
	if active_components.has(data):
		var node: Node = active_components[data]
		if is_instance_valid(node):
			node.queue_free()
		active_components.erase(data)
		
	# 2. Remove from SystemData so it doesn't respawn on return
	if current_system_data and current_system_data.components.has(data):
		current_system_data.components.erase(data)
		
	# 3. Disconnect Signal
	if data.component_completed.is_connected(_on_component_completed):
		data.component_completed.disconnect(_on_component_completed)


## Safely cleans up the physical nodes when leaving the star system
func _cleanup_active_components() -> void:
	for data: BaseComponentData in active_components.keys():
		var node: Node = active_components[data]
		if is_instance_valid(node):
			node.queue_free()
			
		# Disconnect signals so they don't fire in the background while unloaded
		if data.component_completed.is_connected(_on_component_completed):
			data.component_completed.disconnect(_on_component_completed)
			
	active_components.clear()


## Helper to check if a specific component type is currently active in the system
func has_component_type(target_id: StringName) -> bool:
	for data: BaseComponentData in active_components.keys():
		if data.component_id == target_id:
			return true
	return false
