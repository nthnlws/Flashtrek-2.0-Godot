extends Resource
class_name PlanetData

@export var name: String
@export var frame: int = 0
@export var world_position: Vector2 = Vector2.ZERO
@export var faction: Utility.FACTION

# Components
enum PlanetComponentTypes { ANALYZE, COMMUNICATION, DELIVER, }
@export var component_map: Dictionary[PlanetComponentTypes, PackedScene] = {
	PlanetComponentTypes.ANALYZE: preload("res://scenes/components/analyze_planet_component.tscn"),
	PlanetComponentTypes.COMMUNICATION: preload("res://scenes/components/planet_communication_component.tscn"),
	#PlanetComponents.DELIVER: preload("res://scenes/components/planet_communication_component.tscn")
}
@export var active_components:Array[PlanetComponentTypes] = []


func add_component(component_type: PlanetComponentTypes) -> void:
	#print("added component: %s to planet: %s" % [str(component_type), name])
	if component_type in active_components:
		return
	
	active_components.append(component_type)