extends Control

const OBJECT:PackedScene = preload("res://scenes/menus_ui/minimap_object.tscn")

var count:int = 0

var factionShips: Array = []
var starbaseObjects: Array = []
var neutralShips: Array = []
var levelObjects: Array = []
var sunObjects: Array = []
var ship_to_object: Dictionary = {}  # Dictionary to map enemies to TextureRects

# Minimap scale values
var scale_values: Array[float] = [0.35, 0.5, 0.75, 1.0, 1.25, 1.5]
var current_index: int = 3  # Index of the current value in scale_values
var minimapScale:float = scale_values[current_index]  # Start at 1.0

var grid_scale: Vector2


func _ready() -> void:
	SignalBus.factionShipDied.connect(remove_minimap_object)
	SignalBus.neutralShipDied.connect(remove_minimap_object)
	SignalBus.spawnShip.connect(spawn_ship.unbind(1))
	grid_scale = get_viewport().get_visible_rect().size / 2 # Var to center minimap objects


func _process(delta: float) -> void:
	if Navigation.in_galaxy_warp == false:
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
	#print("creating minimap objects")
	clear_objects()
	for enemy:FactionCharacter in LevelManager.factionShips:
		if enemy:
			var new_obj:TextureRect = add_minimap_object()
			
			factionShips.append(new_obj)
			new_obj.modulate = Color.RED # Red
			ship_to_object[enemy] = new_obj  # Map enemy to TextureRect
			count += 1
	
	for NPC:NeutralCharacter in LevelManager.neutralShips:
			var new_obj:TextureRect = add_minimap_object()
			
			neutralShips.append(new_obj)
			new_obj.modulate = Color.SPRING_GREEN # Red
			ship_to_object[NPC] = new_obj  # Map enemy to TextureRect
			count += 1
			
	for starbase:Starbase in LevelManager.starbases:
		if starbase:
			var new_obj:TextureRect = add_minimap_object()
			
			new_obj.modulate = Color.WHITE
			starbaseObjects.append(new_obj)
			count += 1

	for planet:Planet in LevelManager.planets:
		if planet:
			var new_obj:TextureRect = add_minimap_object()
			
			new_obj.modulate = Color.SLATE_BLUE
			levelObjects.append(new_obj)
			count += 1
			
	if LevelManager.sun:
		var new_obj:TextureRect = add_minimap_object()
		
		new_obj.modulate = Color.YELLOW
		sunObjects.append(new_obj)
		count += 1


func update_minimap() -> void:
	if factionShips:
		count = 0
		for character:FactionCharacter in LevelManager.factionShips:
			var globalDistance:Vector2 = character.global_position - LevelManager.player.global_position
			factionShips[count].position = (globalDistance/30 * minimapScale) + grid_scale
			count += 1
			if count == LevelManager.factionShips.size():
				count = 0
	
	if neutralShips:
		count = 0
		for character:NeutralCharacter in LevelManager.neutralShips:
			var globalDistance:Vector2 = character.global_position - LevelManager.player.global_position
			neutralShips[count].position = (globalDistance/30 * minimapScale) + grid_scale
			count += 1
			if count == LevelManager.neutralShips.size():
				count = 0
	
	if starbaseObjects:
		count = 0
		for starbase:Node2D in LevelManager.starbases:
			var globalDistance:Vector2 = starbase.global_position - LevelManager.player.global_position
			starbaseObjects[count].position = (globalDistance/30 * minimapScale) + grid_scale
			count += 1
			if count == LevelManager.starbases.size():
				count = 0

	if levelObjects:
		count = 0
		for planet:Node2D in LevelManager.planets:
			var globalDistance:Vector2 = planet.global_position - LevelManager.player.global_position
			levelObjects[count].position = (globalDistance/30 * minimapScale) + grid_scale
			count += 1

	if sunObjects:
		var globalDistance:Vector2 = LevelManager.sun.global_position - LevelManager.player.global_position
		sunObjects[0].position = (globalDistance / 30 * minimapScale) + grid_scale


func remove_minimap_object(ship) -> void:
	if ship in ship_to_object:
		var texture_rect: TextureRect = ship_to_object[ship]
		self.remove_child(texture_rect)  # Remove the TextureRect from the minimap
		texture_rect.queue_free()  # Free the TextureRect
		factionShips.erase(texture_rect)  # Remove from factionShips array
		neutralShips.erase(texture_rect) # Remove from neutralShips array
		ship_to_object.erase(ship)  # Remove from the dictionary
	else:
		printerr("Could not remove ship from minimap objects, not found")


func clear_objects() -> void:
	var old_objects: Array = factionShips + neutralShips + starbaseObjects + levelObjects + sunObjects
	
	for obj in old_objects:
		if obj:
			obj.queue_free()
	
	factionShips.clear()
	neutralShips.clear()
	starbaseObjects.clear()
	levelObjects.clear()
	sunObjects.clear()
