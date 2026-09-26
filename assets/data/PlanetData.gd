extends Resource
class_name PlanetData

@export var name: String
@export var frame: int = 0
@export var world_position: Vector2 = Vector2.ZERO
@export var faction: Utility.FACTION

@export var components: Array[BaseComponentData] = []

## Maps a PlanetComponentType to a factory Callable, mirroring
## ComponentManager.component_scene_map and SystemData.COMPONENT_FACTORIES.
## Adding a new planet-scoped component type only means adding one entry
## here (plus the scene mapping in ComponentManager) - no branching logic
## to edit or keep in sync. static var (not const) since the dictionary's
## values are lambdas, which aren't compile-time constants.
static var COMPONENT_FACTORIES: Dictionary[Utility.PlanetComponentType, Callable] = {
	Utility.PlanetComponentType.ANALYZE: func(): return AnalyzeComponentData.new(),
}

func add_component(component_type: Utility.PlanetComponentType, mission: MissionData) -> PlanetComponentData:
	if not COMPONENT_FACTORIES.has(component_type):
		printerr("PlanetData: no factory registered for component type %s" % component_type)
		return null

	var data: PlanetComponentData = COMPONENT_FACTORIES[component_type].call()
	data.owning_planet = self
	data.setup_from_mission(mission, self)
	components.append(data)
	# Signal out or handle runtime injection if needed
	return data
