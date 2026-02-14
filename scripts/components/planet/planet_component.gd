extends Node
class_name PlanetComponent

var parent_planet: Planet
var planet_data: PlanetData

func initialize_component(new_planet_data: Resource, host: Node2D) -> void:
	planet_data = new_planet_data
	parent_planet = host
	_on_ready_logic()


func _on_ready_logic() -> void:
	# Virtual method to be overridden by subclasses
	pass
