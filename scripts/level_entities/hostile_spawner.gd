extends Node2D

@export var enemy_scene:PackedScene


func _ready():
	for planet in Utility.mainScene.planets:
		var randi: int = randi_range(-1000, 1000)
		var enemy = enemy_scene.instantiate()
		enemy.global_position = planet.global_position + Vector2(randi, randi)
		add_child(enemy)
