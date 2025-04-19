extends Node

@export var levelBorders: PackedScene
@export var Planets: PackedScene
@export var Starbase: PackedScene
@export var PlayerSpawnArea: PackedScene
@export var Sun: PackedScene
@export var Hostiles: PackedScene
@export var player: PackedScene

@onready var game: Node2D = $".."

var all_systems_data: Dictionary = {} 


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



func _ready() -> void:
	instantiate_new_system_nodes() # Init spawn for all level nodes
	generate_system_info() # Generates system JSON
	_init_planets() # Spawn planets and move to JSON data locaiton
	


func _init_planets():
	var planets: Array = Utility.mainScene.planets
	var planet_data = all_systems_data.get("Solarus").planet_data
	for p in planet_data.size(): # Sets planets to JSON data
		planets[p].global_position.x = planet_data[p].x
		planets[p].global_position.y = planet_data[p].y
		planets[p].sprite.frame = planet_data[p].frame
	for r in planets.size() - planet_data.size(): # Removes extra planets from active set
		planets.resize(planets.size() - 1)
	
	
func instantiate_new_system_nodes():
	var init_border = levelBorders.instantiate()
	add_child(init_border)
	init_border.add_to_group("level_nodes")

	var init_sun = Sun.instantiate()
	add_child(init_sun)
	init_sun.add_to_group("level_nodes")
	

	var init_starbase = Starbase.instantiate()
	add_child(init_starbase)
	init_starbase.add_to_group("level_nodes")
	

	var init_spawn = PlayerSpawnArea.instantiate()
	add_child(init_spawn)
	init_spawn.add_to_group("level_nodes")
	init_spawn.add_to_group("player_spawn_area")
	

	for i in range(6): # Spawn 6 planets for use in level gen
		var init_planet: Node2D = Planets.instantiate()
		add_child(init_planet)
		init_planet.global_position = Vector2(40000, 40000) # Moves planets outside of level borders
		
	#var init_hostiles = Hostiles.instantiate()
	#add_child(init_hostiles)
	#init_hostiles.add_to_group("level_nodes")


	var init_player = player.instantiate()
	add_child(init_player)
	init_player.add_to_group("level_nodes")
	
func generate_system_info():
	var system_num = 1
	
	while system_num <= MAX_LEVEL:
		var system_data = generate_system_variables(system_num)
		all_systems_data[str(system_num)] = system_data
		system_num += 1
	
	var solarus_data: Dictionary = generate_system_variables("Solarus")
	all_systems_data["Solarus"] = solarus_data # Use the name as the key

	var kronos_data: Dictionary = generate_system_variables("Kronos")
	all_systems_data["Kronos"] = kronos_data

	var romulus_data: Dictionary = generate_system_variables("Romulus")
	all_systems_data["Romulus"] = romulus_data
	
	#print(all_systems_data)

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
		faction = get_faction_for_system(system_number)
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
	var planet_count = randi_range(3, 6)
	var planet_data = generate_planet_data(planet_count)
	
	return {
		"faction": faction,
		"planet_data": planet_data,
		"enemy_health_mult": enemy_health_mult,
		"enemy_damage_mult": enemy_damage_mult,
		"system_size": 20000,
		#"enemies": "BLANK",
		#"enemy_types": enemy_types,
	}

func get_faction_for_system(system_number) -> int:
	system_number = int(system_number)
	if system_number <= fed_max:
		return Utility.FACTION.FEDERATION
	elif system_number >= kling_min and system_number <= kling_max:
		return Utility.FACTION.KLINGON
	elif system_number >= rom_min:
		return Utility.FACTION.ROMULAN
	else:
		print("Error: System out of range, using default faction: Federation")
		return 0
			



func generate_planet_data(PLANET_COUNT: int) -> Array:
	# Ensure calculations use floats where needed
	var min_dist_between = clamp(20000.0 / PLANET_COUNT, 6000.0, 20000.0)
	var max_dist_origin = 15000.0 + ((PLANET_COUNT - 3.0) * 750.0)
	var min_dist_origin = clamp(7500.0 + ((PLANET_COUNT - 3.0) * 750.0), 7500.0, 10000.0)

	var all_planets_data: Array = []       # Initialize the ARRAY to hold all planet dictionaries
	var placed_positions: Array[Vector2] = [] # Store positions placed *in this run*

	for i in range(PLANET_COUNT):
		# Pass the list of already placed positions to the validation function
		var position = get_valid_position(min_dist_origin, max_dist_origin, min_dist_between, placed_positions)

		# Check if get_valid_position failed
		if position == Vector2.ZERO:
			push_warning("Failed to place planet %d. Stopping generation for this system." % (i + 1))
			# Depending on requirements, you might return the partially generated list
			# or an empty list to indicate complete failure.
			return all_planets_data # Return what we have so far

		# If successful, add the new position to the tracking list for the next iteration
		placed_positions.append(position)

		# Generate other planet data (e.g., texture frame)
		# Adjust range based on your sprite sheet
		var random_frame: int = randi() % 207 # Example: assumes 0-255 frames

		# Create the DICTIONARY for the current planet
		var current_planet_dict: Dictionary = {
			"frame": random_frame,
			"x": int(position.x),
			"y": int(position.y),
		}

		# Add the dictionary for this planet to the main array
		all_planets_data.append(current_planet_dict)
		# print("Placed planet %d at %s, frame %d" % [i+1, str(position), random_frame]) # Debugging

	# Return the completed array of planet dictionaries
	return all_planets_data


# --- Position Validation Function ---

# Tries to find a valid position, checking against previously placed positions in this batch
func get_valid_position(
		min_distance_from_origin: float,
		max_distance_from_origin: float,
		min_distance_between_planets: float,
		existing_positions: Array[Vector2] # Accept the list of already placed positions
	) -> Vector2:

	const max_attempts = 500 # Increased attempts slightly
	var attempt = 0
	# Removed internal planet_positions - uses the passed 'existing_positions' now

	while attempt < max_attempts:
		attempt += 1
		# Generate a random angle and distance within the specified range
		# Corrected distance generation for uniform area distribution
		var min_dist_sq = min_distance_from_origin * min_distance_from_origin
		var max_dist_sq = max_distance_from_origin * max_distance_from_origin
		var distance_sq = randf_range(min_dist_sq, max_dist_sq)
		var distance = sqrt(distance_sq)

		var angle = randf_range(0, TAU) # TAU = 2 * PI

		# Calculate the potential position
		var potential_position = Vector2(cos(angle), sin(angle)) * distance

		# Check if the position is far enough from other planets *in this batch*
		var is_valid = true
		# Use distance_squared_to for minor performance improvement
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
