extends Control


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	yield($AnimationPlayer, "animation_finished")
	SceneChanger.change_scene("res://menu/main_menu.tscn", 3.0)
