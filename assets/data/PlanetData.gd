extends Resource
class_name PlanetData

@export var name: String
@export var frame: int = 0
@export var world_position: Vector2 = Vector2.ZERO
@export var faction: Utility.FACTION

# Components
enum PlanetComponentType { ANALYZE, COMMUNICATION, DELIVER }
@export var component_map: Dictionary[PlanetComponentType, PackedScene] = {
	PlanetComponentType.ANALYZE: preload("res://scenes/components/analyze_planet_component.tscn"),
	PlanetComponentType.COMMUNICATION: preload("res://scenes/components/planet_communication_component.tscn"),
	#PlanetComponents.DELIVER: preload("res://scenes/components/planet_communication_component.tscn")
}
@export var active_components:Array[PlanetComponentType] = []


func add_component(component_type: PlanetComponentType) -> void:
	print("added component: %s to planet: %s" % [PlanetData.PlanetComponentType.keys()[component_type], name])
	if component_type in active_components:
		# Component already added to data
		return
	
	active_components.append(component_type)
