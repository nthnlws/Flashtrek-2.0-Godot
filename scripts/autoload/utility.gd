extends Node
class_name game_data


var Z: Dictionary[String, int] =  { # Z Indexes for level objects
	# -- GAME WORLD STATIC OBJECTS --
	"Suns": 0,
	"Planets": 0,
	"Starbase": 0,
	
	# -- GAME WORLD DYNAMIC OBJECTS --
	"LootDrops": 5, # Should appear on top of planets but behind ships
	"Weapons": 10, # Lasers, torpedoes, etc.
	"NeutralShips": 20, # Player and NPCs will share this base layer
	"FriendlyShips": 25, # Player and NPCs will share this base layer
	"FactionShips": 30,
	"Player": 40,
	
	# -- GAME WORLD EFFECTS --
	"Effects": 50, # Explosions, shield hits, etc.
	"Hitmarker": 60, 
	
	# -- LEVEL STATIC OBJECTS --
	"WorldBorders": 60,
}

var player_name: String = "USS Enterprise"
var starting_ship: SHIP_TYPES = SHIP_TYPES.Hideki_Class

enum FACTION { FEDERATION, KLINGON, ROMULAN, NEUTRAL }

# Used for global references to dict ship data JSON
enum SHIP_TYPES {
	Merchantman,				#0
	Keldon_Class,
	batlh_Class,
	JemHadar,
	sech_Class,
	Pathfinder_Class,
	Steamrunner_Class,
	Soyuz_Class,
	Miranda_Class,
	Nimitz_Class,
	Freedom_Class,				#10
	Intrepid_Class,
	Niagara_Class,
	Talarian_Freighter,
	Galor_Class,
	Bajoran_Freighter,
	daSpu_Class,
	Klingon_Bird_of_Prey,
	Walker_Class,
	Sovereign_Class,
	Malachowski_Class,			#20
	Miranda_Class_Lantree_variant,
	Nova_Class,
	Constitution_Class_Strange_New_Worlds,
	Nova_Class_Rhode_Island_variant,
	New_Orleans_Class,
	DKora_Marauder,
	Hideki_Class,
	Qugh_Class,
	Hiawatha_Class,
	Mars_Synth_Defense_Ship,	 #30
	Mogai_Class,
	Intrepid_Class_Aeroshuttle,
	Gagarin_Class,
	Saber_Class,
	Miranda_Class_Saratoga_variant,
	Parliament_Class,
	Georgiou_Class,
	Defiant_Class,
	Cheyenne_Class,
	Peregrine_Class,			 #40
	Odyssey_Class,
	D5_Class,
	Risian_Corvette,
	Breen_Interceptor,
	Bajoran_Interceptor,
	Oberth_Class,
	Cardenas_Class,
	Vesta_Class,
	Miranda_Class_Antares_variant,
	Challenger_Class,			 #50
	Constitution_II_Class,
	Constitution_III_Class,
	Galaxy_Class,
	Maquis_Raider,
	chargh_Class,
	Wallenberg_Class,
	Dhailkhina_Class,
	Sampson_Class,
	Excelsior_Class,
	Class_III_Neutronic_Fuel_Carrier_Kobayashi_Maru, #60
	Shepard_Class,
	Norway_Class,
	California_Class,
	Galaxy_Class_Venture_variant,
	Springfield_Class,
	Theta_Class,
	Groumall_Freighter,
	Tellarite_Cruiser,
	Magee_Class,
	bortaS_bIr_Class,			#70
	Dia_Vectau_Class,
	Hernandez_Class,
	Excelsior_Class_Refit,
	Luna_Class,
	Edison_Class,
	Constellation_Class,
	Sagan_Class,
	Sutherland_Class,
	Nebula_Class_Phoenix_variant,
	La_Sirena,					#80
	Monaveen,
	Risian_Luxury_Cruiser,
	Brel_Class,
	Dderidex_Class,
	Engle_Class,
	Reliant_Class,
	Ross_Class,
	Akira_Class,
	Ambassador_Class,
	Excelsior_II_Class,			#90
	Hoover_Class,
	Nebula_Class,
}

#Accessed by Utility.SHIP_DATA.values()[Utility.SHIP_TYPES.ship_name]
var SHIP_DATA: Dictionary # Loaded from ShipData.JSON file
var PLAYER_SHIP_STATS: Dictionary # Loaded from ShipData.JSON file
var ENEMY_SHIP_STATS: Dictionary # Loaded from ShipData.JSON file

var is_initial_load: bool = true
var fadeLength: float = 2.0 # Used for fade in/out on Galaxy Warp

# Colors
const UI_yellow: String = "[color=#FFCC66]"
const UI_blue: String = "[color=#6699CC]"
const UI_cargo_green: String = "[color=#1DCC4B]"
const UI_ship_lime: String = "[color=#3bdb8b]"
const damage_red: String = "[color=#eb4034]"
const damage_green: String = "[color=#46e065]"
const damage_blue: String = "[color=#80b9ff]"
const fed_blue: String = "[color=#3984BE]"
const rom_green: String = "[color=#009301]"
const klin_red: String = "[color=#FF2A2A]"
const neut_cyan: String = "[color=#78D9C2]"


func _init() -> void:
	load_JSON_ship_data()


func _ready() -> void:
	SignalBus.updateLevelData.connect(store_level_data)


func _input(event: InputEvent) -> void:
	#Fullscreen management
	if Input.is_action_just_pressed("f11"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func store_level_data(save_data: GalaxyData) -> void: #TODO fix saving logic for new GalaxyData structure
	var file_path: String = "user://level_data.json"
	
	# Save to file
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_data, "\t", false))
	file.close()

#func load_level_data()
# Check if the file exists and load existing data if it does
	#if FileAccess.file_exists(file_path):
		#var file = FileAccess.open(file_path, FileAccess.READ)
		#save_data = JSON.parse_string(file.get_as_text())
		#file.close()


func load_JSON_ship_data() -> void:
	var JSON_path:String = "res://assets/data/ShipData.json"
	var file_string:String = FileAccess.get_file_as_string(JSON_path)
	var JSON_ship_data: Dictionary
	if file_string != null:
		JSON_ship_data = JSON.parse_string(file_string)
	else:
		push_warning("JSON loading from ShipData failed at " + JSON_path)
	
	if JSON_ship_data == null:
		push_error("ShipData JSON file parsing failed at " + JSON_path)
	
	SHIP_DATA = JSON_ship_data.get("ShipData")
	PLAYER_SHIP_STATS = JSON_ship_data.get("PlayerStats")
	ENEMY_SHIP_STATS = JSON_ship_data.get("EnemyStats")

func create_custom_tween(node:Node, property:String, final_val, duration:float, curve:Curve) -> void:
	create_tween().tween_property(node, property, final_val, duration).as_relative().set_custom_interpolator(func(v): return curve.sample_baked(v))


# This function finds the closest point on the surface of a body's shapes to a given global point.
static func get_distance_to_shape(to_point: Vector2, area: Area2D) -> float:
	# Remove old debug lines
	for line in Engine.get_main_loop().get_nodes_in_group("lines"):
		line.free()
	
	var shape_node = area.get_children()[0].shape
	if not shape_node:
		printerr("Error: shape_node is null.")
		return INF

	var shape_rect: Rect2 = shape_node.get_rect()

	var closest_point_on_rect: Vector2 = Vector2.ZERO
	var area_pos: Vector2 = area.global_position
	var area_rot: float = area.global_rotation # Get the rotation in radians

	# 1. Define all points in LOCAL space (relative to the area's origin)
	var local_points: Array[Vector2] = [
		# Corners
		shape_rect.position,                                            # Top Left
		Vector2(shape_rect.end.x, shape_rect.position.y),               # Top Right
		Vector2(shape_rect.position.x, shape_rect.end.y),               # Bottom Left
		shape_rect.end,                                                 # Bottom Right

		# Midpoints of edges
		shape_rect.position + Vector2(shape_rect.size.x / 2.0, 0),      # Top Mid
		shape_rect.end - Vector2(shape_rect.size.x / 2.0, 0),           # Bottom Mid
		shape_rect.position + Vector2(0, shape_rect.size.y / 2.0),      # Left Mid
		shape_rect.end - Vector2(0, shape_rect.size.y / 2.0),           # Right Mid

		# Center of the Area2D's transform (its local origin)
		Vector2.ZERO,

		# Your other custom points (calculated locally)
		shape_rect.position / 2.0,
		Vector2(shape_rect.position.x/2.0 + shape_rect.size.x/2.0, shape_rect.position.y/2.0),
		Vector2(shape_rect.position.x/2.0, shape_rect.position.y/2.0 + shape_rect.size.y/2.0),
		Vector2(shape_rect.position.x/2.0 + shape_rect.size.x/2.0, shape_rect.position.y/2.0 + shape_rect.size.y/2.0)
	]
	
	var points: Array[Vector2] = []
	for local_p in local_points:
		var rotated_point: Vector2 = local_p.rotated(area_rot)
		var global_point: Vector2 = rotated_point + area_pos
		points.append(global_point)
	
	var distance_array:Array[float] = []
	for point:Vector2 in points:
		var distance_to_corner:float = to_point.distance_to(point)
		distance_array.append(distance_to_corner)
	distance_array.sort() # Sort by value
	
	# Debug line drawing
	#for i in range(points.size()):
		#var line:Line2D = Line2D.new()
		#line.add_point(to_point)
		#line.add_point(points[i])
		#line.width = 2
		#line.default_color = Color.WHITE
		#line.add_to_group("lines")
		#Engine.get_main_loop().current_scene.add_child(line)
	
	return distance_array[0] # Return the shortest distance in array


func get_distance_to_polygon(to_point: Vector2, area: Area2D) -> float:
	var collision_polygon = area.get_children()[0]
	var local_vertices = collision_polygon.polygon

	var min_distance = INF
	var area_transform = area.global_transform

	for vertex in local_vertices:
		# Transform the local vertex point to a global world position
		var global_vertex = area_transform * vertex
		
		var distance = to_point.distance_to(global_vertex)
		if distance < min_distance:
			min_distance = distance
	
	return min_distance


func get_faction_from_ship(ship_index: SHIP_TYPES) -> FACTION:
	var faction:Utility.FACTION = SHIP_DATA.values()[ship_index].get("FACTION")
	return faction
