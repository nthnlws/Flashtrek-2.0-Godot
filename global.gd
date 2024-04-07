extends Node

@onready var player = $Game/Player
@onready var asteroid = $Game/Asteroids/Asteroid

func _ready():
	asteroid.area_entered.connect(player.die)

func asteroid_collision():
	pass
