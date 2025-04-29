extends Node2D

@onready var hud: Control = $HUD_layer/HUD
@onready var VidModulate: CanvasModulate = %VidModulate
@onready var warp_video: VideoStreamPlayer = %warp_video
@onready var full_color_rect: ColorRect = %FadeAnimation
@onready var loading_screen: Control = %LoadingScreen
@onready var level: Node = $Level

var in_galaxy_warp:bool = false

var spawn_options: Array = []
var enemies: Array = []
var levelWalls: Array = []
var planets: Array = []
var unused_planets: Array = []
var suns: Array = []
var player: Player
var starbase: Array = []

func _printArrays():
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
	SignalBus.playerDied.connect(handlePlayerDied)
	SignalBus.galaxy_warp_screen_fade.connect(galaxy_fade_out)
	
	Navigation.currentSystem = "Solarus"
	
	score = 0
	
	
	
func galaxy_warp_check() -> bool:
	if (in_galaxy_warp == false and player.velocity.x > -25 and player.velocity.x < 25
		and player.velocity.y > -200 and player.velocity.y < 25 and player.warping_active == false):
			return true
	else: return false


func galaxy_fade_out():
	warp_video.play()
	
	await get_tree().create_timer(1.5).timeout
	var tween: Object = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(VidModulate, "color", Color(1, 1, 1, 1), 4.0)
	
	await get_tree().create_timer(2.0).timeout
	#get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")
	
	
	print("Warp finished with target system " + str(Navigation.targetSystem))
	SignalBus.galaxy_warp_finished.emit(Navigation.targetSystem)
	in_galaxy_warp = false
	
	%LoadingScreen.visible = true
	$transition_overlay.visible = false
	$Video_layer.visible = false

func handlePlayerDied():
	%LoadingScreen.visible = true
	if Navigation.currentSystem != "Solarus":
		level._change_system("Solarus")
	player.camera._zoom = Vector2(0.4, 0.4)
	await get_tree().create_timer(1.5).timeout
	player.respawn(spawn_options.pick_random().global_position)
	%LoadingScreen.visible = false
