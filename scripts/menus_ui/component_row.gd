extends HBoxContainer
class_name ComponentLabelRow

@export var icon: TextureRect
@export var component_name: Label

enum Icon {Control, Node2D, Node}
@export var icon_map: Dictionary[Icon, Texture2D] = {
}


func set_component(new_name: String, new_icon: Icon) -> void:
	icon.texture = icon_map.get(new_icon)
	component_name.text = new_name
