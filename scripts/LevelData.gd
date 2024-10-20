extends Node


var enemies = []
var levelWalls = []
var planets = []
var suns = []

func _ready() -> void:
	SignalBus.levelReset.connect(reset_arrays)
	
func reset_arrays():
	enemies.clear()
	levelWalls.clear()
	planets.clear()
	suns.clear()
