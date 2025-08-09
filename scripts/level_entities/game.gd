extends Node2D

@onready var hud: Control = $HUD_layer/HUD
@onready var loading_screen: Control = %LoadingScreen
@onready var level: Node = $Level
@onready var tunnel_effect: SubViewportContainer = %TunnelEffect

var galaxy_map: Resource = preload("res://assets/data/galaxy_map_data.tres")

const MAX_LEVEL = 31  # Highest system level

var score:int = 0:
	set(value):
		score = value
		hud.score = score


func _ready() -> void:
	# Signal Connections
	SignalBus.galaxy_warp_finished.connect(_warp_into_new_system)
	SignalBus.playerDied.connect(handlePlayerDied)
	SignalBus.galaxy_warp_screen_fade.connect(galaxy_fade_out)


func galaxy_fade_out() -> void:
	tunnel_effect.visible = true
	var tween: Tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(tunnel_effect.get_node("ParticleViewport/ParticleDrawer"), "centerArea", 85, 4.0)
	
	await get_tree().create_timer(4.0).timeout
	
	print("Warp finished with target system " + str(Navigation.targetSystem))
	SignalBus.galaxy_warp_finished.emit(Navigation.targetSystem)
	Navigation.in_galaxy_warp = false


func handlePlayerDied() -> void:
	%LoadingScreen.visible = true
	if Navigation.currentSystem != "Solarus":
		level._change_system("Solarus")
	LevelData.player.camera._zoom = Vector2(0.4, 0.4)
	await get_tree().create_timer(1.5).timeout
	LevelData.player.respawn(LevelData.spawn_options.pick_random().global_position)
	%LoadingScreen.visible = false


func _warp_into_new_system(system) -> void:
	LevelData.player.global_position = Navigation.entry_coords
	
	var tween: Tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(tunnel_effect.get_node("ParticleViewport/ParticleDrawer"), "centerArea", 200, 4.0)
	
	LevelData.player.camera._zoom = Vector2(0.4, 0.4)
	LevelData.player.overdrive_state_change("INSTANT")
	LevelData.player._teleport_shader_toggle("uncloak")
	
	await get_tree().create_timer(1.5).timeout
	
	SignalBus.entering_new_system.emit()
	
	var tween2: Object = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property(LevelData.player, "velocity", Vector2(0, -600).rotated(LevelData.player.global_rotation), 3.0)
	create_tween().tween_property(LevelData.player.camera, "_zoom", Vector2(0.5, 0.5), 3.0)
	await tween2.finished
	tunnel_effect.visible = false
	
	LevelData.player.camera._zoom = Vector2(0.5, 0.5)
	LevelData.player.overdrive_state_change("SMOOTH")


func generate_system_info() -> void:
	var all_systems_data = LevelData.all_systems_data
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
	
	LevelData.all_systems_data = all_systems_data
	Navigation.systems = all_systems_data.keys()
	SignalBus.updateLevelData.emit(all_systems_data)


func generate_system_variables(system_number) -> Dictionary:
	var faction
	if typeof(system_number) == TYPE_STRING:
		match system_number:
			"Solarus":
				system_number = 1
				faction = Utility.FACTION.FEDERATION
			"Kronos":
				system_number = 20
				faction = Utility.FACTION.KLINGON
			"Romulus":
				system_number = 30
				faction = Utility.FACTION.ROMULAN
			"Neutral":
				faction = Utility.FACTION.NEUTRAL
				system_number = 12
	else:
		faction = Navigation.get_faction_for_system(system_number)
		system_number = int(system_number)
	
	# Health Scaling
	var ship_health_mult: float = 1
	var health_scaling_rate: float = 4.0/14.0
	
	# Damage Scaling
	var enemy_damage_mult: float = 1
	var damage_scaling_rate: float = 4.0/14.0
	if system_number <= 6:
		pass
	elif system_number <= 20:
		ship_health_mult = snapped(1 + ((system_number - 6) * health_scaling_rate), 0.01)
		enemy_damage_mult = snapped(1 + ((system_number - 6) * damage_scaling_rate), 0.01)
		#print("Health mult equals 1 + (" + str(system_number - 6) + " times scaling rate: %s" % health_scaling_rate + " equals %s" % enemy_health_mult)
	else: 
		ship_health_mult = 5.0 # Default double scaling above system 20
		enemy_damage_mult = 5.0
	
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
		"ship_health_mult": ship_health_mult,
		"enemy_damage_mult": enemy_damage_mult,
		"system_size": 20000,
		"enemies": {},
		"neutrals": {},
		"enemies_defeated": false,
		"neutrals_defeated": false,
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
		
		# Create the Dictionary for the current planet
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
