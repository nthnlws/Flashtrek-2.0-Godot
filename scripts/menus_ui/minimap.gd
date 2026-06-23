extends Control

const OBJECT:PackedScene = preload("res://scenes/menus_ui/minimap_object.tscn")

var count:int = 0

var factionShips: Array = []
var neutralShips: Array = []
var missionShips: Array = []
var planetObjects: Array = []
var starbaseObjects: Array = []
var containerObjects: Array = []
var sunObjects: Array = []
var ship_to_object: Dictionary = {}  # Maps ships to minimap objects
var container_to_object: Dictionary = {} # Maps containers to minimap objects

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
	SignalBus.spawnShip.connect(spawn_ship.unbind(1))
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


func spawn_ship() -> void:
	var new_obj = add_minimap_object()
	factionShips.append(new_obj)
	new_obj.modulate = Color.RED # Red
	#ship_to_object[enemy] = new_obj  # Map enemy to TextureRect


func add_minimap_object() -> TextureRect:
	var new_obj = OBJECT.instantiate()
	new_obj.add_to_group("minimap_obj")
	add_child(new_obj)
	
	new_obj.modulate = Color.RED  # Default color
	
	return new_obj


func create_minimap_objects() -> void:
	clear_objects()
	for enemy:FactionCharacter in LevelManager.factionShips:
		if enemy:
			var new_obj:TextureRect = add_minimap_object()
			
			factionShips.append(new_obj)
			new_obj.modulate = Color.RED
			ship_to_object[enemy] = new_obj  # Map enemy to TextureRect
	
	for NPC:NeutralCharacter in LevelManager.neutralShips:
		var new_obj:TextureRect = add_minimap_object()
		
		neutralShips.append(new_obj)
		new_obj.modulate = Color.SPRING_GREEN
		ship_to_object[NPC] = new_obj  # Map enemy to TextureRect

	for missions:MissionCharacter in LevelManager.missionShips:
		var new_obj:TextureRect = add_minimap_object()
		
		missionShips.append(new_obj)
		new_obj.modulate = Color.MAGENTA
		ship_to_object[missions] = new_obj  # Map ship to minimap object
			
	for starbase:Starbase in LevelManager.starbases:
		if starbase:
			var new_obj:TextureRect = add_minimap_object()
			
			new_obj.modulate = Color.WHITE
			starbaseObjects.append(new_obj)

	for planet:Planet in LevelManager.planets:
		if planet:
			var new_obj:TextureRect = add_minimap_object()
			planetObjects.append(new_obj)
			new_obj.modulate = Color.SLATE_BLUE

	if LevelManager.sun:
		var new_obj:TextureRect = add_minimap_object()
		
		new_obj.modulate = Color.YELLOW
		sunObjects.append(new_obj)
	
	for container:ContainerPickup in LevelManager.containers:
		if container:
			var new_obj:TextureRect = add_minimap_object()
			
			containerObjects.append(new_obj)
			new_obj.modulate = Color.MAGENTA
			container_to_object[container] = new_obj  # Map container to minimap object


func update_minimap() -> void:
	if factionShips:
		for i: int in range(factionShips.size()):
			var visual_marker:TextureRect = factionShips[i]
			
			# Check if a corresponding real ship exists for this index
			if i < LevelManager.factionShips.size():
				var real_ship: FactionCharacter = LevelManager.factionShips[i]
				
				var globalDistance: Vector2 = real_ship.global_position - LevelManager.player.global_position
				visual_marker.position = (globalDistance / 30 * minimapScale) + grid_scale
				visual_marker.visible = true
			else:
				# Hide unused markers
				visual_marker.visible = false
	
	if neutralShips:
		for i in range(neutralShips.size()):
			var visual_marker:TextureRect = neutralShips[i]
			
			# Check if a corresponding real ship exists for this index
			if i < LevelManager.neutralShips.size():
				var real_ship = LevelManager.neutralShips[i]
				
				var globalDistance = real_ship.global_position - LevelManager.player.global_position
				visual_marker.position = (globalDistance / 30 * minimapScale) + grid_scale
				visual_marker.visible = true
			else:
				# Hide unused markers
				visual_marker.visible = false
	
	if missionShips:
		for i in range(missionShips.size()):
			var visual_marker:TextureRect = missionShips[i]
			
			# Check if a corresponding real ship exists for this index
			if i < LevelManager.missionShips.size() and is_instance_valid(LevelManager.missionShips[i]):
				var real_ship = LevelManager.missionShips[i]
				
				var globalDistance = real_ship.global_position - LevelManager.player.global_position
				visual_marker.position = (globalDistance / 30 * minimapScale) + grid_scale
				visual_marker.visible = true
			else:
				# Hide unused markers
				visual_marker.visible = false

	if starbaseObjects:
		for i:int in range(LevelManager.starbases.size()):
			var globalDistance:Vector2 = LevelManager.starbases[i].global_position - LevelManager.player.global_position
			starbaseObjects[count].position = (globalDistance/30 * minimapScale) + grid_scale

	if planetObjects:
		for i:int in range(LevelManager.planets.size()):
			var globalDistance:Vector2 = LevelManager.planets[i].global_position - LevelManager.player.global_position
			planetObjects[i].position = (globalDistance/30 * minimapScale) + grid_scale

	if sunObjects:
		var globalDistance:Vector2 = LevelManager.sun.global_position - LevelManager.player.global_position
		sunObjects[0].position = (globalDistance / 30 * minimapScale) + grid_scale
	
	if containerObjects:
		for i:int in range(LevelManager.containers.size()):
			var globalDistance:Vector2 = LevelManager.containers[i].global_position - LevelManager.player.global_position
			containerObjects[i].position = (globalDistance/30 * minimapScale) + grid_scale


func remove_minimap_object(object) -> void:
	print(object.name)
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
		printerr("Could not find object in minimap mapping dictionaries")


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
