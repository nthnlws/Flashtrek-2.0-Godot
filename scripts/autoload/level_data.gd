extends Node

var spawn_options: Array[Area2D] = []
var enemyShips: Array[EnemyCharacter] = []
var neutralShips: Array[NeutralCharacter] = []
var levelWalls: Array[Node2D] = []
var planets: Array[Node2D] = []
var unused_planets: Array[Node2D] = []
var suns: Array[Node2D] = []
var player: Player
var starbase: Array[Node2D] = []


var all_systems_data: Dictionary = {}


func _ready() -> void:
	SignalBus.level_entity_added.connect(add_level_entity)


func _printArrays() -> void:
	print(enemyShips)
	#print("Planets: %s" % planets)
	#print("Suns: %s" % suns)
	#print("Level Walls: %s" % levelWalls)


func add_level_entity(node:Node2D, type:String) -> void:
	match type:
		"Starbase":
			starbase.append(node)
		"Planet":
			planets.append(node)
		"Sun":
			suns.append(node)
		"Wall":
			levelWalls.append(node)
