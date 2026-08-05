class_name AnalyzeComponentData
extends BaseComponentData

## Store the local offset from the planet center
@export var mission_point: Vector2

func _init() -> void:
	component_id = &"analyze"

## Called by the mission generator when the mission is created.
func setup_data(calculated_local_point: Vector2) -> void:
	mission_point = calculated_local_point
