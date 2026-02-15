extends Resource
class_name PlanetData

@export var name: String
@export var frame: int = 0
@export var world_position: Vector2 = Vector2.ZERO
@export var faction: Utility.FACTION

# Components
enum PlanetComponentType { ANALYZE, COMMUNICATION, DELIVER }
@export var component_map: Dictionary[PlanetComponentType, PackedScene] = {
	PlanetComponentType.ANALYZE: preload("uid://cq5kxvmajgng5"),
	PlanetComponentType.COMMUNICATION: preload("uid://rr6unh73nxxs"),
	#PlanetComponents.DELIVER: preload("res://scenes/components/planet_communication_component.tscn")
}
@export var active_components:Dictionary[PlanetComponentType, MissionData] = {}


func add_component(component_type: PlanetComponentType, mission_data: MissionData = MissionData.new()) -> void:
	#print("added component: %s to planet: %s" % [PlanetData.PlanetComponentType.keys()[component_type], name])
	if component_type in active_components:
		# Component already added to data
		return
	
	active_components.set(component_type, mission_data)
