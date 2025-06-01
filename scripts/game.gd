extends Node2D

@onready var hud: Control = $HUD_layer/HUD
@onready var warp_tunnel: ColorRect = %WarpTunnel
@onready var loading_screen: Control = %LoadingScreen
@onready var level: Node = $Level

var galaxy_map: Resource = preload("res://assets/data/galaxy_map_data.tres")

var in_galaxy_warp:bool = false

var spawn_options: Array = []
var enemies: Array = []
var levelWalls: Array = []
var planets: Array = []
var unused_planets: Array = []
var suns: Array = []
var player: Player
var starbase: Array = []

func _printArrays() -> void:
	print(enemies)
	print(planets)
	print(suns)
	print(levelWalls)
	
func clearArrays() -> void:
	enemies.clear()
	planets.clear()
	suns.clear()
	levelWalls.clear()
	
var score:int = 0:
	set(value):
		score = value
		hud.score = score


func _init() -> void:
	Utility.mainScene = self
	clearArrays()


func _ready() -> void:
	# Signal Connections
	SignalBus.galaxy_warp_finished.connect(_warp_into_new_system)
	SignalBus.playerDied.connect(handlePlayerDied)
	SignalBus.galaxy_warp_screen_fade.connect(galaxy_fade_out)


func galaxy_fade_out() -> void:
	warp_tunnel.visible = true
	
	await get_tree().create_timer(1.5).timeout
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(warp_tunnel, "material:shader_parameter/addH", 3, 3.0)
	
	await get_tree().create_timer(2.0).timeout
	
	
	print("Warp finished with target system " + str(Navigation.targetSystem))
	SignalBus.galaxy_warp_finished.emit(Navigation.targetSystem)
	in_galaxy_warp = false


func handlePlayerDied() -> void:
	%LoadingScreen.visible = true
	if Navigation.currentSystem != "Solarus":
		level._change_system("Solarus")
	player.camera._zoom = Vector2(0.4, 0.4)
	await get_tree().create_timer(1.5).timeout
	player.respawn(spawn_options.pick_random().global_position)
	%LoadingScreen.visible = false


func _warp_into_new_system(system) -> void:
	player.global_position = Navigation.entry_coords
	
	var tween: Tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(warp_tunnel, "material:shader_parameter/addH", 150, 3.0)
	
	player.camera._zoom = Vector2(0.4, 0.4)
	
	await get_tree().create_timer(1.5).timeout
	
	SignalBus.entering_new_system.emit()
	
	player.warping_state_change("INSTANT")
	player._teleport_shader_toggle("uncloak")
	
	var tween2: Object = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property(player, "velocity", Vector2(0, -600).rotated(player.global_rotation), 3.0)
	create_tween().tween_property(player.camera, "_zoom", Vector2(0.5, 0.5), 3.0)
	await tween2.finished
	
	player.camera._zoom = Vector2(0.5, 0.5)
	player.warping_state_change("SMOOTH")
