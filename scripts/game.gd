extends Node2D

@onready var torpedos = $Torpedos
@onready var player = $Player
@onready var asteroids = $Asteroids
@onready var hud = $UI/HUD
@onready var game_over_screen = $UI/GameOverScreen
@onready var player_spawn_pos = $PlayerSpawnPos
@onready var player_spawn_area = $PlayerSpawnPos/PlayerSpawnArea

var asteroid_scene = preload("res://scenes/asteroid.tscn")

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
	
	for asteroid in asteroids.get_children():
		asteroid.connect("exploded", _on_asteroid_exploded)

func _input(event):
	if Input.is_action_just_pressed("reset"):
		get_tree().reload_current_scene()
	
	if Input.is_action_just_pressed("f11"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		

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
		$MainMenuBackground.play()
	else:
		if player.warping_active == true:
			player.warping_state_change()
		await get_tree().create_timer(1).timeout
		while !player_spawn_area.is_empty:
			await get_tree().create_timer(0.1).timeout
		player.respawn(player_spawn_pos.global_position)
