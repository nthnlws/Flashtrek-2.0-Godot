extends Resource
class_name PlanetData

@export var name: String
@export var frame: int = 0
@export var world_position: Vector2 = Vector2.ZERO
@export var faction: Utility.FACTION

@export var components: Array[BaseComponentData] = []

func add_component(component_type: Utility.PlanetComponentType, mission: MissionData) -> void:
	if component_type == Utility.PlanetComponentType.ANALYZE:
		var data = AnalyzeComponentData.new()
		data.setup_data(Utility.get_random_point_on_circle(1500))
		components.append(data)
		# Signal out or handle runtime injection if needed
