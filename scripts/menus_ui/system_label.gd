@tool
extends Label
class_name SystemLabel

@export var system_name:String = "Solarus":
	set(value):
		self.name = value
		system_name = value
		set_text(value)
@export var modulate_color:Color = Color(1, 1, 0, 1):
	set(value):
		modulate_color = value
		modulate = value
const GALAXY_MAP_LABEL_THEME = preload("res://resources/galaxy_map_label_theme.tres")

func _ready() -> void:
	_setup_label()


func _setup_label() -> void:
	label_settings = GALAXY_MAP_LABEL_THEME # Assign theme
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER # Center alignment
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER # Center alignment
	uppercase = true
	size = Vector2(10, 10)
	modulate = modulate_color
