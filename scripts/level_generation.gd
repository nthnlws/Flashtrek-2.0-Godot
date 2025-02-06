extends Node

@export var levelBorders: PackedScene
@export var Planets: PackedScene
@export var Starbase: PackedScene
@export var PlayerSpawnArea: PackedScene
@export var Sun: PackedScene
@export var Hostiles: PackedScene
@export var Player: PackedScene

@onready var init_nodes: Array = [levelBorders, Planets, Starbase, PlayerSpawnArea, Sun, Hostiles, Player]
@onready var game: Node2D = $".."


var system_vars

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#if Utility.is_initial_load:
		#new_game_gen()
	new_system_gen("Solarus")
	
	
	
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

func new_system_gen(system_num):
	var system_vars = generate_system_variables(system_num)
	
	Utility.current_system_faction = system_vars["faction"]
	print("Faction: " + str(Utility.current_system_faction))
	
	# Delete old level nodes
	for node in get_tree().get_nodes_in_group("level_nodes"):
		node.queue_free()
		
	# Initialize the save_data dictionary
	var file_path = "user://level_data.json"
	var save_data = {}
	
	# Check if the file exists and load existing data if it does
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		save_data = JSON.parse_string(file.get_as_text())
		file.close()
	
	var init_border = levelBorders.instantiate()
	add_child(init_border)
	init_border.add_to_group("level_nodes")
	
	generate_planets(system_num, save_data)
	
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



const SYSTEM_RANGES = {
	"Federation": {"range": {"min": 1, "max": 16}},
	"Klingon": {"range": {"min": 17, "max": 24}},
	"Romulan": {"range": {"min": 25, "max": 31}},
}

var fed_min = SYSTEM_RANGES["Federation"]["range"]["min"]
var fed_max = SYSTEM_RANGES["Federation"]["range"]["max"]
var kling_min = SYSTEM_RANGES["Klingon"]["range"]["min"]
var kling_max = SYSTEM_RANGES["Klingon"]["range"]["max"]
var rom_min = SYSTEM_RANGES["Romulan"]["range"]["min"]

const MAX_LEVEL = 31  # Highest system level

func generate_system_variables(system_number) -> Dictionary:
	var faction_name
	if system_number.length() > 2:
		match system_number:
			"Solarus":
				system_number = 10
				faction_name = Utility.FACTION.FEDERATION
			"Kronos":
				system_number = 20
				faction_name = Utility.FACTION.KLINGON
			"Romulus":
				system_number = 28
				faction_name = Utility.FACTION.ROMULAN
			"Neutral":
				faction_name = Utility.FACTION.NEUTRAL
				system_number = 15
	else:
		faction_name = get_faction_for_system(system_number)
		system_number = int(system_number)
		
		
	#if faction_name == "":
		#print("Invalid System Name")
		#return {}  # Invalid system number
	
	# Health Scaling
	var enemy_health_mult = 1
	var health_scaling_rate = 1/30
	if system_number <= 30:
		enemy_health_mult = 1 + (system_number * health_scaling_rate)
	else: enemy_health_mult = 2.0
	
	# Damage Scaling
	var enemy_damage_mult = 1
	var damage_scaling_rate = 1/30
	if system_number <= 30:
		enemy_damage_mult = 1 + (system_number * damage_scaling_rate)
	else: enemy_damage_mult = 2.0
	
	# Randomly generate enemy types
	#var enemy_types = generate_enemy_types(position_in_range)  # Generate enemy types
	
	return {
		"faction": faction_name,
		"system_number": system_number,
		"enemy_health_mult": enemy_health_mult,
		"enemy_damage_mult": enemy_damage_mult
		#"enemy_types": enemy_types,
	}

func get_faction_for_system(system_number) -> String:
	system_number = int(system_number)
	if system_number <= fed_max:
		return "Federation"
	elif system_number >= kling_min and system_number <= kling_max:
		return "Klingon"
	elif system_number >= rom_min:
		return "Romulan"
	else:
		print("System out of range, error")
		return ""
			

#func generate_enemy_types(position_in_range: int) -> Array:
	#var types = []
	#var num_types = randi_range(1, 3)  # Randomize number of enemy types
	#for _ in range(num_types):
		#var level = position_in_range + 1
		#types.append({"type": "EnemyType" + str(randi_range(1, 5)), "level": level})
	#return types

func generate_planets(system_num:String, save_data:Dictionary):
	var init_planets = Planets.instantiate()
	if not save_data.has(system_num) or save_data == null:
		init_planets.PLANET_COUNT = randi_range(3, 6)
		add_child(init_planets)
		print("no data")
	if save_data.has(system_num):
		print("save data")
		init_planets.PLANET_COUNT = save_data[system_num]["planet_count"]
		
		var system_data = save_data[system_num]
		var i = 0
		add_child(init_planets)
		for plan in init_planets.get_children():
			var saved_planet_positions = system_data["planet_data"][i]
			plan.global_position.x = saved_planet_positions["x"]
			plan.global_position.y = saved_planet_positions["y"]
			plan.get_node("PlanetTexture").frame = saved_planet_positions["frame"]
			i += 1
			# Setting planet pos to save file
			#print("Set Value x: " + str(plan.global_position.x))
