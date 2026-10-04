extends Resource
class_name PlanetData

@export var name: String
@export var frame: int = 0
@export var world_position: Vector2 = Vector2.ZERO
@export var faction: Utility.FACTION

@export var components: Array[BaseComponentData] = []

## Builds the planet-scoped component registered as `component_id` via
## ComponentGenerator and stores it on this planet. `mission` may be null for
## components that don't need one.
func add_component(component_id: StringName, mission: MissionData) -> PlanetComponentData:
	var definition: ComponentDefinition = ComponentRegistry.get_definition(component_id)
	if definition == null or definition.scope != ComponentDefinition.Scope.PLANET:
		printerr("PlanetData: no planet-scoped component registered for id '%s'" % component_id)
		return null

	var data: PlanetComponentData = ComponentGenerator.build(component_id, {"mission": mission, "planet": self}) as PlanetComponentData
	if data == null:
		return null
	components.append(data)
	return data
