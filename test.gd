extends Node2D

var o: String = "4"
var t: String = "3"
var range: int = 2
var galaxyMapData = preload("res://assets/data/galaxy_map_data.tres")

func _ready():
	print(get_reachable_systems(o, range))
	
	
func system_neighbor_check(origin, target) -> bool:
	var system: SystemData = galaxyMapData.get_system(origin)
	if not system:
		printerr("Current system not found: ", origin)
		return false

	# Check if destination is in neighbors
	if target in system.neighbors:
		return true
	else:
		print("Destination not a neighbor!")
		return false

func get_reachable_systems(start_name: String, max_range: int) -> Array:
	var visited := {}
	var queue: Array = []
	var reachable := []

	queue.append({ "name": start_name, "depth": 0 })
	visited[start_name] = true

	while not queue.is_empty():
		var current = queue.pop_front()
		var current_name = current["name"]
		var depth = current["depth"]

		if depth > 0:
			reachable.append(current_name)

		if depth >= max_range:
			continue

		var current_system = galaxyMapData.get_system(current_name)
		if current_system == null:
			continue

		for neighbor_name in current_system.neighbors:
			if not visited.has(neighbor_name):
				visited[neighbor_name] = true
				queue.append({ "name": neighbor_name, "depth": depth + 1 })

	return reachable
