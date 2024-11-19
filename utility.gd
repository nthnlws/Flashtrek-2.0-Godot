extends Node

enum PLAYER_TYPE { BIRDOFPREY, ENTERPRISETOS, JEM_HADAR, ENTERPRISETNG, MONAVEEN, CALIFORNIA }
enum ENEMY_TYPE { BIRDOFPREY, ENTERPRISETOS, JEM_HADAR, ENTERPRISETNG, MONAVEEN, CALIFORNIA }
enum FACTION { FEDERATION, KLINGON, ROMULAN, NEUTRAL }

var mainScene:Node = null # Set by main scene on _init()

const UI_yellow: String = "[color=#FFCC66]"
const UI_blue: String = "[color=#6699CC]"
const UI_cargo_green: String = "[color=#1DCC4B]"
const UI_ship_lime: String = "[color=#3bdb8b]"


func _input(event):
	#Fullscreen management
	if Input.is_action_just_pressed("f11"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
