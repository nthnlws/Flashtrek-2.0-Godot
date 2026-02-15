extends Node2D
class_name PlanetComponent

var parent_planet: Planet
var planet_data: PlanetData
var mission_data: MissionData

func initialize_component(new_planet_data: Resource, host: Node2D, new_mission_data:MissionData = MissionData.new()) -> void:
	planet_data = new_planet_data
	parent_planet = host
	mission_data = new_mission_data
	_on_ready_logic()


func _on_ready_logic() -> void:
	# Virtual method to be overridden by subclasses
	pass
