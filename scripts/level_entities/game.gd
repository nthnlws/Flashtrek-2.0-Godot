extends Node2D

@onready var loading_screen: Control = %LoadingScreen
@onready var warp_effect: ColorRect = %WarpEffect
@onready var hud: Control = $HUD_layer/HUD
@onready var level: Node = $Level
@onready var minimap: Control = %MiniMap

var galaxy_map: Resource = preload("res://assets/data/galaxy_map_data.tres")

var score:int = 0:
	set(value):
		score = value
		hud.score = score


func _ready() -> void:
	# Signal Connections
	SignalBus.system_changed.connect(_on_level_system_changed)
	SignalBus.galaxy_warp_finished.connect(_warp_into_new_system)
	SignalBus.playerDied.connect(handlePlayerDied)
	SignalBus.start_warp_effect.connect(galaxy_fade_out)
	
	Utility.current_gamestate = Utility.GAMESTATE.SYSTEM
	minimap.create_minimap_objects()
	
	SignalBus.galaxyDataUpdated.emit(LevelManager.galaxy_data)


func galaxy_fade_out() -> void:
	warp_effect.start_warp_animation()


func handlePlayerDied() -> void:
	SignalBus.toggleQ3HUD.emit("off")
	SignalBus.toggleQ2HUD.emit("off")
	%LoadingScreen.visible = true
	LevelManager.player.camera._zoom = Vector2(0.4, 0.4)
	await get_tree().create_timer(1.0).timeout
	LevelManager.player.respawn()
	%LoadingScreen.visible = false
	minimap.create_minimap_objects()


func _warp_into_new_system(system_data:SystemData) -> void:
	LevelManager.player.global_position = LevelManager.entry_coords
	
	LevelManager.player.camera._zoom = Vector2(0.4, 0.4)
	LevelManager.player.uncloak_ship(3.0)
	
	await get_tree().create_timer(1.5).timeout
	SignalBus.entering_new_system.emit()
	warp_effect.exit_warp_animation()
	
	var tween2: Object = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_LINEAR)
	tween2.tween_property(LevelManager.player, "velocity", Vector2(600, 0).rotated(LevelManager.player.global_rotation), 3.0)
	create_tween().tween_property(LevelManager.player.camera, "_zoom", Vector2(0.5, 0.5), 3.0)
	await tween2.finished
	
	LevelManager.player.camera._zoom = Vector2(0.5, 0.5)
	LevelManager.player.overdrive_state_change("SMOOTH")


func _on_level_system_changed(system_data: SystemData) -> void:
	if minimap:
		minimap.create_minimap_objects()
