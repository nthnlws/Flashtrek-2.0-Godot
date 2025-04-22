extends Node2D

@onready var hud = $HUD_layer/HUD
@onready var anim = %AnimationPlayer
@onready var VidModulate = %VidModulate
@onready var canvas_modulate = %CanvasModulate
@onready var warp_video = %warp_video
@onready var full_color_rect: ColorRect = %FadeAnimation
@onready var loading_screen: Control = %LoadingScreen

var in_galaxy_warp:bool = false

var spawn_options: Array = []
var enemies: Array = []
var levelWalls: Array = []
var planets: Array = []
var unused_planets: Array = []
var suns: Array = []
var player: Player
var starbase: Array = []
var systems: Array = ["Solarus", "Romulus", "Kronos"]

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
	SignalBus.galaxy_warp_screen_fade.connect(galaxy_fade_out)
	SignalBus.entering_galaxy_warp.connect(fade_hud.bind("off"))
	
	if OS.get_name() == "Windows":
		DiscordManager.single_player_game() # Sets Discord status to Solarus
	
	anim.play("fade_in_long")
	
	Navigation.currentSystem = "Solarus"
	
	score = 0


func _warp_into_new_system(system):
	%MiniMap.create_minimap_objects() # Update minimap objects to new system
	player.camera._zoom = Vector2(0.4, 0.4)
	
	await get_tree().create_timer(1.5).timeout
	SignalBus.entering_new_system.emit()
	
	anim.play("fade_in_long")
	%LoadingScreen.visible = false
	$transition_overlay.visible = true
	anim.play("fade_in_long")
	
	player.global_position = Navigation.entry_coords
	
	player._teleport_shader_toggle("uncloak")
	player.warping_state_change("INSTANT")
	
	
	var tween: Object = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(player, "velocity", Vector2(0, -600).rotated(player.global_rotation), 3.0)
	create_tween().tween_property(player.camera, "_zoom", Vector2(0.5, 0.5), 3.0)
	await tween.finished
	player.camera._zoom = Vector2(0.5, 0.5)
	
	fade_hud("on")
	player.warping_state_change("SMOOTH")
	in_galaxy_warp = false
	
	
	
func galaxy_warp_check() -> bool:
	if (in_galaxy_warp == false and player.velocity.x > -25 and player.velocity.x < 25
		and player.velocity.y > -200 and player.velocity.y < 25 and player.warping_active == false):
			return true
	else: return false


func galaxy_fade_out():
	anim.play("galaxy_travel_fade_out")
	warp_video.play()
	
	await get_tree().create_timer(1.5).timeout
	var tween: Object = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(VidModulate, "color", Color(1, 1, 1, 1), 4.0)
	
	await get_tree().create_timer(2.0).timeout
	#get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")
	
	
	print("Warp finished with target system " + str(Navigation.targetSystem))
	SignalBus.galaxy_warp_finished.emit(Navigation.targetSystem)
	
	%LoadingScreen.visible = true
	$transition_overlay.visible = false
	$Video_layer.visible = false
	
	
	
func fade_hud(state):
	if state == "off":
		create_tween().tween_property(canvas_modulate, "color", Color(1, 1, 1, 0), 2)
	else:
		var tween: Object = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_property(canvas_modulate, "color", Color(1, 1, 1, 1), 3)
	
	
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
