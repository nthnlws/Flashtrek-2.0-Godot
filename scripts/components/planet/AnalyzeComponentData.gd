class_name AnalyzeComponentData
extends PlanetComponentData

## Store the local offset from the planet center
@export var mission_point: Vector2

func _init() -> void:
	component_id = &"analyze"

## Called by PlanetData.add_component() when the mission is created.
func setup_from_mission(mission: MissionData, context: PlanetData) -> void:
	mission_point = Utility.get_random_point_on_circle(1500)
