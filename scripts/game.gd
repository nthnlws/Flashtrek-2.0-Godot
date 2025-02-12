extends Node2D

@onready var hud = $HUD_layer/HUD
@onready var anim = %AnimationPlayer
@onready var VidModulate = %VidModulate
@onready var canvas_modulate = %CanvasModulate
@onready var warp_video = %warp_video

var in_galaxy_warp:bool = false

var enemies = []
var levelWalls = []
var planets = []
var suns = []
var player: Player
var starbase = []
var systems = ["Solarus", "Romulus", "Kronos"]

func printArrays():
	print(enemies)
	print(planets)
	print(suns)
	print(levelWalls)
	
func clearArrays():
	enemies.clear()
	planets.clear()
	suns.clear()
	levelWalls.clear()
	
var score:int = 0:
	set(value):
		score = value
		hud.score = score


func _init():
	Utility.mainScene = self
	clearArrays()
	
	
func _ready():
	# Signal Connections
	SignalBus.galaxy_warp_screen_fade.connect(galaxy_fade_out)
	SignalBus.entering_galaxy_warp.connect(fade_hud)
	SignalBus.levelReset.connect(clearArrays)
	
	if OS.get_name() == "Windows":
		DiscordManager.single_player_game() # Sets Discord status to Solarus
	
	anim.play("fade_in_long")

	
	Navigation.currentSystem = "Solarus"
	
	score = 0


	
func galaxy_warp_check() -> bool:
	if (in_galaxy_warp == false and player.velocity.x > -25 and player.velocity.x < 25
		and player.velocity.y > -25 and player.velocity.y < 25 and player.warping_active == false):
			return true
	else: return false


func galaxy_fade_out():
	anim.play("galaxy_travel_fade_out")
	warp_video.play()
	
	await get_tree().create_timer(1.5).timeout
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(VidModulate, "color", Color(1, 1, 1, 1), 4.0)
	
	await get_tree().create_timer(2.0).timeout
	#get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")
	
	
	get_tree().paused = true
	#print("Warp finished with target system " + str(Navigation.targetSystem))
	SignalBus.galaxy_warp_finished.emit(Navigation.targetSystem)
	
	
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
