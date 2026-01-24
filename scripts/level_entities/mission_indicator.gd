extends Node2D
class_name MissionIndicator

@onready var indicator_animation: AnimationPlayer = $IndicatorAnimation

signal player_entered
signal player_exited


func _ready() -> void:
	self.visible = false


func activate_indicator(spawn_position:Vector2):
	self.position = spawn_position
	indicator_animation.play("active_indicator")
	self.visible = true

func deactivate_indicator() -> void:
	print("disable indicator")
	indicator_animation.stop()
	self.visible = false


func _on_mission_zone_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_entered.emit(body)

func _on_mission_zone_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_exited.emit(body)
