@tool
extends Area2D
class_name SystemIndicator

const GALAXY_MAP_LABEL_THEME = preload("res://resources/galaxy_map_label_theme.tres")

@export var system_name:String = "Solarus":
	set(value):
		self.name = value
		system_name = value
