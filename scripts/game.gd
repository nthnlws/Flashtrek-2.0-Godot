extends Node2D

@onready var hud: Control = $HUD_layer/HUD
@onready var VidModulate: CanvasModulate = %VidModulate
@onready var warp_video: VideoStreamPlayer = %warp_video
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
	SignalBus.galaxy_warp_finished.connect(_warp_into_new_system)
	SignalBus.playerDied.connect(handlePlayerDied)
	SignalBus.galaxy_warp_screen_fade.connect(galaxy_fade_out)
	
	
func galaxy_warp_check() -> bool:
	if (in_galaxy_warp == false and player.velocity.x > -25 and player.velocity.x < 25
		and player.velocity.y > -200 and player.velocity.y < 25 and player.warping_active == false):
			return true
	else: return false


func galaxy_fade_out():
	warp_video.play()
	
	await get_tree().create_timer(1.5).timeout
	var tween: Object = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(VidModulate, "color", Color(1, 1, 1, 0.4), 1.5)
	
	await get_tree().create_timer(2.0).timeout
	#get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")
	
	
	print("Warp finished with target system " + str(Navigation.targetSystem))
	SignalBus.galaxy_warp_finished.emit(Navigation.targetSystem)
	in_galaxy_warp = false
	
	#%LoadingScreen.visible = true
	#$transition_overlay.visible = false
	#$Video_layer.visible = false

func handlePlayerDied():
	%LoadingScreen.visible = true
	if Navigation.currentSystem != "Solarus":
		level._change_system("Solarus")
	player.camera._zoom = Vector2(0.4, 0.4)
	await get_tree().create_timer(1.5).timeout
	player.respawn(spawn_options.pick_random().global_position)
	%LoadingScreen.visible = false

func _warp_into_new_system(system):
	player.global_position = Navigation.entry_coords
	
	var tween: Object = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(VidModulate, "color", Color(1, 1, 1, 0), 1.0)
	
	Navigation.set_current_system(system)
	player.camera._zoom = Vector2(0.4, 0.4)
	
	await get_tree().create_timer(1.5).timeout
	
	SignalBus.entering_new_system.emit()
	
	#%LoadingScreen.visible = false
	#$transition_overlay.visible = true
	#FadeAnimation.visible = false
	
	player.warping_state_change("INSTANT")
	player._teleport_shader_toggle("uncloak")
	
	
	
	var tween2: Object = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property(player, "velocity", Vector2(0, -600).rotated(player.global_rotation), 3.0)
	create_tween().tween_property(player.camera, "_zoom", Vector2(0.5, 0.5), 3.0)
	await tween2.finished
	
	player.camera._zoom = Vector2(0.5, 0.5)
	player.warping_state_change("SMOOTH")
