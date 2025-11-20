extends Node2D

@onready var loading_screen: Control = %LoadingScreen
@onready var tunnel_effect: SubViewportContainer = %TunnelEffect
@onready var hud: Control = $HUD_layer/New_HUD

var galaxy_map: Resource = preload("res://assets/data/galaxy_map_data.tres")
var player:Player

var score:int = 0:
	set(value):
		score = value
		hud.score = score


func _ready() -> void:
	# Signal Connections
	SignalBus.galaxy_warp_finished.connect(_warp_into_new_system)
	SignalBus.playerDied.connect(handlePlayerDied)
	SignalBus.galaxy_warp_screen_fade.connect(galaxy_fade_out)
	
	LevelManager.on_level_loaded()


func galaxy_fade_out() -> void:
	tunnel_effect.visible = true
	var tween: Tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(tunnel_effect.get_node("ParticleViewport/ParticleDrawer"), "centerArea", 85, 4.0)
	
	await get_tree().create_timer(4.0).timeout
	
	print("Warp finished with target system " + str(Navigation.targetSystem))
	SignalBus.galaxy_warp_finished.emit(Navigation.targetSystem)
	Navigation.in_galaxy_warp = false


func handlePlayerDied() -> void:
	SignalBus.toggleQ3HUD.emit("off")
	SignalBus.toggleQ2HUD.emit("off")
	%LoadingScreen.visible = true
	if LevelManager.current_system_data.system_index != GalaxyData.SPECIAL_SYSTEMS.Solarus:
		LevelManager.change_system(GalaxyData.SPECIAL_SYSTEMS.Solarus)
	player.camera._zoom = Vector2(0.4, 0.4)
	await get_tree().create_timer(1.5).timeout
	LevelManager.player.respawn(LevelManager.get_spawn_position())
	%LoadingScreen.visible = false


func _warp_into_new_system(system) -> void:
	player.global_position = Navigation.entry_coords
	
	var tween: Tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(tunnel_effect.get_node("ParticleViewport/ParticleDrawer"), "centerArea", 200, 4.0)
	
	player.camera._zoom = Vector2(0.4, 0.4)
	player.overdrive_state_change("INSTANT")
	player.uncloak_ship(3.0)
	
	await get_tree().create_timer(1.5).timeout
	
	SignalBus.entering_new_system.emit()
	
	var tween2: Object = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property(player, "velocity", Vector2(600, 0).rotated(player.global_rotation), 3.0)
	create_tween().tween_property(player.camera, "_zoom", Vector2(0.5, 0.5), 3.0)
	await tween2.finished
	tunnel_effect.visible = false
	
	player.camera._zoom = Vector2(0.5, 0.5)
	player.overdrive_state_change("SMOOTH")
