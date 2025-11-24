# GalaxyData.gd
extends Resource
class_name GalaxyData

const system_name_file: String = "res://assets/data/system_names.txt"
enum SPECIAL_SYSTEMS { Solarus = 101, Kronos = 102, Romulus = 103, Risa = 104 }

const MAX_SYSTEM_NUMBER:int = 31  # Highest system level
const NUM_FED_SYSTEMS:int = 16
const NUM_KLING_SYSTEMS:int = 7
const NUM_ROM_SYSTEMS:int = 7

@export var systems: Array[SystemData]
var system_id_map: Dictionary = {} 
var system_names: Array[String]

const NEIGHBOR_MAP: Dictionary = {
	SPECIAL_SYSTEMS.Solarus: [6, 7, 8, 10],
	SPECIAL_SYSTEMS.Kronos:  [16, 17, SPECIAL_SYSTEMS.Risa, 20, 21],
	SPECIAL_SYSTEMS.Romulus: [26, 29, 30, 31],
	SPECIAL_SYSTEMS.Risa:    [14, SPECIAL_SYSTEMS.Kronos, 20, 19],

	# Procedural Systems (Using Integers 1-31)
	1:  [2, 3],
	2:  [1, 4],
	3:  [1, 5],
	4:  [2, 15, 6],
	5:  [3, 6, 7],
	6:  [4, 11, SPECIAL_SYSTEMS.Solarus, 5],
	7:  [5, SPECIAL_SYSTEMS.Solarus, 8],
	8:  [7, SPECIAL_SYSTEMS.Solarus, 9],
	9:  [8, 10],
	10: [9, SPECIAL_SYSTEMS.Solarus, 11],
	11: [6, 12, 10],
	12: [11, 13, 19, 28],
	13: [14, 12],
	14: [SPECIAL_SYSTEMS.Risa, 13],
	15: [4, 16],
	16: [15, 17, SPECIAL_SYSTEMS.Kronos],
	17: [16, SPECIAL_SYSTEMS.Kronos],
	19: [12, SPECIAL_SYSTEMS.Risa, 20, 27],
	20: [19, SPECIAL_SYSTEMS.Risa, SPECIAL_SYSTEMS.Kronos, 28],
	21: [SPECIAL_SYSTEMS.Kronos, 22, 24],
	22: [21, 23],
	23: [22, 24],
	24: [21, 23, 25],
	25: [24, 30],
	26: [29, 27, 20, 24, SPECIAL_SYSTEMS.Romulus],
	27: [19, 26, 28],
	28: [27, 29],
	29: [28, 26, SPECIAL_SYSTEMS.Romulus],
	30: [SPECIAL_SYSTEMS.Romulus, 25, 31],
	31: [SPECIAL_SYSTEMS.Romulus, 30],
}

func _init() -> void:
	if system_names.is_empty():
		_reload_text_file()


func _reload_text_file() -> void:
	system_names.clear()
	system_names = load_text_file(system_name_file)
	system_names.shuffle()


func get_system(system_id: int) -> SystemData:
	if system_id_map.has(system_id):
		return system_id_map[system_id]
	
	push_error("System ID %d not found in GalaxyData." % system_id)
	return null


static func generate_galaxy_data() -> GalaxyData:
	var new_galaxy:GalaxyData = GalaxyData.new()
	for sys_index:int in range(MAX_SYSTEM_NUMBER):
		var rand_sys_name:String = new_galaxy.system_names.pop_front()
		var system_data: SystemData = SystemData.generate_system_data(sys_index + 1, rand_sys_name) # +1 to have index values match GalaxyMap
		new_galaxy.systems.append(system_data)
		new_galaxy.system_id_map[sys_index + 1] = system_data # +1 to have index values match GalaxyMap
	
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
		var neighbor_ids: Array = NEIGHBOR_MAP[origin_id]
		
		# Iterate through the integer values (Neighbor IDs)
		for target_id: int in neighbor_ids:
			if system_id_map.has(target_id):
				var target_system: SystemData = system_id_map[target_id]
				origin_system.warp_neighbors.append(target_system)
			else:
				push_warning("System %d tries to connect to missing ID %d" % [origin_id, target_id])


static func load_text_file(file_path:String) -> Array[String]:
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
	var parents: Dictionary = { start_id: null }
	
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
