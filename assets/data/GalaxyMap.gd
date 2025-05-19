# GalaxyMap.gd
extends Resource
class_name GalaxyMap

@export var systems: Array[SystemData] = []

func get_system(name: String) -> SystemData:
	for system in systems:
		if system.system_name == name:
			return system
	return null
