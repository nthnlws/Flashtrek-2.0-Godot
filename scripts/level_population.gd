extends Node

@export var levelBorders: PackedScene
@export var Planets: PackedScene
@export var Starbase: PackedScene
@export var PlayerSpawnArea: PackedScene
@export var Sun: PackedScene
@export var Hostiles: PackedScene
@export var Player: PackedScene

@onready var init_nodes: Array = [levelBorders, Planets, Starbase, PlayerSpawnArea, Sun, Hostiles, Player]

# Called when the node enters the scene tree for the first time.
func _ready():
	instantiate_nodes()
	

func instantiate_nodes():
	var init_border = levelBorders.instantiate()
	add_child(init_border)
	
	var init_planets = Planets.instantiate()
	add_child(init_planets)
	
	var init_sun = Sun.instantiate()
	add_child(init_sun)
	
	var init_starbase = Starbase.instantiate()
	add_child(init_starbase)
	
	var init_spawn = PlayerSpawnArea.instantiate()
	add_child(init_spawn)
	
	var init_hostiles = Hostiles.instantiate()
	add_child(init_hostiles)
	
	var init_player = Player.instantiate()
	add_child(init_player)
