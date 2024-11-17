extends Node

enum PLAYER_TYPE { BIRDOFPREY, ENTERPRISETOS, JEM_HADAR, ENTERPRISETNG, MONAVEEN }
enum ENEMY_TYPE { BIRDOFPREY, ENTERPRISETOS, JEM_HADAR, ENTERPRISETNG, MONAVEEN }
enum FACTION { FEDERATION, KLINGON, ROMULAN }

var mainScene:Node = null # Set by main scene on _init()

func _input(event):
	#Fullscreen management
	if Input.is_action_just_pressed("f11"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
