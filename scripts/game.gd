extends Node2D

@onready var hud = $HUD_layer/HUD
@onready var pauseMenu = $Menus/PauseMenu
@onready var game_over_screen = $Menus/GameOverScreen
@onready var anim = %AnimationPlayer


var score:int = 0:
	set(value):
		score = value
		hud.score = score

func _ready():
	if OS.get_name() != "Windows":
		DiscordManager.single_player_game() # Sets Discord status to Solarus
	
	game_over_screen.visible = false
	score = 0
	
	%ColorRect.visible
	anim.play("fade_in")
