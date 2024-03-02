extends Control

onready var play_button = $VBoxContainer/HSplitContainer/VBoxContainer/Play/Button
onready var quit_button = $VBoxContainer/HSplitContainer/VBoxContainer/Quit/Button


func _ready() -> void:
	yield($AnimationPlayer, "animation_finished")
	play_button.grab_focus()


func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("fire_laser"):
		SceneChanger.change_scene("res://game/game.tscn")
		# gdlint: disable=private-method-call
		MusicManager._change_track_to("Game", 3.0)


func _on_Play_pressed() -> void:
	_disable_buttons()
	SceneChanger.change_scene("res://game/game.tscn")
	# gdlint: disable=private-method-call
	MusicManager._change_track_to("Game", 3.0)


func _on_Quit_pressed() -> void:
	_disable_buttons()
	get_tree().quit()


func _disable_buttons() -> void:
	play_button.set_focus_mode(Control.FOCUS_NONE)
	quit_button.set_focus_mode(Control.FOCUS_NONE)
