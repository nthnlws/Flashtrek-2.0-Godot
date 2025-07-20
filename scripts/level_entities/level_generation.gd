extends Node

@export_category("Level Entities")
@export var levelBorders: PackedScene
@export var Planet: PackedScene
@export var Starbase: PackedScene
@export var PlayerSpawnArea: PackedScene
@export var Sun: PackedScene
@export var EnemyShip: PackedScene
@export var NeutralShip: PackedScene
@export var Player: PackedScene

@export_category("Items")
@export var item_pickup: PackedScene

@onready var game: Node2D = $".."
@onready var pickups: Node = $item_pickups

var all_systems_data: Dictionary = {}

const MAX_LEVEL = 31  # Highest system level


func _ready() -> void:
	Console.pause_enabled = true
	Console.add_command(
		"upgrade", # Command name
		spawn_loot_command, # Function call
		["type"], # Argument params
		1, # Required params
		"Spawns a damage upgrade on the player", # Description
		)
	Console.add_command_autocomplete_list("upgrade", UpgradePickup.MODULE_TYPES.keys())
	
	SignalBus.galaxy_warp_finished.connect(_change_system)
	SignalBus.playerDied.connect(_change_system.bind("Solarus"))
	SignalBus.spawnLoot.connect(spawn_loot)
	
	instantiate_new_system_nodes() # Init spawn for all level nodes
	generate_system_info() # Generate info for all systems
	_change_system("Solarus") # Spawn planets and move to JSON data location


func spawn_loot_command(type_str: String) -> void:
	type_str = type_str.to_upper()
	var type:int = UpgradePickup.MODULE_TYPES[type_str]
	var position: Vector2 = Utility.mainScene.player.global_position
	spawn_loot(type, position)

func spawn_loot(type:UpgradePickup.MODULE_TYPES, position:Vector2) -> void:
	print(str(type) + str(position))
	var new_drop:UpgradePickup = item_pickup.instantiate()
	new_drop.global_position = position
	new_drop.scale = Vector2(1.25, 1.25)
	new_drop.upgrade_type = type
	pickups.call_deferred("add_child",new_drop)


func _instaniate_ships(PLANET_COUNT:int) -> void:
	Utility.mainScene.enemyShips.clear()
	var planets = Utility.mainScene.planets
	for e:int in range(planets.size()):
		var max_spawn_distance: int = 1500
		var min_spawn_distance: int = 500
		var random_angle: float = randf_range(0, TAU)
		var spawn_distance: float = randf_range(min_spawn_distance, max_spawn_distance)
		var spawn_position: Vector2 = Vector2.from_angle(random_angle) * spawn_distance
		
		var init_enemy: EnemyCharacter = EnemyShip.instantiate()
		init_enemy.global_position = planets[e].global_position + spawn_position
		add_child(init_enemy)
		init_enemy.add_to_group("level_nodes")
	
	Utility.mainScene.neutralShips.clear()
	for p: Node2D in planets:
		var init_neutral: NeutralCharacter = NeutralShip.instantiate()
		
		# 0.0 is at Vector2.ZERO, 1.0 is at the planet's position.
		var random_fraction: float = clamp(randf(),0.2, 0.8)
		var spawn_pos: Vector2 = Vector2.ZERO.lerp(p.global_position, random_fraction)

		init_neutral.global_position = spawn_pos
		add_child(init_neutral)
		init_neutral.add_to_group("level_nodes")


func _change_system(system) -> void:
	# Combining all planets into single array for new system spawning
	var all_planets: Array = Utility.mainScene.planets + Utility.mainScene.unused_planets
	# Clear old arrays
	Utility.mainScene.planets.clear()
	Utility.mainScene.unused_planets.clear()
	
	# Re-map planet array with correct count
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
	
	for ship: CharacterBody2D in Utility.mainScene.neutralShips + Utility.mainScene.enemyShips:
		ship.queue_free()
		
	_instaniate_ships(planet_data.size())
	
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

	var init_player: Player = Player.instantiate()
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
	var spawn_positions: Array = get_valid_spawn_positions(planet_count)
	# Use last position in array to spawn sun
	var sun_data:Dictionary = generate_sun_data(planet_count)
	# Use remaining positions to get planet data
	var planet_data:Array = generate_planet_data(spawn_positions)
	
	
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


func generate_sun_data(PLANET_COUNT:int)-> Dictionary:
	# Generate random angle and radius for spawn position
	var max_spawn_distance: float = clamp(7500.0 + ((PLANET_COUNT - 3.0) * 750.0), 7500.0, 10000.0) - 2000
	var min_spawn_distance: float = 3500
	var random_angle: float = randf_range(0, TAU)
	var spawn_distance: float = randf_range(min_spawn_distance, max_spawn_distance)
	
	var spawn_position: Vector2 = Vector2.from_angle(random_angle) * spawn_distance
	var random_index: int = randi_range(0, 5)
	
	var sun_data: Dictionary = {
		"frame": random_index,
		"x": int(spawn_position.x),
		"y": int(spawn_position.y),
	}
	
	return sun_data


func get_valid_spawn_positions(PLANET_COUNT: int) -> Array:
	var min_dist_between: float = clamp(20000.0 / PLANET_COUNT, 6000.0, 20000.0)
	var max_dist_origin: float = 15000.0 + ((PLANET_COUNT - 3.0) * 750.0)
	var min_dist_origin: float = clamp(7500.0 + ((PLANET_COUNT - 3.0) * 750.0), 7500.0, 10000.0)

	var all_planets_data: Array = []
	var placed_positions: Array[Vector2] = [] # Store positions placed *in this run*
	
	
	var all_possible_points = PoissonDiscSampling.generate_points_for_circle(
		Vector2.ZERO,
		max_dist_origin,
		min_dist_origin,
		30
	)
	
	# Filter the points to be within the spawn ring
	var valid_spawn_points: Array[Vector2] = []
	for point in all_possible_points:
		# Check if the point is outside the inner "no-spawn" zone
		if point.distance_to(Vector2.ZERO) >= min_dist_origin:
			valid_spawn_points.append(point)
	
	# Shuffle the list to get a random selection
	valid_spawn_points.shuffle()
	# Take the first 'num_planets_to_spawn' points from the shuffled list
	var final_planet_positions = valid_spawn_points.slice(0, PLANET_COUNT)
	return final_planet_positions


func generate_planet_data(valid_spawns:Array[Vector2]) -> Array:
	var all_planets_data:Array = []
	for i in valid_spawns.size():
		# Pass the list of already placed positions to the validation function
		var position: Vector2 = valid_spawns.pop_front()

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
