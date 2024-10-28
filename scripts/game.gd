extends Node2D

@onready var hud = $HUD_layer/HUD
@onready var anim = %AnimationPlayer


var score:int = 0:
	set(value):
		score = value
		hud.score = score

func _ready():
	if OS.get_name() == "Windows":
		DiscordManager.single_player_game() # Sets Discord status to Solarus

	score = 0
	
	%ColorRect.visible
	anim.play("fade_in")

func load_menu_status():
	if not FileAccess.file_exists("user://menuoptions.json"):
		print("No save file found")
		# TODO: default menu file
		return
	
	var file = FileAccess.open("user://menuoptions.json", FileAccess.READ)
	var json = file.get_as_text()
	var save_data = JSON.parse_string(json)
	
	for key in save_data.keys():
		GameSettings.set(key, save_data[key])
		
	file.close()

func _input(event):
	if Input.is_action_just_pressed("f11"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
