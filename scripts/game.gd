extends Node2D

@onready var torpedos = $Level/Torpedos
@onready var player = $Level/Player
@onready var asteroids = $Level/Asteroids

@onready var hud = $HUD_layer/HUD
@onready var pauseMenu = $Menus/PauseMenu
@onready var game_over_screen = $Menus/GameOverScreen
@onready var anim = %AnimationPlayer


@onready var player_spawn_pos = $Level/PlayerSpawnPos
@onready var player_spawn_area = $Level/PlayerSpawnPos/PlayerSpawnArea

var asteroid_scene = preload("res://scenes/asteroid.tscn")
var Asteroid = preload("res://scripts/asteroid.gd")


#func _on_ready() -> void:
	#var load_signal = func(): Global.emit_signal("level_loaded")
	#call_deferred("load_signal")
	
var score:int = 0:
	set(value):
		score = value
		hud.score = score
		
var lives: int:
	set(value):
		lives = value
		hud.init_lives(lives)

func _ready():
	game_over_screen.visible = false
	score = 0
	lives = 3
	
	player.connect("torpedo_shot", _on_player_torpedo_shot)
	player.connect("died", _on_player_died)
	pauseMenu.connect("teleport", Callable(player, "teleport"))
	
	for asteroid in asteroids.get_children():
		asteroid.connect("exploded", _on_asteroid_exploded)
	
	%ColorRect.visible
	anim.play("fade_in")
	
	
func _on_player_torpedo_shot(torpedo):
	torpedos.add_child(torpedo)

func _on_asteroid_exploded(pos, size, points):
	$AsteroidHitSound.play()
	score += points
	for i in range(2):
		match size:
			Asteroid.AsteroidSize.LARGE:
				spawn_asteroid(pos, Asteroid.AsteroidSize.MEDIUM)
			Asteroid.AsteroidSize.MEDIUM:
				spawn_asteroid(pos, Asteroid.AsteroidSize.SMALL)
			Asteroid.AsteroidSize.SMALL:
				pass

func spawn_asteroid(pos, size):
	var a = asteroid_scene.instantiate()
	a.global_position = pos
	a.size = size
	a.connect("exploded", _on_asteroid_exploded)
	asteroids.call_deferred("add_child", a)

func _on_player_died():
	lives -= 1
	player.global_position = player_spawn_pos.global_position
	if lives <= 0:
		await get_tree().create_timer(1.0).timeout
		game_over_screen.visible = true
		#TODO: Add game over music here
	else:
		if player.warping_active == true:
			player.warping_state_change()
		await get_tree().create_timer(1).timeout
		player.respawn(player_spawn_pos.global_position)




