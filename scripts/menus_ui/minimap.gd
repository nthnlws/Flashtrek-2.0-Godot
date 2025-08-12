extends Control

const OBJECT = preload("res://scenes/menus_ui/minimap_object.tscn")

var count:int = 0

var enemyShips: Array = []
var starbaseObjects: Array = []
var neutralShips: Array = []
var levelObjects: Array = []
var sunObjects: Array = []
var ship_to_object: Dictionary = {}  # Dictionary to map enemies to TextureRects
var player: Player

# Minimap scale values
var scale_values: Array[float] = [0.35, 0.5, 0.75, 1.0, 1.25, 1.5]
var current_index: int = 3  # Index of the current value in scale_values
var minimapScale = scale_values[current_index]  # Start at 1.0

var grid_scale: Vector2


func _ready() -> void:
	SignalBus.enemyShipDied.connect(remove_minimap_object)
	SignalBus.neutralShipDied.connect(remove_minimap_object)
	SignalBus.spawnShip.connect(spawn_ship.unbind(1))
	grid_scale = get_viewport().get_visible_rect().size / 2 # Var to center minimap objects
	
	player = LevelData.player
	
	create_minimap_objects()


func _process(delta: float) -> void:
	if !player: return
	
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


func spawn_ship():
	var new_obj = add_minimap_object()
	enemyShips.append(new_obj)
	new_obj.modulate = Color.RED # Red
	#ship_to_object[enemy] = new_obj  # Map enemy to TextureRect


func add_minimap_object():
	var new_obj = OBJECT.instantiate()
	new_obj.add_to_group("minimap_obj")
	add_child(new_obj)
	
	new_obj.modulate = Color.RED  # Default color
	
	return new_obj


func create_minimap_objects() -> void:
	clear_objects()
	for enemy:FactionCharacter in LevelData.enemyShips:
		if enemy:
			var new_obj = add_minimap_object()
			
			enemyShips.append(new_obj)
			new_obj.modulate = Color.RED # Red
			ship_to_object[enemy] = new_obj  # Map enemy to TextureRect
			count += 1
			
	for NPC:NeutralCharacter in LevelData.neutralShips:
		if NPC:
			var new_obj = add_minimap_object()
			
			neutralShips.append(new_obj)
			new_obj.modulate = Color.SPRING_GREEN # Red
			ship_to_object[NPC] = new_obj  # Map enemy to TextureRect
			count += 1
			
	for starbase:Node2D in LevelData.starbase:
		if starbase:
			var new_obj = add_minimap_object()
			
			new_obj.modulate = Color.WHITE
			starbaseObjects.append(new_obj)
			count += 1

	for planet:Node2D in LevelData.planets:
		if planet:
			var new_obj = add_minimap_object()
			
			new_obj.modulate = Color.SLATE_BLUE
			levelObjects.append(new_obj)
			count += 1
			
	for sun:Node2D in LevelData.suns:
		if sun:
			var new_obj = add_minimap_object()
			
			new_obj.modulate = Color.YELLOW
			sunObjects.append(new_obj)
			count += 1


func update_minimap() -> void:
	if enemyShips:
		count = 0
		for character:FactionCharacter in LevelData.enemyShips:
			var globalDistance:Vector2 = character.global_position - player.global_position
			enemyShips[count].position = (globalDistance/30 * minimapScale) + grid_scale
			count += 1
			if count == LevelData.enemyShips.size():
				count = 0
	
	if neutralShips:
		count = 0
		for character:NeutralCharacter in LevelData.neutralShips:
			var globalDistance:Vector2 = character.global_position - player.global_position
			neutralShips[count].position = (globalDistance/30 * minimapScale) + grid_scale
			count += 1
			if count == LevelData.neutralShips.size():
				count = 0
	
	if starbaseObjects:
		count = 0
		for starbase:Node2D in LevelData.starbase:
			var globalDistance:Vector2 = starbase.global_position - player.global_position
			starbaseObjects[count].position = (globalDistance/30 * minimapScale) + grid_scale
			count += 1
			if count == LevelData.starbase.size():
				count = 0

	if levelObjects:
		count = 0
		for planet:Node2D in LevelData.planets:
			var globalDistance:Vector2 = planet.global_position - player.global_position
			levelObjects[count].position = (globalDistance/30 * minimapScale) + grid_scale
			count += 1

	if sunObjects:
		count = 0
		for sun:Node2D in LevelData.suns:
			var globalDistance:Vector2 = sun.global_position - player.global_position
			sunObjects[count].position = (globalDistance/30 * minimapScale) + grid_scale
			count += 1


func remove_minimap_object(ship) -> void:
	if ship in ship_to_object:
		var texture_rect: TextureRect = ship_to_object[ship]
		self.remove_child(texture_rect)  # Remove the TextureRect from the minimap
		texture_rect.queue_free()  # Free the TextureRect
		enemyShips.erase(texture_rect)  # Remove from enemyShips array (if present)
		neutralShips.erase(texture_rect) # Remove from neutralShips array (if present)
		ship_to_object.erase(ship)  # Remove from the dictionary
	else:
		print("Ship not found in minimap objects")


func clear_objects() -> void:
	var old_objects: Array = enemyShips + neutralShips + starbaseObjects + levelObjects + sunObjects
	
	for obj in old_objects:
		if obj:
			obj.queue_free()
	
	enemyShips.clear()
	neutralShips.clear()
	starbaseObjects.clear()
	levelObjects.clear()
	sunObjects.clear()
