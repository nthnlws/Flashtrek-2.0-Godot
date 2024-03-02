extends Node

export(PackedScene) var enemy

onready var entity_spawn_point = $EntityPath/EntitySpawnPoint


func _ready() -> void:
	EventBus.connect("game_over", self, "_on_game_over")


func _on_game_over() -> void:
	SceneChanger.change_scene("res://menu/game_over.tscn", 3.0)


func _on_UFOTimer_timeout() -> void:
	var e = enemy.instance()
	entity_spawn_point.offset = randi()
	e.position = entity_spawn_point.position
	$EntityContainer.add_child(e)


func _on_AsteroidTimer_timeout() -> void:
	var a = Asteroid.new()
	entity_spawn_point.offset = randi()
	a.position = entity_spawn_point.position
	# flinging the asteroid before it is in the scenetree raises an error, we should fling it after adding to the scene tree.
	# a.fling_at(Vector2.ZERO)
	$EntityContainer.add_child(a)
	a.fling_at(Vector2.ZERO)


func free_explosions():
	Sparks.garbage_collect(get_tree())
