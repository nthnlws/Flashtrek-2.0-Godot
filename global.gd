extends Node

@onready var player = $Game/Player
@onready var shield = $Game/Player/Shield
@onready var asteroid = $Game/Asteroids/Asteroid
@onready var hud = $Game/UI/HUD

func _ready():
	asteroid.area_entered.connect(player.die)
	shield.ready.connect(hud._on_shield_ready)

func asteroid_collision():
	pass
