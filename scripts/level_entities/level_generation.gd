extends Node

@export_category("Level Entities")
@export var levelBorders: PackedScene
@export var Planet: PackedScene
@export var Starbase: PackedScene
@export var PlayerSpawnArea: PackedScene
@export var Sun: PackedScene
@export var Hostiles: PackedScene
@export var player: PackedScene

@export_category("Items")
@export var item_pickup: PackedScene


@onready var game: Node2D = $".."
@onready var pickups: Node = $item_pickups

var all_systems_data: Dictionary = {}

const MAX_LEVEL = 31  # Highest system level



func _ready() -> void:
	SignalBus.galaxy_warp_finished.connect(_change_system)
	SignalBus.playerDied.connect(_change_system.bind("Solarus"))
	SignalBus.enemyDied.connect(spawn_loot)
	
	instantiate_new_system_nodes() # Init spawn for all level nodes
	generate_system_info() # Generate info for all systems
	_change_system("Solarus") # Spawn planets and move to JSON data location


func spawn_loot(enemy:EnemyCharacter) -> void:
	var new_drop:UpgradePickup = item_pickup.instantiate()
	new_drop.global_position = enemy.global_position
	new_drop.scale = Vector2(1.25, 1.25)
	new_drop.upgrade_type = randi_range(0, UpgradePickup.MODULE_TYPES.size() - 1) # Pick random drop type
	pickups.call_deferred("add_child",new_drop)


func _instaniate_enemies() -> void:
	Utility.mainScene.enemies.clear()
	var planets = Utility.mainScene.planets
	for e in range(planets.size()):
		var randint: int = randi_range(-1000, 1000) # Spawn distance from planet
		var init_hostiles: CharacterBody2D = Hostiles.instantiate()
		
		init_hostiles.global_position = planets[e].global_position + Vector2(randint, randint)
		add_child(init_hostiles)
		init_hostiles.add_to_group("level_nodwes")
	
	
	
func _change_system(system) -> void:
	# Combining all planets into single array for new system spawning
	var all_planets: Array = Utility.mainScene.planets + Utility.mainScene.unused_planets
	Utility.mainScene.planets.clear()
	Utility.mainScene.unused_planets.clear()
	
	#Re-map planet array with correct count
	var planet_data: Array = all_systems_data.get(system).planet_data
	for p in planet_data.size(): # Sets planets to JSON data
		all_planets[p].global_position.x = planet_data[p].x
		all_planets[p].global_position.y = planet_data[p].y
		all_planets[p].sprite.frame = planet_data[p].frame
		all_planets[p].name = planet_data[p].name
		all_planets[p].set_label(planet_data[p].name)
		Utility.mainScene.planets.append(all_planets[p])
		Utility.mainScene.planets[p].planetFaction = all_systems_data.get(system).faction
	#print(Utility.mainScene.planets)
	if planet_data.size() < 6:
		for extra in 6 - planet_data.size():
			Utility.mainScene.unused_planets.append(all_planets.pop_back())
		for i in range(Utility.mainScene.unused_planets.size()):
			Utility.mainScene.unused_planets[i].global_position = Vector2(40000, 40000)
	#print(Utility.mainScene.unused_planets)
	
	
	var sun_data: Dictionary = all_systems_data.get(system).sun_data
	var sun: Node2D = Utility.mainScene.suns[0]
	sun.global_position.x = sun_data.x
	sun.global_position.y = sun_data.y
	sun.sprite.frame = sun_data.frame
	
	for enemy: CharacterBody2D in Utility.mainScene.enemies:
		enemy.queue_free()
		
	_instaniate_enemies()
	
	%MiniMap.create_minimap_objects() # Refresh minimap objects
	
	
func instantiate_new_system_nodes() -> void:
	var init_border: Node2D = levelBorders.instantiate()
	add_child(init_border)
	init_border.add_to_group("level_nodes")

	var init_sun: Node2D = Sun.instantiate()
	add_child(init_sun)
	init_sun.add_to_group("level_nodes")
	

	var init_starbase: Node2D = Starbase.instantiate()
	add_child(init_starbase)
	init_starbase.global_position = Vector2.ZERO
	init_starbase.add_to_group("level_nodes")
	

	var init_spawn: Area2D = PlayerSpawnArea.instantiate()
	add_child(init_spawn)
	init_spawn.add_to_group("level_nodes")
	init_spawn.add_to_group("player_spawn_area")
	

	for i in range(6): # Spawn 6 planets for use in level gen
		var init_planet: Node2D = Planet.instantiate()
		add_child(init_planet)
		init_planet.global_position = Vector2(40000, 40000) # Moves planets outside of level borders
		


	var init_player: Player = player.instantiate()
	add_child(init_player)
	init_player.add_to_group("level_nodes")
	
func generate_system_info() -> void:
	var system_num: int = 1
	
	while system_num <= MAX_LEVEL:
		var system_data: Dictionary = generate_system_variables(system_num)
		all_systems_data[str(system_num)] = system_data
		system_num += 1
	
	var solarus_data: Dictionary = generate_system_variables("Solarus")
	all_systems_data["Solarus"] = solarus_data # Use the name as the key

	var kronos_data: Dictionary = generate_system_variables("Kronos")
	all_systems_data["Kronos"] = kronos_data

	var romulus_data: Dictionary = generate_system_variables("Romulus")
	all_systems_data["Romulus"] = romulus_data
	
	Utility.store_level_data(all_systems_data)
	Navigation.all_systems_data = all_systems_data
	Navigation.systems = all_systems_data.keys()

func generate_system_variables(system_number) -> Dictionary:
	var faction
	if typeof(system_number) == TYPE_STRING:
		match system_number:
			"Solarus":
				system_number = 10
				faction = Utility.FACTION.FEDERATION
			"Kronos":
				system_number = 20
				faction = Utility.FACTION.KLINGON
			"Romulus":
				system_number = 28
				faction = Utility.FACTION.ROMULAN
			"Neutral":
				faction = Utility.FACTION.NEUTRAL
				system_number = 15
	else:
		faction = Navigation.get_faction_for_system(system_number)
		system_number = int(system_number)
	
	# Health Scaling
	var enemy_health_mult: float = 1
	var health_scaling_rate: float = 1.0/30.0
	
	# Damage Scaling
	var enemy_damage_mult: float = 1
	var damage_scaling_rate: float = 1.0/30.0
	if system_number <= 30:
		enemy_health_mult = snapped(1 + (system_number * health_scaling_rate), 0.01)
		enemy_damage_mult = snapped(1 + (system_number * damage_scaling_rate), 0.01)
	else: 
		enemy_health_mult = 2.0 # Default double scaling above system 30
		enemy_damage_mult = 2.0
	
	# Random planet count
	var planet_count: int = randi_range(3, 6)
	var planet_data: Array = generate_planet_data(planet_count)
	var sun_data: Dictionary = generate_sun_data()
	
	return {
		"faction": faction,
		"planet_data": planet_data,
		"sun_data": sun_data,
		"enemy_health_mult": enemy_health_mult,
		"enemy_damage_mult": enemy_damage_mult,
		"system_size": 20000,
		#"enemies": "BLANK",
		#"enemy_types": enemy_types,
	}


func generate_sun_data() -> Dictionary:
	var spawnDistance: int = 8000
	var spawnVariability: int = 500
	
	spawnDistance = randi() % (2 * spawnVariability + 1) - spawnVariability + spawnDistance
	
	var random_index: int = randi_range(0, 5)
	
	var angle: float = randf_range(0, TAU) # 0-360 degrees
	var sun_position: Vector2 = Vector2(cos(angle), sin(angle)) * spawnDistance
	
	var sun_data: Dictionary = {
		"frame": random_index,
		"x": int(sun_position.x),
		"y": int(sun_position.y),
	}
	
	return sun_data
	
	
func generate_planet_data(PLANET_COUNT: int) -> Array:
	var min_dist_between: float = clamp(20000.0 / PLANET_COUNT, 6000.0, 20000.0)
	var max_dist_origin: float = 15000.0 + ((PLANET_COUNT - 3.0) * 750.0)
	var min_dist_origin: float = clamp(7500.0 + ((PLANET_COUNT - 3.0) * 750.0), 7500.0, 10000.0)

	var all_planets_data: Array = []
	var placed_positions: Array[Vector2] = [] # Store positions placed *in this run*

	for i in range(PLANET_COUNT):
		# Pass the list of already placed positions to the validation function
		var position: Vector2 = get_valid_position(min_dist_origin, max_dist_origin, min_dist_between, placed_positions)

		# Check if get_valid_position failed
		if position == Vector2.ZERO:
			push_warning("Failed to place planet %d. Stopping generation for this system." % (i + 1))
			return all_planets_data # Return what we have so far

		# If successful, add the new position to the tracking list for the next iteration
		placed_positions.append(position)

		var random_frame: int = randi() % 220
		var planet_name: String = Navigation.planet_names.pop_at(randi() % Navigation.planet_names.size())

		# Create the DICTIONARY for the current planet
		var current_planet_dict: Dictionary = {
			"name": planet_name,
			"frame": random_frame,
			"x": int(position.x),
			"y": int(position.y),
		}

		# Add the dictionary for this planet to the main array
		all_planets_data.append(current_planet_dict)

	# Return the completed array of planet dictionaries
	return all_planets_data
	
	
func get_valid_position(
		min_distance_from_origin: float,
		max_distance_from_origin: float,
		min_distance_between_planets: float,
		existing_positions: Array[Vector2]
	) -> Vector2:

	const max_attempts: int = 500
	var attempt: int = 0

	while attempt < max_attempts:
		attempt += 1
		var min_dist_sq:float = min_distance_from_origin * min_distance_from_origin
		var max_dist_sq:float = max_distance_from_origin * max_distance_from_origin
		var distance_sq:float = randf_range(min_dist_sq, max_dist_sq)
		var distance:float = sqrt(distance_sq)

		var angle: float = randf_range(0, TAU) # TAU = 2 * PI

		# Calculate the potential position
		var potential_position: Vector2 = Vector2(cos(angle), sin(angle)) * distance

		# Check if the position is far enough from other planets
		var is_valid: bool = true
		
		var min_dist_sq_check = min_distance_between_planets * min_distance_between_planets
		for existing_pos in existing_positions: # Check against the passed list
			if potential_position.distance_squared_to(existing_pos) < min_dist_sq_check:
				is_valid = false
				break # No need to check further for this attempt

		# If valid, return the position immediately
		if is_valid:
			return potential_position

	# If the loop finishes without finding a valid position
	push_warning("Get_valid_position failed after %d attempts." % max_attempts)
	return Vector2.ZERO # Return Vector2.ZERO to indicate failure
