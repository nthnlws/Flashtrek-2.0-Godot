extends Node2D

@onready var hud = $HUD_layer/HUD
@onready var anim = %AnimationPlayer
@onready var canvas_modulate = %CanvasModulate
@onready var player_node = %Player

var in_galaxy_warp:bool = false

var enemies = []
var levelWalls = []
var planets = []
var suns = []
var player = []
var starbase = []
var systems = ["Solarus", "Romulus", "Kronos"]

func printArrays():
	print(enemies)
	print(planets)
	print(suns)
	print(levelWalls)
	
var score:int = 0:
	set(value):
		score = value
		hud.score = score

func _init():
	Utility.mainScene = self
	
	
func _ready():
	SignalBus.galaxy_warp_finished.connect(fade_screen_out)
	SignalBus.Quad1_clicked.connect(fade_hud)
	SignalBus.levelReset.connect(reset_arrays)
	
	if OS.get_name() == "Windows":
		DiscordManager.single_player_game() # Sets Discord status to Solarus

	score = 0
	
	#%ColorRect.visible
	#anim.play("fade_in")
#

func galaxy_warp_check() -> bool:
	if (in_galaxy_warp == false and player_node.velocity.x > -25 and player_node.velocity.x < 25
		and player_node.velocity.y > -25 and player_node.velocity.y < 25 and player_node.warping_active == false):
			return true
	else: return false


func fade_screen_out():
	anim.play("galaxy_warp_fade") 
	
	
func fade_hud():
	if galaxy_warp_check():
		create_tween().tween_property(canvas_modulate, "color", Color(1, 1, 1, 0), 2)
		await get_tree().process_frame
		in_galaxy_warp = true
	
	
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


func reset_arrays():
	enemies.clear()
	levelWalls.clear()
	planets.clear()
	suns.clear()
