@tool
extends RichTextLabel
class_name SystemLabel

const default_color = Color(1, 1, 0, 1)

@export var system_name:String = "Solarus":
	set(value):
		self.name = value
		system_name = value
		self.text = value

const ethno_font = preload("uid://biu3eo18bcl6f")

func _ready() -> void:
	_setup_label()


func _setup_label() -> void:
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER # Center alignment
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER # Center alignment
	size = Vector2(30, 10)
