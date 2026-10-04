class_name AnalyzeComponentData
extends PlanetComponentData

## Store the local offset from the planet center
@export var mission_point: Vector2

func _init() -> void:
	component_id = &"analyze"
