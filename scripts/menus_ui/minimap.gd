extends Control

const OBJECT:PackedScene = preload("res://scenes/menus_ui/minimap_object.tscn")

var count:int = 0
enum OBJECT_TYPE { FACTION, NEUTRAL, MISSION_OBJECTIVE, SUN, PLANET, STARBASE }

var factionShips: Array[TextureRect]
var neutralShips: Array[TextureRect]
var missionShips: Array[TextureRect]
var planetObjects: Array[TextureRect]
var starbaseObjects: Array[TextureRect]
var containerObjects: Array[TextureRect]
var missionObjects: Array[TextureRect]
## Debug builds only - one per ScrapComponent field.
var scrapObjects: Array[TextureRect]
var sunObjects: Array
var ship_to_object: Dictionary
var container_to_object: Dictionary
## Mission objective node (indicator, salvage, target planet) -> marker.
var mission_to_object: Dictionary
## ScrapComponent node -> marker.
var scrap_to_object: Dictionary

# Minimap scale values
var scale_values: Array[float] = [0.35, 0.5, 0.75, 1.0, 1.25, 1.5]
var current_index: int = 3  # Index of the current value in scale_values
var minimapScale:float = scale_values[current_index]  # Start at 1.0

var grid_scale: Vector2


func _ready() -> void:
	SignalBus.factionShipDied.connect(remove_minimap_object)
	SignalBus.neutralShipDied.connect(remove_minimap_object)
	SignalBus.containerPickedUp.connect(remove_minimap_object)
	SignalBus.missionCharacterDied.connect(remove_minimap_object)
	SignalBus.galaxy_warp_finished.connect(create_minimap_objects.unbind(1))
	# A component injected into the currently-loaded system (e.g. a debug-
	# added component, or a mission accepted for the system you're already
	# in) spawns its ships/containers outside the normal system_changed
	# flow this minimap otherwise relies on, so it needs telling directly.
	SignalBus.component_injected.connect(create_minimap_objects.unbind(1))
	MissionManager.mission_started.connect(create_minimap_objects.unbind(1))
	MissionManager.mission_updated.connect(create_minimap_objects.unbind(1))
	MissionManager.mission_completed.connect(create_minimap_objects.unbind(1))
	MissionManager.mission_failed.connect(create_minimap_objects.unbind(1))
	grid_scale = get_viewport().get_visible_rect().size / 2 # Var to center minimap objects


func _process(delta: float) -> void:
	if Utility.current_gamestate != Utility.GAMESTATE.WARPING:
		update_minimap()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("letter_e"):
		if current_index < scale_values.size() - 1:
			current_index += 1
			minimapScale = scale_values[current_index]

	elif event.is_action_pressed("letter_q"):
		if current_index > 0:
			current_index -= 1
			minimapScale = scale_values[current_index]


func create_minimap_texture(color: Color) -> TextureRect:
	var new_obj = OBJECT.instantiate()
	new_obj.modulate = color
	new_obj.add_to_group("minimap_obj")
	add_child(new_obj)
	
	return new_obj


func create_minimap_objects() -> void:
	clear_objects()
	
	# Create marker groups with dictionary mapping
	_create_marker_group(LevelManager.factionShips, factionShips, Color.RED, ship_to_object)
	_create_marker_group(LevelManager.neutralShips, neutralShips, Color.SPRING_GREEN, ship_to_object)
	_create_marker_group(LevelManager.missionShips, missionShips, Color.MAGENTA, ship_to_object)
	_create_marker_group(LevelManager.containers, containerObjects, Color.MAGENTA, container_to_object)
	
	# Create marker groups without dictionary mapping
	_create_marker_group(LevelManager.starbases, starbaseObjects, Color.WHITE)
	_create_marker_group(LevelManager.planets, planetObjects, Color.SLATE_BLUE)

	# Handle single objects (Sun)
	if is_instance_valid(LevelManager.sun):
		sunObjects.append(create_minimap_texture(Color.YELLOW))

	# Debug-only: ambient scrap fields
	if OS.is_debug_build():
		_create_marker_group(get_tree().get_nodes_in_group(ScrapComponent.MINIMAP_GROUP), scrapObjects, Color.WHITE, scrap_to_object)

	# Created last so they draw over planet markers
	_create_marker_group(_get_mission_objectives(), missionObjects, Color.MAGENTA, mission_to_object)


## Grouped objective nodes, plus the active mission's target planet (or turn-in
## starbase) when in its system.
func _get_mission_objectives() -> Array[Node2D]:
	var objectives: Array[Node2D] = []
	for node: Node in get_tree().get_nodes_in_group(MissionManager.MINIMAP_MARKER_GROUP):
		if node is Node2D and not node.is_queued_for_deletion():
			objectives.append(node)

	var mission: MissionData = MissionManager.active_mission
	if mission and mission.uses_target_planet() and mission.target_system == LevelManager.current_system_data:
		for planet: Planet in LevelManager.planets:
			if is_instance_valid(planet) and planet.planet_data.name == mission.target_planet_name:
				objectives.append(planet)
	# Turn-in point: the starbase marker goes purple once objectives are done
	if mission and mission.awaiting_turn_in and mission.target_system == LevelManager.current_system_data:
		for starbase: Starbase in LevelManager.starbases:
			if is_instance_valid(starbase):
				objectives.append(starbase)
	return objectives

func _create_marker_group(entities: Array, markers: Array, color: Color, dict_map: Variant = null) -> void:
	for entity in entities:
		# is_instance_valid acts as a safer version of your previous "if enemy:" checks
		if is_instance_valid(entity):
			var new_obj: TextureRect = create_minimap_texture(color)
			markers.append(new_obj)
			
			# If a dictionary was passed in, map the entity to its minimap object
			if dict_map != null:
				dict_map[entity] = new_obj


func update_minimap() -> void:
	# Cache player position once per frame to avoid redundant lookups
	if not is_instance_valid(LevelManager.player):
		return
	var player_pos: Vector2 = LevelManager.player.global_position

	# Ships and containers can be added mid-system (component injection),
	# which appends to LevelManager's arrays without necessarily rebuilding
	# every marker in lockstep - so their markers are updated by looking each
	# entity's marker up in its mapping dictionary directly, rather than by
	# assuming markers[i] still corresponds to entities[i].
	_update_marker_dict(ship_to_object, player_pos)
	_update_marker_dict(container_to_object, player_pos)
	_update_marker_dict(scrap_to_object, player_pos)
	_update_mission_markers(player_pos)

	# Starbases/planets never change after the initial system-load rebuild
	# and have no per-entity removal signal, so plain index correspondence
	# is safe for them.
	_update_marker_group(starbaseObjects, LevelManager.starbases, player_pos)
	_update_marker_group(planetObjects, LevelManager.planets, player_pos)

	# Update single objects (Sun)
	if sunObjects and not sunObjects.is_empty() and is_instance_valid(LevelManager.sun):
		sunObjects[0].position = _get_minimap_pos(LevelManager.sun.global_position, player_pos)

# Helper Functions for minimap updates
func _update_marker_group(markers: Array, entities: Array, player_pos: Vector2) -> void:
	if not markers:
		return

	for i in range(markers.size()):
		var marker: TextureRect = markers[i]

		# Ensures the entity exists, the index is in bounds, and the node hasn't been freed
		if i < entities.size() and is_instance_valid(entities[i]):
			marker.position = _get_minimap_pos(entities[i].global_position, player_pos)
			marker.visible = true
		else:
			marker.visible = false


## Position-updates every entity->marker mapping directly from the dictionary,
## so a marker is always tied to its actual entity regardless of array order
## or how many entities were added since the marker was created.
func _update_marker_dict(dict_map: Dictionary, player_pos: Vector2) -> void:
	for entity in dict_map:
		var marker: TextureRect = dict_map[entity]
		if not is_instance_valid(marker):
			continue
		if is_instance_valid(entity):
			marker.position = _get_minimap_pos(entity.global_position, player_pos)
			marker.visible = true
		else:
			marker.visible = false

## Objectives are freed without a signal (calibrated buoys, collected salvage),
## so their markers are removed once the node is gone.
func _update_mission_markers(player_pos: Vector2) -> void:
	for objective: Variant in mission_to_object.keys():
		var marker: TextureRect = mission_to_object[objective]
		if is_instance_valid(objective) and not objective.is_queued_for_deletion():
			marker.position = _get_minimap_pos(objective.global_position, player_pos)
		else:
			mission_to_object.erase(objective)
			missionObjects.erase(marker)
			marker.queue_free()


func _get_minimap_pos(target_pos: Vector2, player_pos: Vector2) -> Vector2:
	return ((target_pos - player_pos) / 30.0 * minimapScale) + grid_scale


func remove_minimap_object(object: Variant) -> void:
	var found: bool = false

	if object in ship_to_object:
		found = true
		var texture_rect: TextureRect = ship_to_object[object]
		self.remove_child(texture_rect)  # Remove the TextureRect from the minimap
		texture_rect.queue_free()  # Free the minimap object
		factionShips.erase(texture_rect)  # Remove from factionShips array
		neutralShips.erase(texture_rect) # Remove from neutralShips array
		missionShips.erase(texture_rect) # Remove from missionShips array
		ship_to_object.erase(object)  # Remove from the mapping dictionary

	if object in container_to_object:
		found = true
		var texture_rect: TextureRect = container_to_object[object]
		self.remove_child(texture_rect)  # Remove the TextureRect from the minimap
		texture_rect.queue_free()  # Free the minimap object
		containerObjects.erase(texture_rect)
		container_to_object.erase(object)  # Remove from the mapping dictionary

	if not found:
		printerr("Could not find %s in minimap mapping dictionaries" % object.name)


func clear_objects() -> void:
	var old_objects: Array = factionShips + neutralShips + starbaseObjects + planetObjects + sunObjects + missionShips + containerObjects + missionObjects + scrapObjects
	
	for obj in old_objects:
		if obj:
			obj.queue_free()
	
	factionShips.clear()
	neutralShips.clear()
	missionShips.clear()
	starbaseObjects.clear()
	planetObjects.clear()
	sunObjects.clear()
	containerObjects.clear()
	missionObjects.clear()
	scrapObjects.clear()

	# The mapping dictionaries must be rebuilt in lockstep with the arrays
	# above - clearing only the arrays left stale entity->marker entries
	# (pointing at already-freed markers) behind on every rebuild.
	ship_to_object.clear()
	container_to_object.clear()
	mission_to_object.clear()
	scrap_to_object.clear()
