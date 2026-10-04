class_name ProtectComponentData
extends SystemComponentData

@export var faction: Utility.FACTION
@export var attacker_faction: Utility.FACTION
@export var protected_ships_data: Array[ShipState]
@export var difficulty: float = 1.0

@export_group("Route")
@export var start_position: Vector2
## Waypoints after start_position; the last is the destination.
@export var route: Array[Vector2] = []
## Index of the next waypoint.
@export var route_index: int = 0

@export_group("Ambushes")
## Route progress (0-1) at which each ambush spawns.
@export var ambush_thresholds: Array[float] = [0.3, 0.65]
@export var ambushes_triggered: int = 0
@export var ambush_size: int = 2


func _init() -> void:
	component_id = &"protect_ship"


## Route progress (0-1) for a transport at `position`.
func get_progress(position: Vector2) -> float:
	var points: Array[Vector2] = [start_position]
	points.append_array(route)

	var total: float = 0.0
	var covered: float = 0.0
	for i: int in range(route.size()):
		var segment: float = points[i].distance_to(points[i + 1])
		total += segment
		if i < route_index:
			covered += segment
		elif i == route_index:
			covered += maxf(segment - position.distance_to(points[i + 1]), 0.0)
	return covered / total if total > 0.0 else 1.0
