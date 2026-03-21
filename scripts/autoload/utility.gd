extends Node
class_name game_data


var Z: Dictionary[String, int] = { # Z Indexes for level objects
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

var player_name: String = "Runabout"
var starting_ship: SHIP_TYPES = SHIP_TYPES.Hideki_Class

enum FACTION { FEDERATION, KLINGON, ROMULAN, NEUTRAL }
enum GAMESTATE { SYSTEM, WARPING, CUTSCENE, MAINMENU }
enum MENUSTATE { SETTINGS, SHIPINFO, STARBASE, GALAXY, NONE }
var current_gamestate: GAMESTATE = GAMESTATE.MAINMENU
var current_menu: MENUSTATE = MENUSTATE.NONE
var _is_quitting: bool = false
var dev_mode_enabled: bool = false

# Used for global references to dict ship data JSON
enum SHIP_TYPES {
	La_Sirena,
	Groumall_Freighter,
	Monaveen,
	Risian_Luxury_Cruiser,
	Brel_Class,
	Dderidex_Class,
	Engle_Class,
	Reliant_Class,
	Ross_Class,
	Akira_Class,
	Ambassador_Class,
	Excelsior_II_Class,
	Hoover_Class,
	Nebula_Class,
	Theta_Class,
	Tellarite_Cruiser,
	Magee_Class,
	bortaS_bIr_Class,
	Dia_Vectau_Class,
	Hernandez_Class,
	Excelsior_Class_Refit,
	Luna_Class,
	Edison_Class,
	Constellation_Class,
	Sagan_Class,
	Sutherland_Class,
	Nebula_Class_Phoenix_variant,
	Maquis_Raider,
	Odyssey_Class,
	chargh_Class,
	Wallenberg_Class,
	Tvaro_Class,
	Dhailkhina_Class,
	Sampson_Class,
	Excelsior_Class,
	Kobayashi_Maru,
	Shepard_Class,
	Norway_Class,
	California_Class,
	Galaxy_Class_Venture_variant,
	Springfield_Class,
	Peregrine_Class,
	D5_Class,
	Risian_Corvette,
	Breen_Interceptor,
	Bajoran_Interceptor,
	Oberth_Class,
	Cardenas_Class,
	Vesta_Class,
	Miranda_Class_Antares_variant,
	Challenger_Class,
	Constitution_II_Class,
	Constitution_III_Class,
	Galaxy_Class,
	DKora_Marauder,
	Hideki_Class,
	Qugh_Class,
	Hiawatha_Class,
	Mars_Synth_Defense_Ship,
	Mogai_Class,
	Intrepid_Class_Aeroshuttle,
	Gagarin_Class,
	Saber_Class,
	Miranda_Class_Saratoga_variant,
	Parliament_Class,
	Georgiou_Class,
	Defiant_Class,
	Cheyenne_Class,
	Talarian_Freighter,
	Galor_Class,
	Bajoran_Freighter,
	daSpu_Class,
	Klingon_Bird_of_Prey,
	Shrike_Class,
	Walker_Class,
	Sovereign_Class,
	Malachowski_Class,
	Miranda_Class_Lantree_variant,
	Nova_Class,
	Constitution_Class_Strange_New_Worlds,
	Nova_Class_Rhode_Island_variant,
	New_Orleans_Class,
	Merchantman,
	Keldon_Class,
	batlh_Class,
	JemHadar,
	sech_Class,
	Lanora_Class,
	Pathfinder_Class,
	Steamrunner_Class,
	Soyuz_Class,
	Miranda_Class,
	Nimitz_Class,
	Freedom_Class,
	Intrepid_Class,
	Niagara_Class,
}

## Accessed by Utility.SHIP_DATA[Utility.SHIP_TYPES.ship_name].variable
var SHIP_DATA: Dictionary  # Loaded from ShipData.txt  — sprite, collision, faction etc.
## Accessed by Utility.SHIP_STATS[Utility.SHIP_TYPES.ship_name].variable
var SHIP_STATS: Dictionary # Loaded from ShipStats.txt — movement, health, combat stats

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

# Audio
enum AUDIO_BUS {
	MASTER,
	MUSIC,
	EFFECTS,
	MENUS
}


func _init() -> void:
	load_ship_data()
func _ready() -> void:
	get_tree().set_auto_accept_quit(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_handle_quit_request()
func _handle_quit_request() -> void:
	if _is_quitting: return
	_is_quitting = true
	
	#print("Intercepted Quit Request")
	if (LevelManager.galaxy_data
		and SaveManager.current_save_slot > 0
		and Utility.current_gamestate != Utility.GAMESTATE.MAINMENU):
			SaveManager.save_galaxy(SaveManager.current_save_slot, LevelManager.galaxy_data)
			#print("Emergency Save Complete.")
	
	get_tree().quit()


func _input(event: InputEvent) -> void:
	#Fullscreen management
	if Input.is_action_just_pressed("f11"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func load_ship_data() -> void:
	_load_txt("res://assets/data/ShipData.txt", SHIP_DATA)
	_load_txt("res://assets/data/ShipStats.txt", SHIP_STATS)

func _load_txt(path: String, target: Dictionary) -> void:
	var absolute_path: String = ProjectSettings.globalize_path(path)
	var file: FileAccess = FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		push_error("TXT loading failed at %s — error: %s" % [path, FileAccess.get_open_error()])
		file = FileAccess.open(path, FileAccess.READ)
		return
	#else: print('loading file path %s: ' % path)

	var headers: PackedStringArray = file.get_csv_line()

	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < headers.size() or (row.size() == 1 and row[0] == ""):
			continue

		var entry: Dictionary = {}
		for i: int in range(headers.size()):
			entry[headers[i]] = _parse_csv_value(row[i])

		var key = entry.get("INDEX")
		if key != null:
			target[key] = entry


func _parse_csv_value(value: String) -> Variant:
	# Empty string
	if value == "":
		return null
	# Bool
	if value.to_lower() == "true":  return true
	if value.to_lower() == "false": return false
	# Integer
	if value.is_valid_int():        return value.to_int()
	# Float
	if value.is_valid_float():      return value.to_float()
	# Fallback to string
	return value


func create_custom_tween(node: Node, property: String, final_val, duration: float, curve: Curve) -> void:
	create_tween().tween_property(node, property, final_val, duration).as_relative().set_custom_interpolator(func(v): return curve.sample_baked(v))



# This function finds the closest point on the surface of a body's shapes to a given global point.
func get_distance_to_shape(to_point: Vector2, area: Area2D) -> float:
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
		shape_rect.position, # Top Left
		Vector2(shape_rect.end.x, shape_rect.position.y), # Top Right
		Vector2(shape_rect.position.x, shape_rect.end.y), # Bottom Left
		shape_rect.end, # Bottom Right

		# Midpoints of edges
		shape_rect.position + Vector2(shape_rect.size.x / 2.0, 0), # Top Mid
		shape_rect.end - Vector2(shape_rect.size.x / 2.0, 0), # Bottom Mid
		shape_rect.position + Vector2(0, shape_rect.size.y / 2.0), # Left Mid
		shape_rect.end - Vector2(0, shape_rect.size.y / 2.0), # Right Mid

		# Center of the Area2D's transform (its local origin)
		Vector2.ZERO,

		# Your other custom points (calculated locally)
		shape_rect.position / 2.0,
		Vector2(shape_rect.position.x / 2.0 + shape_rect.size.x / 2.0, shape_rect.position.y / 2.0),
		Vector2(shape_rect.position.x / 2.0, shape_rect.position.y / 2.0 + shape_rect.size.y / 2.0),
		Vector2(shape_rect.position.x / 2.0 + shape_rect.size.x / 2.0, shape_rect.position.y / 2.0 + shape_rect.size.y / 2.0)
	]
	
	var points: Array[Vector2] = []
	for local_p in local_points:
		var rotated_point: Vector2 = local_p.rotated(area_rot)
		var global_point: Vector2 = rotated_point + area_pos
		points.append(global_point)
	
	var distance_array: Array[float] = []
	for point: Vector2 in points:
		var distance_to_corner: float = to_point.distance_to(point)
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


func get_faction_from_ship_type(ship_index: SHIP_TYPES) -> FACTION:
	var faction: Utility.FACTION = SHIP_DATA.values()[ship_index].get("FACTION")
	return faction

func color_string(color: String, text: String) -> String:
	return color + text + "[/color]"

func get_enemy_faction(faction: Utility.FACTION) -> Utility.FACTION:
	if faction == Utility.FACTION.FEDERATION:
		return Utility.FACTION.KLINGON
	elif faction == Utility.FACTION.KLINGON:
		return Utility.FACTION.ROMULAN
	elif faction == Utility.FACTION.ROMULAN:
		return Utility.FACTION.FEDERATION
	else: return Utility.FACTION.NEUTRAL

func get_random_point_on_circle(radius: float) -> Vector2:
	return Vector2.from_angle(randf() * TAU) * radius

func get_faction_home_system(faction: FACTION) -> SystemData:
	if faction == FACTION.FEDERATION:
		return LevelManager.galaxy_data.get_system(GalaxyData.SPECIAL_SYSTEMS.Solarus)
	if faction == FACTION.ROMULAN:
		return LevelManager.galaxy_data.get_system(GalaxyData.SPECIAL_SYSTEMS.Romulus)
	if faction == FACTION.KLINGON:
		return LevelManager.galaxy_data.get_system(GalaxyData.SPECIAL_SYSTEMS.Kronos)
	else:
		printerr("No home system found for faction %s" % faction)
		return LevelManager.galaxy_data.get_system(GalaxyData.SPECIAL_SYSTEMS.Solarus) 


const ANCHOR_YEAR: int = 2025 
const ANCHOR_MONTH: int = 08
const ANCHOR_DAY: int = 12
const ANCHOR_STARDATE_BASE: float = 4513.0

# Calendar Offsets
const KLINGON_YEAR_OFFSET: int = 1374 # 2373 AD = Year 999 YoK
const ROMULAN_YEAR_OFFSET: int = 450   # Landing on Romulus approx 450 AD

## Original Federation Stardate Function
func calculate_current_stardate() -> float:
	var anchor_dict: Dictionary = {
		"year": ANCHOR_YEAR, "month": ANCHOR_MONTH, "day": ANCHOR_DAY,
		"hour": 0, "minute": 0, "second": 0
	}
	var anchor_timestamp: int = Time.get_unix_time_from_datetime_dict(anchor_dict)
	var now_timestamp: int = Time.get_unix_time_from_system()
	var seconds_since_anchor: int = now_timestamp - anchor_timestamp
	var days_since_anchor: float = seconds_since_anchor / 86400.0

	return ANCHOR_STARDATE_BASE + days_since_anchor

## Klingon Format: "Day [X] in the Year of Kahless [Y]"
func get_klingon_date() -> String:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	
	# Calculate Klingon Year
	var klingon_year: int = now["year"] - KLINGON_YEAR_OFFSET
	
	# Calculate Day of the Year (1 - 366)
	var day_of_year: int = _get_day_of_year(now)
	
	return "Day %d in the Year of Kahless %d" % [day_of_year, klingon_year]

## Romulan Format: "Imperial Year [Y].[Day]"
func get_romulan_date() -> String:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	
	# Calculate Romulan 'After Settlement' Year
	var romulan_year: int = now["year"] - ROMULAN_YEAR_OFFSET
	
	# Calculate Day of the Year
	var day_of_year: int = _get_day_of_year(now)
	
	# Formatting as "Year.Day" (e.g., 1575.224)
	return "Imperial Year %d.%03d" % [romulan_year, day_of_year]

# Helper function to calculate the ordinal day of the year
func _get_day_of_year(date_dict: Dictionary) -> int:
	var year = date_dict["year"]
	var month = date_dict["month"]
	var day = date_dict["day"]
	
	var days_in_months = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	
	# Check for Leap Year
	if (year % 4 == 0 and year % 100 != 0) or (year % 400 == 0):
		days_in_months[1] = 29
		
	var ordinal_day: int = day
	for i in range(month - 1):
		ordinal_day += days_in_months[i]
		
	return ordinal_day
