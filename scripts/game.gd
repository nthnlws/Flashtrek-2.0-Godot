extends Node2D

@onready var hud = $HUD_layer/HUD
@onready var anim = %AnimationPlayer
@onready var VidModulate = %VidModulate
@onready var canvas_modulate = %CanvasModulate
@onready var warp_video = %warp_video

# Vars for galaxy map navigation
var leave_info: Dictionary # Info for player pos when warping into system
var leaveDataStored: bool = false # Check to see if player pos has already been check
var current_system: String = "" # Current player system
var targetSystem: String = "" # Currently selected system on galaxy map

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
	
var score:int = 0:
	set(value):
		score = value
		hud.score = score


func _init():
	Utility.mainScene = self
	
	
func _ready():
	# Signal Connections
	SignalBus.galaxy_warp_screen_fade.connect(galaxy_fade_out)
	SignalBus.entering_galaxy_warp.connect(fade_hud)
	SignalBus.levelReset.connect(reset_arrays)
	
	if OS.get_name() == "Windows":
		DiscordManager.single_player_game() # Sets Discord status to Solarus
	
	anim.play("fade_in_long")

	
	Utility.current_system = "20"
	
	score = 0

func _process(delta: float) -> void:
	if in_galaxy_warp and leaveDataStored == false and player_outside_system_check(player.global_position):
		print("Left system at: " + str(player.global_position))
		store_player_system_exit_info()
		

func player_outside_system_check(coords: Vector2):
	if coords.x > 20000 or coords.x < -20000 or coords.y > 20000 or coords.y < -20000:
		leaveDataStored = true
		return true
	else: return false
	
func galaxy_warp_check() -> bool:
	if (in_galaxy_warp == false and player.velocity.x > -25 and player.velocity.x < 25
		and player.velocity.y > -25 and player.velocity.y < 25 and player.warping_active == false):
			return true
	else: return false

func store_player_system_exit_info():
	var leave_coords: Vector2 = player.global_position
	var leave_rotation: float = player.global_rotation
	
	leave_info = {
		"exit_pos": leave_coords,
		"leave_rotation": leave_rotation
	}

func set_player_system_entry_position():
	var exit_coords = leave_info.exit_pos
	var entry_coords = leave_info.exit_pos
	var exit_rotation = leave_info.leave_rotation
	
	# Flip the exit side to place the player on the opposite side
	if abs(exit_coords.x) >= 20000:
		# Player exited East/West, so flip the x-coordinate
		entry_coords.x *= -1
		# Cap the y-coordinate to 10,000
		entry_coords.y = clamp(exit_coords.y, -10000, 10000)
	elif abs(exit_coords.y) >= 20000:
		# Player exited North/South, so flip the y-coordinate
		entry_coords.y *= -1
		# Cap the x-coordinate to 10,000
		entry_coords.x = clamp(exit_coords.x, -10000, 10000)

	# Set the player's position and rotation upon entry
	player.global_position = entry_coords
	player.global_rotation = exit_rotation

func galaxy_fade_out():
	anim.play("galaxy_travel_fade_out")
	warp_video.play()
	
	await get_tree().create_timer(1.5).timeout
	var tween = create_tween().set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	tween.tween_property(VidModulate, "color", Color(1, 1, 1, 1), 4.0)
	
	await get_tree().create_timer(2.0).timeout
	#get_tree().change_scene_to_file("res://scenes/galaxy_map.tscn")
	
	
	get_tree().paused = true
	#print("Warp finished with target system " + str(Utility.mainScene.targetSystem))
	SignalBus.galaxy_warp_finished.emit(Utility.mainScene.targetSystem)
	
	
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
