extends Control

const OBJECT:PackedScene = preload("res://scenes/menus_ui/minimap_object.tscn")

var count:int = 0

var factionShips: Array[TextureRect]
var neutralShips: Array[TextureRect]
var missionShips: Array[TextureRect]
var planetObjects: Array[TextureRect]
var starbaseObjects: Array[TextureRect]
var containerObjects: Array[TextureRect]
var sunObjects: Array
var ship_to_object: Dictionary
var container_to_object: Dictionary

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


func add_minimap_object(color: Color) -> TextureRect:
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
		sunObjects.append(add_minimap_object(Color.YELLOW))

func _create_marker_group(entities: Array, markers: Array, color: Color, dict_map: Variant = null) -> void:
	for entity in entities:
		# is_instance_valid acts as a safer version of your previous "if enemy:" checks
		if is_instance_valid(entity):
			var new_obj: TextureRect = add_minimap_object(color)
			markers.append(new_obj)
			
			# If a dictionary was passed in, map the entity to its minimap object
			if dict_map != null:
				dict_map[entity] = new_obj


func update_minimap() -> void:
	# Cache player position once per frame to avoid redundant lookups
	if not is_instance_valid(LevelManager.player):
		return
	var player_pos: Vector2 = LevelManager.player.global_position

	# Update all array-based markers
	_update_marker_group(factionShips, LevelManager.factionShips, player_pos)
	_update_marker_group(neutralShips, LevelManager.neutralShips, player_pos)
	_update_marker_group(missionShips, LevelManager.missionShips, player_pos)
	_update_marker_group(starbaseObjects, LevelManager.starbases, player_pos)
	_update_marker_group(planetObjects, LevelManager.planets, player_pos)
	_update_marker_group(containerObjects, LevelManager.containers, player_pos)

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

func _get_minimap_pos(target_pos: Vector2, player_pos: Vector2) -> Vector2:
	return ((target_pos - player_pos) / 30.0 * minimapScale) + grid_scale


func remove_minimap_object(object: Variant) -> void:
	if object in ship_to_object:
		var texture_rect: TextureRect = ship_to_object[object]
		self.remove_child(texture_rect)  # Remove the TextureRect from the minimap
		texture_rect.queue_free()  # Free the minimap object
		factionShips.erase(texture_rect)  # Remove from factionShips array
		neutralShips.erase(texture_rect) # Remove from neutralShips array
		missionShips.erase(texture_rect) # Remove from missionShips array
		ship_to_object.erase(object)  # Remove from the mapping dictionary
	if object in container_to_object:
		var texture_rect: TextureRect = container_to_object[object]
		self.remove_child(texture_rect)  # Remove the TextureRect from the minimap
		texture_rect.queue_free()  # Free the minimap object
		containerObjects.erase(texture_rect)
		ship_to_object.erase(object)  # Remove from the mapping dictionary
	else:
		printerr("Could not find %s in minimap mapping dictionaries" % object.name)


func clear_objects() -> void:
	var old_objects: Array = factionShips + neutralShips + starbaseObjects + planetObjects + sunObjects + missionShips + containerObjects
	
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
