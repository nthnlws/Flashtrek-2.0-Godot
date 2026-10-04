## Relocated between systems by MissionManager._on_system_changed().
class_name BountyComponentData
extends SystemComponentData

@export var target: ShipState
@export var bounty_name: String
@export var faction: Utility.FACTION

## Multiplier on system difficulty for the target's stats.
const ELITE_DIFFICULTY_MULT: float = 1.75


func _init() -> void:
	component_id = &"bounty"


## Caller moves this data into `destination.components`.
func relocate(destination: SystemData) -> void:
	target.save_position = _random_position(destination)


func _random_position(system: SystemData) -> Vector2:
	return Utility.get_random_point_on_circle(randf_range(6000.0, system.system_size * 0.7))
