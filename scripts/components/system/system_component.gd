extends Node
class_name SystemComponent

var system_data: SystemData

func initialize_component(new_system_data: SystemData) -> void:
	system_data = new_system_data
	_on_ready_logic()


func _on_ready_logic() -> void:
	# Virtual method to be overridden by subclasses
	pass
