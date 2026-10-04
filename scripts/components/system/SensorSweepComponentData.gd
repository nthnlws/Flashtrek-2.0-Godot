class_name SensorSweepComponentData
extends SystemComponentData

## Uncalibrated buoys, world space.
@export var scan_points: Array[Vector2] = []
@export var total_points: int = 0
## Only counts down while in the system.
@export var time_remaining: float = 0.0


func _init() -> void:
	component_id = &"sensor_sweep"
