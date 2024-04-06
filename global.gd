extends Node

@onready var player = $Game/Player
@onready var asteroid = $Game/Asteroids/Asteroid


@export var warping_active = false
@export var shield_active = false

func _ready():
	asteroid.area_entered.connect(player.die)
