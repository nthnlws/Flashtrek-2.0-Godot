@tool
extends Area2D
class_name SystemIndicator

const GALAXY_MAP_LABEL_THEME = preload("uid://dxr76rggjriau")
var system_data:SystemData

@onready var system_label: SystemLabel = $SystemLabel

@export var system_index:int = 0:
	set(value):
		system_index = value
		name = str(value)


func _ready() -> void:
	if !Engine.is_editor_hint():
		system_data = LevelManager.galaxy_data.get_system(system_index)


func change_system_label(new_name:String) -> void:
		system_label.system_name = new_name
