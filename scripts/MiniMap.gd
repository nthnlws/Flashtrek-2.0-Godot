extends Control

@export var enemy_texture = preload("res://assets/textures/Minimap/enemy_mini.png")
@export var starbase_texture = preload("res://assets/textures/Minimap/starbase_mini.png")
@export var planet_texture = preload("res://assets/textures/Minimap/planet_mini.png")
@export var sun_texture = preload("res://assets/textures/Minimap/sun_mini.png")


var count:int = 0

var enemyObjects = []
var starbaseObjects = []
var neutralObjects = []
var sunObjects = []
var enemy_to_texture = {}  # Dictionary to map enemies to TextureRects
var player

# Minimap scale values
var scale_values = [0.35, 0.5, 0.75, 1.0, 1.25, 1.5]
var current_index = 3  # Index of the current value in scale_values
var minimapScale = scale_values[current_index]  # Start at 1.0
	


var grid_scale

func _ready():
	SignalBus.enemyDied.connect(remove_minimap_object)
	grid_scale = get_viewport().get_visible_rect().size/2 # Var to center minimap objects
	
	player = Utility.mainScene.player[0]
	
	create_minimap_objects()
	
func _process(delta):
	if !player: return
	
	update_minimap()
	
func _input(event):
	if event.is_action_pressed("letter_e"):
		if current_index < scale_values.size() - 1:
			current_index += 1
			minimapScale = scale_values[current_index]

	elif event.is_action_pressed("letter_q"):
		if current_index > 0:
			current_index -= 1
			minimapScale = scale_values[current_index]
			
	if Input.is_action_pressed("zoom_out"):
		scale_minimap("OUT")

	if Input.is_action_pressed("zoom_in"):
		scale_minimap("IN")
		
		
func scale_minimap(direction):
	var minimap_nodes = get_tree().get_nodes_in_group("minimap_obj")
	for node in minimap_nodes:
		if direction == "OUT":
			node.scale = clamp(Vector2(node.scale.x * 0.9, node.scale.y * 0.9), Vector2(0.5, 0.5), Vector2(1.0, 1.0))
		elif direction == "IN":
			node.scale = clamp(Vector2(node.scale.x / 0.9, node.scale.y / 0.9), Vector2(0.5, 0.5), Vector2(1.0, 1.0))


func create_minimap_objects():
	for enemy in Utility.mainScene.enemies:
		if enemy:
			var texture_rect = TextureRect.new()
			texture_rect.texture = enemy_texture
			texture_rect.size = Vector2(5, 5)
			texture_rect.layout_mode = 1 # Sets to Anchors
			texture_rect.anchors_preset = 8 # Set anchor to center
			texture_rect.add_to_group("minimap_obj")
			
			self.add_child(texture_rect)
			enemyObjects.append(texture_rect)
			enemy_to_texture[enemy] = texture_rect  # Map enemy to TextureRect
			count += 1
			
	for starbase in Utility.mainScene.starbase:
		if starbase:
			var texture_rect = TextureRect.new()
			texture_rect.texture = starbase_texture
			texture_rect.size = Vector2(7, 7)
			texture_rect.layout_mode = 1 # Sets to Anchors
			texture_rect.anchors_preset = 8 # Set anchor to center
			texture_rect.add_to_group("minimap_obj")
			
			self.add_child(texture_rect)
			starbaseObjects.append(texture_rect)
			count += 1

	for planet in Utility.mainScene.planets:
		if planet:
			var texture_rect = TextureRect.new()
			texture_rect.texture = planet_texture
			texture_rect.size = Vector2(7, 7)
			texture_rect.layout_mode = 1 # Sets to Anchors
			texture_rect.anchors_preset = 8 # Set anchor to center
			texture_rect.add_to_group("minimap_obj")
			
			self.add_child(texture_rect)
			neutralObjects.append(texture_rect)
			count += 1
			
	for sun in Utility.mainScene.suns:
		if sun:
			var texture_rect = TextureRect.new()
			texture_rect.texture = sun_texture
			texture_rect.size = Vector2(5, 5)
			texture_rect.scale = Vector2(0.75, 0.75)
			texture_rect.layout_mode = 1 # Sets to Anchors
			texture_rect.anchors_preset = 8 # Set anchor to center
			texture_rect.add_to_group("minimap_obj")
			
			self.add_child(texture_rect)
			sunObjects.append(texture_rect)
			count += 1

func update_minimap():
	if enemyObjects:
		count = 0
		for character in Utility.mainScene.enemies:
			var globalDistance:Vector2 = character.global_position - player.global_position
			enemyObjects[count].position = (globalDistance/30 * minimapScale) + grid_scale
			enemyObjects[count].rotation = character.rotation
			count += 1
			if count == Utility.mainScene.enemies.size():
				count = 0

	if starbaseObjects:
		count = 0
		for starbase in Utility.mainScene.starbase:
			var globalDistance:Vector2 = starbase.global_position - player.global_position
			starbaseObjects[count].position = (globalDistance/30 * minimapScale) + grid_scale
			count += 1
			if count == Utility.mainScene.starbase.size():
				count = 0

	if neutralObjects:
		count = 0
		for planet in Utility.mainScene.planets:
			var globalDistance:Vector2 = planet.global_position - player.global_position
			neutralObjects[count].position = (globalDistance/30 * minimapScale) + grid_scale
			count += 1

	if sunObjects:
		count = 0
		for sun in Utility.mainScene.suns:
			var globalDistance:Vector2 = sun.global_position - player.global_position
			sunObjects[count].position = (globalDistance/30 * minimapScale) + grid_scale
			count += 1

func remove_minimap_object(enemy):
	if enemy in enemy_to_texture:
		var texture_rect = enemy_to_texture[enemy]
		self.remove_child(texture_rect)  # Remove the TextureRect from the minimap
		texture_rect.queue_free()  # Free the TextureRect
		enemyObjects.erase(texture_rect)  # Remove from enemyObjects array
		enemy_to_texture.erase(enemy)  # Remove from the dictionary
		#print("Removed minimap object for enemy: ", enemy)
	else:
		print("Enemy not found in minimap objects")
