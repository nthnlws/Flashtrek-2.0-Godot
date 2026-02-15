extends Node
class_name SystemComponent

var system_data: SystemData
var mission_data: MissionData

func initialize_component(new_system_data: SystemData, new_mission_data:MissionData) -> void:
	system_data = new_system_data
	mission_data = new_mission_data
	_on_ready_logic()


func _on_ready_logic() -> void:
	# Virtual method to be overridden by subclasses
	pass
