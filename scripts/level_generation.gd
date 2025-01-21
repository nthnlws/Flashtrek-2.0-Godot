extends Node

@export var levelBorders: PackedScene
@export var Planets: PackedScene
@export var Starbase: PackedScene
@export var PlayerSpawnArea: PackedScene
@export var Sun: PackedScene
@export var Hostiles: PackedScene
@export var Player: PackedScene

@onready var init_nodes: Array = [levelBorders, Planets, Starbase, PlayerSpawnArea, Sun, Hostiles, Player]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Utility.is_initial_load:
		new_game_gen()
	

func new_game_gen():
	var init_border = levelBorders.instantiate()
	add_child(init_border)
	init_border.add_to_group("level_nodes")
	
	var init_planets = Planets.instantiate()
	add_child(init_planets)
	init_planets.add_to_group("level_nodes")
	
	var init_sun = Sun.instantiate()
	add_child(init_sun)
	init_sun.add_to_group("level_nodes")
	
	var init_starbase = Starbase.instantiate()
	add_child(init_starbase)
	init_starbase.add_to_group("level_nodes")
	
	var init_spawn = PlayerSpawnArea.instantiate()
	add_child(init_spawn)
	init_spawn.add_to_group("level_nodes")
	
	var init_hostiles = Hostiles.instantiate()
	add_child(init_hostiles)
	init_hostiles.add_to_group("level_nodes")
	
	var init_player = Player.instantiate()
	add_child(init_player)
	init_player.add_to_group("level_nodes")
	
func new_system_gen():
	for node in get_tree().get_nodes_in_group("level_nodes"):
		node.queue_free()
		
	
	var file_path = "user://level_data.json"
	
	# Initialize the save_data dictionary
	var save_data = {}
	
# Check if the file exists and load existing data if it does
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		save_data = JSON.parse_string(file.get_as_text())
		file.close()
	
	var init_border = levelBorders.instantiate()
	add_child(init_border)
	init_border.add_to_group("level_nodes")
	
	var init_planets = Planets.instantiate()
	add_child(init_planets)
	init_planets.add_to_group("level_nodes")
	
	var init_sun = Sun.instantiate()
	add_child(init_sun)
	init_sun.add_to_group("level_nodes")
	
	var init_starbase = Starbase.instantiate()
	add_child(init_starbase)
	init_starbase.add_to_group("level_nodes")
	
	var init_spawn = PlayerSpawnArea.instantiate()
	add_child(init_spawn)
	init_spawn.add_to_group("level_nodes")
	
	var init_hostiles = Hostiles.instantiate()
	add_child(init_hostiles)
	init_hostiles.add_to_group("level_nodes")
	
	var init_player = Player.instantiate()
	add_child(init_player)
	init_player.add_to_group("level_nodes")
