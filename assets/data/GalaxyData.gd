# GalaxyData.gd
extends Resource
class_name GalaxyData

const system_name_file: String = "res://assets/data/system_names.txt"
enum SPECIAL_SYSTEMS {Solarus = 101, Kronos = 102, Romulus = 103, Risa = 104}

const MAX_SYSTEM_NUMBER: int = 30 # Highest system level, 1-30 = 30 systems
const NUM_FED_SYSTEMS: int = 16
const NUM_KLING_SYSTEMS: int = 7
const NUM_ROM_SYSTEMS: int = 7

@export var systems: Array[SystemData]
@export var system_id_map: Dictionary = {}
@export var system_names: Array[String]
@export var player_ship_type: Utility.SHIP_TYPES = Utility.starting_ship
@export var current_system: SystemData

static var NEIGHBOR_MAP: Dictionary[SPECIAL_SYSTEMS, Array] = {
	SPECIAL_SYSTEMS.Solarus: [6, 7, 8, 10],
	SPECIAL_SYSTEMS.Kronos: [16, 17, SPECIAL_SYSTEMS.Risa, 19, 20],
	SPECIAL_SYSTEMS.Romulus: [25, 28, 29, 30],
	SPECIAL_SYSTEMS.Risa: [14, SPECIAL_SYSTEMS.Kronos, 19, 18],
	
	1: [2, 3],
	2: [1, 4],
	3: [1, 5],
	4: [2, 15, 6],
	5: [3, 6, 7],
	6: [4, 11, SPECIAL_SYSTEMS.Solarus, 5],
	7: [5, SPECIAL_SYSTEMS.Solarus, 8],
	8: [7, SPECIAL_SYSTEMS.Solarus, 9],
	9: [8, 10],
	10: [9, SPECIAL_SYSTEMS.Solarus, 11],
	11: [6, 12, 10],
	12: [11, 13, 18, 27],
	13: [14, 12],
	14: [SPECIAL_SYSTEMS.Risa, 13],
	15: [4, 16],
	16: [15, 17, SPECIAL_SYSTEMS.Kronos],
	17: [16, SPECIAL_SYSTEMS.Kronos],
	18: [12, SPECIAL_SYSTEMS.Risa, 19, 26],
	19: [18, SPECIAL_SYSTEMS.Risa, SPECIAL_SYSTEMS.Kronos, 27],
	20: [SPECIAL_SYSTEMS.Kronos, 21, 23],
	21: [20, 22],
	22: [21, 23],
	23: [20, 22, 24],
	24: [23, 29],
	25: [28, 26, 19, 23, SPECIAL_SYSTEMS.Romulus],
	26: [18, 25, 27],
	27: [26, 28],
	28: [27, 25, SPECIAL_SYSTEMS.Romulus],
	29: [SPECIAL_SYSTEMS.Romulus, 24, 30],
	30: [SPECIAL_SYSTEMS.Romulus, 29],
}

func _to_string() -> String:
	return "--- %s systems generated in galaxy ---" % [systems.size()]
func _init() -> void:
	if system_names.is_empty():
		_reload_text_file()


# Called by the SaveManager immediately after loading
func post_load_setup() -> void:
	system_id_map.clear()
	
	# 1. First pass: Rebuild the Map
	for system: SystemData in systems:
		if system:
			system_id_map[system.system_index] = system
			
	# 2. Second pass: Reconnect Neighbors using the IDs
	for system: SystemData in systems:
		system.warp_neighbors.clear() # Clear old data to be safe
		
		for neighbor_id: int in system.neighbor_ids:
			if system_id_map.has(neighbor_id):
				system.warp_neighbors.append(system_id_map[neighbor_id])
			else:
				push_warning("System %d has missing neighbor ID %d" % [system.system_index, neighbor_id])


func _reload_text_file() -> void:
	system_names.clear()
	system_names = load_text_file(system_name_file)
	system_names.shuffle()


func get_system(system_id: int) -> SystemData:
	if system_id_map.has(system_id):
		return system_id_map[system_id]
	
	push_error("System ID %d not found in GalaxyData." % system_id)
	return null


func get_system_by_name(system_name: String) -> SystemData:
	for system: SystemData in systems:
		if system.system_name == system_name:
			return system
	
	push_error("System name %s not found in GalaxyData." % system_name)
	return null


static func generate_galaxy_data() -> GalaxyData:
	var new_galaxy: GalaxyData = GalaxyData.new()
	for sys_index: int in range(MAX_SYSTEM_NUMBER):
		var current_id: int = sys_index + 1
		var rand_sys_name: String = new_galaxy.system_names.pop_front()
		var system_data: SystemData = SystemData.generate_system_data(current_id, rand_sys_name)
		new_galaxy.systems.append(system_data)
		new_galaxy.system_id_map[current_id] = system_data
	
	var special_keys = SPECIAL_SYSTEMS.keys()
	for key_name in special_keys:
		var sys_id: int = SPECIAL_SYSTEMS[key_name] # INT value (101)
		# Use the enum key name as the system name (e.g., "Solarus")
		var system_data: SystemData = SystemData.generate_system_data(sys_id, key_name)
		
		new_galaxy.systems.append(system_data)
		new_galaxy.system_id_map[sys_id] = system_data
		
	
	new_galaxy._establish_warp_connections()
	new_galaxy._reload_text_file()
	
	return new_galaxy

func _establish_warp_connections() -> void:
	# Iterate directly through the integer keys (System IDs)
	for origin_id: int in NEIGHBOR_MAP.keys():
		# Safety Check
		if not system_id_map.has(origin_id):
			push_warning("NeighborMap ID %d not found in generated systems." % origin_id)
			continue
			
		var origin_system: SystemData = system_id_map[origin_id]
		for target_id: int in NEIGHBOR_MAP[origin_id]:
			if system_id_map.has(target_id):
				var target_system: SystemData = system_id_map[target_id]
				
				# 1. Update Runtime Reference (for immediate use)
				if not origin_system.warp_neighbors.has(target_system):
					origin_system.warp_neighbors.append(target_system)
				
				# 2. Update Save Data (Integer IDs)
				if not origin_system.neighbor_ids.has(target_id):
					origin_system.neighbor_ids.append(target_id)


static func load_text_file(file_path: String) -> Array[String]:
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open planet names file at %s" % file_path)
		return []

	var names: Array[String] = []
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line != "":
			names.append(line)
	file.close()
	return names


# Returns the number of jumps between two systems. 
# Returns -1 if no path exists.
static func get_jump_distance(start_id: int, target_id: int) -> int:
	# 1. Trivial case: We are already there
	if start_id == target_id:
		return 0
	
	# 2. Setup for Breadth-First Search (BFS)
	# Queue stores arrays of [current_system_id, current_distance]
	var queue: Array = []
	queue.append([start_id, 0])
	
	# Visited set to prevent loops (Dictionary used as Set for O(1) lookup)
	var visited: Dictionary = {}
	visited[start_id] = true
	
	# 3. Process the Queue
	while not queue.is_empty():
		var current_data: Array = queue.pop_front()
		var current_id: int = current_data[0]
		var current_dist: int = current_data[1]
		
		# Check immediate neighbors
		if NEIGHBOR_MAP.has(current_id):
			for neighbor_id: int in NEIGHBOR_MAP[current_id]:
				# Found the target!
				if neighbor_id == target_id:
					return current_dist + 1
				
				# If not visited, add to queue to check its neighbors later
				if not visited.has(neighbor_id):
					visited[neighbor_id] = true
					queue.append([neighbor_id, current_dist + 1])
	
	# 4. Queue emptied without finding target
	return -1

# Returns an Array of System IDs (ints) representing a warp path.
# Returns an empty array if no path is found.
static func get_shortest_path(start_id: int, target_id: int) -> Array[int]:
	if start_id == target_id:
		return [start_id]
	
	# BFS Queue: Stores current_id
	var queue: Array[int] = [start_id]
	
	# Parent Map: Keeps track of where we came from { child_id: parent_id }
	# Used to reconstruct the path later.
	var parents: Dictionary = {start_id: null}
	
	while not queue.is_empty():
		var current_id = queue.pop_front()
		
		if current_id == target_id:
			# Target found! Reconstruct path backwards.
			var path: Array[int] = []
			var curr = target_id
			while curr != null:
				path.append(curr)
				curr = parents[curr]
			path.reverse()
			return path
		
		# Add neighbors
		if NEIGHBOR_MAP.has(current_id):
			for neighbor in NEIGHBOR_MAP[current_id]:
				if not parents.has(neighbor):
					parents[neighbor] = current_id
					queue.append(neighbor)
					
	return [] # No path found
