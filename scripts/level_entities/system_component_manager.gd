extends Node2D
class_name ComponentManager

## Single active system's worth of state. There's only ever one SystemData
## live at a time, so - unlike planets - it needs no per-component owner
## reference; this manager tracks it directly.
var current_system_data: SystemData

# Tracks active physical components by mapping the Data Resource to its Node instance.
# Keyed by the data instance (not component_id), so any number of components
# sharing the same component_id - multiple scrap fields, or one communication
# component per planet - can be active simultaneously.
var active_components: Dictionary[BaseComponentData, Node] = {}


func _ready() -> void:
	SignalBus.system_changed.connect(sync_components_to_new_system)


## Called globally when the player warps to a new star system. Spawns every
## unfinished component owned by the system itself, and every unfinished
## component owned by each of its planets.
func sync_components_to_new_system(new_system: SystemData) -> void:
	# 1. Clean up the physical nodes from the old system
	_cleanup_active_components()

	current_system_data = new_system

	# 2. Spawn system-scoped components (copy - orphans are erased while spawning)
	for data: BaseComponentData in current_system_data.components.duplicate():
		if data.is_finished:
			continue
		_spawn_component(data)

	# 3. Spawn every planet's components
	for planet: PlanetData in current_system_data.planet_data:
		for data: BaseComponentData in planet.components.duplicate():
			if data.is_finished:
				continue
			_spawn_component(data)


## Instantiates the in-level node and passes data in
func _spawn_component(data: BaseComponentData) -> void:
	# Drop components whose mission isn't active (e.g. after loading a save)
	if not data.mission_id.is_empty() and not MissionManager.is_mission_active(data.mission_id):
		_mutate_owning_collection(data, func(collection: Array, d: BaseComponentData) -> void:
			collection.erase(d)
		)
		return

	var component_scene: PackedScene = ComponentRegistry.get_scene(data.component_id)
	if component_scene == null:
		printerr("Component Manager: No ComponentDefinition registered for component_id '%s'" % data.component_id)
		return

	# Instantiate the physical Node
	var component_node: BaseComponent = component_scene.instantiate()

	add_child(component_node)

	# Planet components are no longer parented under their planet's Node, so
	# they need their world position set explicitly to line up with it.
	if data is PlanetComponentData:
		var planet_data: PlanetComponentData = data as PlanetComponentData
		if planet_data.owning_planet:
			component_node.global_position = planet_data.owning_planet.world_position

	# Registered before initialize() so an immediate resolve is cleaned up
	active_components[data] = component_node

	if not data.component_completed.is_connected(_on_component_completed):
		data.component_completed.connect(_on_component_completed.bind(data))

	component_node.initialize(data)


## Calls `mutate(collection, data)` on the array that owns `data`: its planet's
## components or the current system's.
func _mutate_owning_collection(data: BaseComponentData, mutate: Callable) -> void:
	if data is PlanetComponentData:
		var owning_planet: PlanetData = (data as PlanetComponentData).owning_planet
		if owning_planet:
			mutate.call(owning_planet.components, data)
	elif current_system_data:
		mutate.call(current_system_data.components, data)


## Called if a component is dynamically added to the system while the player
## is currently inside it (e.g. accepting a mission for the planet/system
## you're already at).
func inject_component(data: BaseComponentData) -> void:
	_mutate_owning_collection(data, func(collection: Array, d: BaseComponentData) -> void:
		if not collection.has(d):
			collection.append(d)
	)

	_spawn_component(data)

	# Anything that only refreshes on SignalBus.system_changed (e.g. the
	# minimap) needs telling explicitly, since this path doesn't go through
	# a system change.
	SignalBus.component_injected.emit(data)


func is_spawned(data: BaseComponentData) -> bool:
	return active_components.has(data)


func _on_component_completed(success: bool, data: BaseComponentData) -> void:
	# 1. Remove the View Node
	if active_components.has(data):
		var node: Node = active_components[data]
		if is_instance_valid(node):
			node.queue_free()
		active_components.erase(data)

	# 2. Remove from its persistent owner so it doesn't respawn on return
	_mutate_owning_collection(data, func(collection: Array, d: BaseComponentData) -> void:
		collection.erase(d)
	)

	# 3. Disconnect Signal
	if data.component_completed.is_connected(_on_component_completed):
		data.component_completed.disconnect(_on_component_completed)

	# 4. Report the outcome
	SignalBus.component_resolved.emit(data, success)

	# Anything that only refreshes on SignalBus.system_changed (e.g. the
	# debug panel's row list) needs telling explicitly, since a component can
	# finish mid-system without a system change occurring.
	SignalBus.component_removed.emit(data)


## Safely cleans up the physical nodes when leaving the star system
func _cleanup_active_components() -> void:
	for data: BaseComponentData in active_components.keys():
		var node: Node = active_components[data]
		if is_instance_valid(node):
			node.queue_free()
		if data.component_completed.is_connected(_on_component_completed):
			data.component_completed.disconnect(_on_component_completed)

	active_components.clear()


## Helper to check if any active component of a given type exists, regardless
## of what it's owned by.
func has_component_type(target_id: StringName) -> bool:
	for data: BaseComponentData in active_components.keys():
		if data.component_id == target_id:
			return true
	return false


## Helper to find a specific planet's active component of a given type. Since
## a planet can only ever have one component of a given component_id at a
## time in practice (e.g. one "communication" component), this returns the
## first match.
func get_planet_component(planet_data: PlanetData, target_id: StringName) -> Node:
	for data: BaseComponentData in active_components.keys():
		if data is PlanetComponentData and data.component_id == target_id and (data as PlanetComponentData).owning_planet == planet_data:
			return active_components[data]
	return null


func has_planet_component(planet_data: PlanetData, target_id: StringName) -> bool:
	return get_planet_component(planet_data, target_id) != null
