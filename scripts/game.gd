extends Node2D

@onready var hud = $HUD_layer/HUD
@onready var pauseMenu = $Menus/PauseMenu
@onready var game_over_screen = $Menus/GameOverScreen
@onready var anim = %AnimationPlayer

#var asteroid_scene = preload("res://scenes/asteroid.tscn")
#var Asteroid = preload("res://scripts/asteroid.gd")


var score:int = 0:
	set(value):
		score = value
		hud.score = score

func _ready():
	if OS.get_name() != "Windows":
		DiscordManager.single_player_game() # Sets Discord status to Solarus
	
	game_over_screen.visible = false
	score = 0

	#for asteroid in asteroids.get_children():
		#asteroid.connect("exploded", _on_asteroid_exploded)
	
	%ColorRect.visible
	anim.play("fade_in")


#func _on_asteroid_exploded(pos, size, points):
	#$AsteroidHitSound.play()
	#score += points
	#for i in range(2):
		#match size:
			#Asteroid.AsteroidSize.LARGE:
				#spawn_asteroid(pos, Asteroid.AsteroidSize.MEDIUM)
			#Asteroid.AsteroidSize.MEDIUM:
				#spawn_asteroid(pos, Asteroid.AsteroidSize.SMALL)
			#Asteroid.AsteroidSize.SMALL:
				#pass

#func spawn_asteroid(pos, size):
	#var a = asteroid_scene.instantiate()
	#a.global_position = pos
	#a.size = size
	#a.connect("exploded", _on_asteroid_exploded)
	#asteroids.call_deferred("add_child", a)
